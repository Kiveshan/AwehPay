part of 'add_product_screen.dart';

/// Holds the [AddProductScreen] form state (controllers, options, selection)
/// and the product save / prefill / option-loading logic.
mixin _AddProductFormMixin on State<AddProductScreen> {
  bool _isProductAdded = false;
  bool _isSavingProduct = false;
  bool _isProcessingInvoice = false;
  final _apiService = ApiService();
  final _invoiceScanService = InvoiceScanService();
  late final TextEditingController _productNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _alertQuantityController;
  bool _hasScannedBarcode = false;
  bool _quantityModified = false;
  bool _productNameLockedBySelection = false;
  String? _selectedProductId;
  String? _selectedCategory;
  List<String> _productOptions = [];
  List<String> _categoryOptions = ['Other'];
  final Map<String, Map<String, dynamic>> _productDataByName = {};

  void _applyProductPrefill(Map<String, dynamic> product) {
    _fillFromProductMap(product, lockSelection: true);
  }

  void _fillFromProductMap(
    Map<String, dynamic> product, {
    required bool lockSelection,
  }) {
    setState(() {
      _selectedProductId = product['productId'] as String?;
      _productNameLockedBySelection = lockSelection;
      _hasScannedBarcode = true;
      _productNameController.text = (product['name'] as String?) ?? '';
      final productCategory = (product['category'] as String?) ?? '';
      if (productCategory.isNotEmpty && _categoryOptions.contains(productCategory)) {
        _selectedCategory = productCategory;
        _categoryController.clear();
      } else if (productCategory.isNotEmpty) {
        _selectedCategory = 'Other';
        _categoryController.text = productCategory;
      } else {
        _selectedCategory = null;
        _categoryController.clear();
      }
      _barcodeController.text = (product['barcode'] as String?) ?? '';
      _costPriceController.text = '${product['costPrice'] ?? ''}';
      _sellingPriceController.text = '${product['sellingPrice'] ?? ''}';
      _quantityController.text = '${product['stockQuantity'] ?? ''}';
      _alertQuantityController.text = '${product['lowStockThreshold'] ?? ''}';
    });
  }

  void _changeIntField(TextEditingController controller, int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) {
      return;
    }

    setState(() {
      controller.text = '$next';
    });
  }

  Future<void> _saveProduct() async {
    final name = _productNameController.text.trim();
    final category = _selectedCategory == 'Other'
        ? _categoryController.text.trim()
        : (_selectedCategory ?? '');
    final costPrice = _parseMoney(_costPriceController.text);
    final sellingPrice = _parseMoney(_sellingPriceController.text);
    final stockQuantity = int.tryParse(_quantityController.text.trim());
    final lowStockThreshold =
        int.tryParse(_alertQuantityController.text.trim());

    if (name.isEmpty ||
        category.isEmpty ||
        costPrice == null ||
        sellingPrice == null ||
        stockQuantity == null ||
        lowStockThreshold == null) {
      _showError(
        'Please complete all product details before adding the product.',
      );
      return;
    }

    setState(() {
      _isSavingProduct = true;
    });

    try {
      if (_selectedProductId != null) {
        await _apiService.updateProduct(
          productId: _selectedProductId!,
          barcode: _hasScannedBarcode ? _barcodeController.text.trim() : '',
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stockQuantity: stockQuantity,
          lowStockThreshold: lowStockThreshold,
        );
      } else {
        await _apiService.addProduct(
          name: name,
          barcode: _hasScannedBarcode ? _barcodeController.text.trim() : '',
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stockQuantity: stockQuantity,
          category: category,
          lowStockThreshold: lowStockThreshold,
        );
      }

      if (!mounted) return;
      InventoryTimestamp.markChanged();
      if (_selectedProductId != null) {
        context.pop();
      } else {
        setState(() {
          _isProductAdded = true;
        });
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProduct = false;
        });
      }
    }
  }

  double? _parseMoney(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

    if (cleanedValue.isEmpty) {
      return null;
    }

    return double.tryParse(cleanedValue);
  }

  Future<void> _loadProductOptions() async {
    try {
      final response = await _apiService.fetchProductOptions();
      final products = response['products'];
      final categories = response['categories'];

      if (!mounted) {
        return;
      }

      setState(() {
        if (products is List) {
          _productDataByName.clear();
          _productOptions = [];
          for (final p in products) {
            if (p is Map<String, dynamic> && p['name'] is String) {
              final name = p['name'] as String;
              _productDataByName[name] = p;
              _productOptions.add(name);
            }
          }
        }

        if (categories is List) {
          final loadedCategories = categories.whereType<String>().toList();

          if (!loadedCategories.contains('Other')) {
            loadedCategories.add('Other');
          }

          _categoryOptions = loadedCategories;
        }
      });
    } catch (_) {}
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
