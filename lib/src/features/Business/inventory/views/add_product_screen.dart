import 'dart:math' as math;

import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:awe_pay/src/core/router/app_routes.dart';
import 'package:awe_pay/src/features/Business/Inventory/models/scanned_product.dart';
import 'package:awe_pay/src/features/Business/Inventory/views/review_scanned_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/add_product_header.dart';
import '../../../../core/widgets/scan_barcode_button.dart';
import '../../../../core/widgets/scan_type_bottom_sheet.dart';
import '../../../../core/widgets/invoice_source_bottom_sheet.dart';

import '../services/invoice_ocr_parser.dart';
import '../services/invoice_scan_service.dart';
import 'widgets/add_product_form.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.isReplenishStock = false,
    this.lockedProductId,
    this.lockedProductName,
    this.lockedCategory,
    this.prefillBarcode,
    this.prefillCostPrice,
    this.prefillSellingPrice,
    this.prefillStockQuantity,
    this.prefillLowStockThreshold,
  });

  final bool isReplenishStock;
  final String? lockedProductId;
  final String? lockedProductName;
  final String? lockedCategory;
  final String? prefillBarcode;
  final double? prefillCostPrice;
  final double? prefillSellingPrice;
  final int? prefillStockQuantity;
  final int? prefillLowStockThreshold;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
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
  List<String> _productOptions = [];
  List<String> _categoryOptions = ['Other'];
  final Map<String, Map<String, dynamic>> _productDataByName = {};

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.lockedProductName ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.lockedCategory ?? '',
    );
    final hasPrefillBarcode =
        widget.prefillBarcode != null && widget.prefillBarcode!.isNotEmpty;
    _barcodeController = TextEditingController(
      text: hasPrefillBarcode ? widget.prefillBarcode : '',
    );
    _costPriceController = TextEditingController(
      text: widget.prefillCostPrice != null
          ? widget.prefillCostPrice!.toStringAsFixed(2)
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.prefillSellingPrice != null
          ? widget.prefillSellingPrice!.toStringAsFixed(2)
          : '',
    );
    _quantityController = TextEditingController(
      text: widget.prefillStockQuantity != null
          ? '${widget.prefillStockQuantity}'
          : '',
    );
    _alertQuantityController = TextEditingController(
      text: widget.prefillLowStockThreshold != null
          ? '${widget.prefillLowStockThreshold}'
          : '',
    );
    if (hasPrefillBarcode) {
      _hasScannedBarcode = true;
    }
    _selectedProductId = widget.lockedProductId;
    _productNameController.addListener(() {
      if (_productNameLockedBySelection) {
        final currentText = _productNameController.text;
        final stillMatches = _productDataByName.containsKey(currentText);
        if (!stillMatches) {
          setState(() {
            _productNameLockedBySelection = false;
            _selectedProductId = null;
            _categoryController.clear();
            _costPriceController.clear();
            _sellingPriceController.clear();
            _quantityController.clear();
            _alertQuantityController.clear();
          });
        }
      }
    });
    _quantityController.addListener(() {
      if (widget.isReplenishStock && !_quantityModified) {
        final original = widget.prefillStockQuantity != null
            ? '${widget.prefillStockQuantity}'
            : '';
        if (_quantityController.text != original) {
          setState(() {
            _quantityModified = true;
          });
        }
      }
    });
    _loadProductOptions();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _alertQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AddProductHeader(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isProductAdded) ...[
                            Center(
                              child: ScanBarcodeButton(
                                onTap: _showScanOptions,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          AddProductForm(
                            isProductAdded: _isProductAdded,
                            isSavingProduct: _isSavingProduct,
                            hasScannedBarcode: _hasScannedBarcode,
                            lockedProductName: widget.lockedProductName,
                            lockedCategory: widget.lockedCategory,
                            productOptions: _productOptions,
                            categoryOptions: _categoryOptions,
                            productNameController: _productNameController,
                            categoryController: _categoryController,
                            barcodeController: _barcodeController,
                            costPriceController: _costPriceController,
                            sellingPriceController: _sellingPriceController,
                            quantityController: _quantityController,
                            alertQuantityController: _alertQuantityController,
                            onProductOptionSelected: (name) {
                              final data = _productDataByName[name];
                              if (data != null) {
                                _fillFromProductMap(data, lockSelection: true);
                              } else {
                                setState(() {
                                  _selectedProductId = null;
                                  _productNameLockedBySelection = false;
                                });
                              }
                            },
                            onIncrementQuantity: () =>
                                _changeIntField(_quantityController, 1),
                            onDecrementQuantity: () =>
                                _changeIntField(_quantityController, -1),
                            onIncrementAlertQuantity: () =>
                                _changeIntField(_alertQuantityController, 1),
                            onDecrementAlertQuantity: () =>
                                _changeIntField(_alertQuantityController, -1),
                            onSave: _saveProduct,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessingInvoice)
            Container(
              color: Colors.white,
              child: const Center(
                child: _ProcessingInvoiceOverlay(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showScanOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return ScanTypeBottomSheet(
          onScanBarcode: () {
            Navigator.of(context).pop();
            _handleBarcodeScan();
          },
          onScanInvoice: () {
            Navigator.of(context).pop();
            _handleInvoiceScan();
          },
        );
      },
    );
  }

  Future<void> _handleBarcodeScan() async {
    final barcode = await context.push<String>(AppRoutes.barcodeScanner);
    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    try {
      final response = await _apiService.lookupProductByBarcode(barcode.trim());
      final product = response['product'];

      if (response['found'] == true && product is Map<String, dynamic>) {
        _applyProductPrefill(product);
        _showError('Product found. Review details before saving.');
      } else {
        if (!mounted) return;
        final addNew = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Product not found'),
            content: const Text('Product not found. Add as new product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add New'),
              ),
            ],
          ),
        );

        if (addNew == true && mounted) {
          setState(() {
            _selectedProductId = null;
            _productNameLockedBySelection = false;
            _hasScannedBarcode = true;
            _barcodeController.text = barcode.trim();
            _productNameController.clear();
            _categoryController.clear();
            _costPriceController.clear();
            _sellingPriceController.clear();
            _quantityController.clear();
            _alertQuantityController.clear();
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    }
  }

  Future<void> _handleInvoiceScan() async {
    final source = await showModalBottomSheet<InvoiceImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return InvoiceSourceBottomSheet(
          onSelect: (choice) {
            Navigator.of(context).pop(
              choice == InvoiceSourceChoice.camera
                  ? InvoiceImageSource.camera
                  : InvoiceImageSource.gallery,
            );
          },
        );
      },
    );

    if (source == null) {
      return;
    }

    setState(() {
      _isSavingProduct = true;
      _isProcessingInvoice = true;
    });

    try {
      final image = await _invoiceScanService.pickInvoiceImage(source: source);
      if (image == null) {
        return;
      }

      final recognizedText = await _invoiceScanService.recognizeFromFilePath(
        image.path,
      );

      final parser = InvoiceOcrParser();
      final parsed = parser.parseRecognizedText(recognizedText);

      if (parsed.products.isEmpty) {
        _showError('No readable invoice items were found. Please retry scanning.');
        return;
      }

      final response = await _apiService.matchScannedProducts(
        products: parsed.products
            .map((p) => p.toJson())
            .toList(),
      );

      final rawProducts = response['products'];
      final matchedProducts = rawProducts is List
          ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(ScannedProduct.fromJson)
              .toList()
          : <ScannedProduct>[];

      if (matchedProducts.isEmpty) {
        _showError('No readable invoice items were found. Please retry scanning.');
        return;
      }

      if (!mounted) return;
      await context.push(
        AppRoutes.reviewScannedProducts,
        extra: ReviewScannedProductsArgs(
          products: matchedProducts,
          rawOcrText: recognizedText.text,
          supplierName: parsed.supplierName,
          invoiceNumber: parsed.invoiceNumber,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProduct = false;
          _isProcessingInvoice = false;
        });
      }
    }
  }

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
      _categoryController.text = (product['category'] as String?) ?? '';
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
    final category = _categoryController.text.trim();
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

class _ProcessingInvoiceOverlay extends StatefulWidget {
  const _ProcessingInvoiceOverlay();

  @override
  State<_ProcessingInvoiceOverlay> createState() =>
      _ProcessingInvoiceOverlayState();
}

class _ProcessingInvoiceOverlayState extends State<_ProcessingInvoiceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _DotCirclePainter(progress: _controller.value),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Processing Invoice',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DotCirclePainter extends CustomPainter {
  const _DotCirclePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const dotCount = 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const dotRadius = 4.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final offset = Offset(
        center.dx + radius * math.cos(angle - math.pi / 2),
        center.dy + radius * math.sin(angle - math.pi / 2),
      );
      final distFromActive = ((i / dotCount) - progress + 1) % 1;
      final opacity = (1 - distFromActive).clamp(0.15, 1.0);
      canvas.drawCircle(
        offset,
        dotRadius,
        Paint()
          ..color =
              const Color(0xFFB8A9E8).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_DotCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
