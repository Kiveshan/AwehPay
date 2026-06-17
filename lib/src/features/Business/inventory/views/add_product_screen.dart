import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final _apiService = ApiService();
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
    final isReplenish = widget.isReplenishStock;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isProductAdded) ...[
                        Center(
                          child: _ScanBarcodeButton(
                            onTap: () {
                              setState(() {
                                _hasScannedBarcode = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isReplenish
                                ? const Color(0xFFF5C9B7)
                                : const Color(0xFFF5C9B7),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isProductAdded) ...[
                              const _ProductAddedStatus(),
                              const SizedBox(height: 24),
                            ],
                            _EditableOptionField(
                              label: 'Product Name',
                              controller: _productNameController,
                              options: _productOptions,
                              prefixIcon: Icons.search_rounded,
                              readOnly: _isProductAdded ||
                                  widget.lockedProductName != null,
                              onOptionSelected: (name) {
                                final data = _productDataByName[name];
                                if (data != null) {
                                  setState(() {
                                    _selectedProductId =
                                        data['productId'] as String?;
                                    _productNameLockedBySelection = true;
                                    _categoryController.text =
                                        (data['category'] as String?) ?? '';
                                    _costPriceController.text =
                                        '${data['costPrice'] ?? ''}';
                                    _sellingPriceController.text =
                                        '${data['sellingPrice'] ?? ''}';
                                    _quantityController.text =
                                        '${data['stockQuantity'] ?? ''}';
                                    _alertQuantityController.text =
                                        '${data['lowStockThreshold'] ?? ''}';
                                  });
                                } else {
                                  setState(() {
                                    _selectedProductId = null;
                                    _productNameLockedBySelection = false;
                                  });
                                }
                              },
                            ),
                            if (_hasScannedBarcode) ...[
                              const SizedBox(height: 18),
                              _InputField(
                                label: 'Product Barcode',
                                controller: _barcodeController,
                                readOnly: _isProductAdded,
                              ),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _InputField(
                                    label: 'Cost Price',
                                    controller: _costPriceController,
                                    keyboardType: TextInputType.number,
                                    prefixText: 'R',
                                    readOnly: _isProductAdded,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: _InputField(
                                    label: 'Selling Price',
                                    controller: _sellingPriceController,
                                    keyboardType: TextInputType.number,
                                    prefixText: 'R',
                                    readOnly: _isProductAdded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _InputField(
                                    label: 'Quantity',
                                    labelColor: null,
                                    borderColor: null,
                                    textColor: null,
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    spinnerColor: const Color(0xFFF5C9B7),
                                    readOnly: _isProductAdded,
                                    onIncrement: _isProductAdded
                                        ? null
                                        : () {
                                            final v = int.tryParse(
                                                  _quantityController.text,
                                                ) ??
                                                0;
                                            setState(() {
                                              _quantityController.text =
                                                  '${v + 1}';
                                            });
                                          },
                                    onDecrement: _isProductAdded
                                        ? null
                                        : () {
                                            final v = int.tryParse(
                                                  _quantityController.text,
                                                ) ??
                                                0;
                                            if (v > 0) {
                                              setState(() {
                                                _quantityController.text =
                                                    '${v - 1}';
                                              });
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: _EditableOptionField(
                                    label: 'Product Category',
                                    controller: _categoryController,
                                    options: _categoryOptions,
                                    readOnly: _isProductAdded ||
                                        widget.lockedCategory != null,
                                  ),
                                ),
                              ],
                            ),
                            ...[
                              const SizedBox(height: 18),
                              _InputField(
                                label: 'Alert me when stock reaches below',
                                controller: _alertQuantityController,
                                keyboardType: TextInputType.number,
                                trailingText: 'Units',
                                spinnerColor: const Color(0xFFF5C9B7),
                                readOnly: _isProductAdded,
                                onIncrement: _isProductAdded
                                    ? null
                                    : () {
                                        final value = int.tryParse(
                                              _alertQuantityController.text,
                                            ) ??
                                            0;
                                        setState(() {
                                          _alertQuantityController.text =
                                              '${value + 1}';
                                        });
                                      },
                                onDecrement: _isProductAdded
                                    ? null
                                    : () {
                                        final value = int.tryParse(
                                              _alertQuantityController.text,
                                            ) ??
                                            0;
                                        if (value > 0) {
                                          setState(() {
                                            _alertQuantityController.text =
                                                '${value - 1}';
                                          });
                                        }
                                      },
                              ),
                            ],
                            if (!_isProductAdded) ...[
                              const SizedBox(height: 24),
                              _SaveButton(
                                label: 'Add Product',
                                icon: Icons.add_rounded,
                                onTap: _isSavingProduct ? null : _saveProduct,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _ProductAddedStatus extends StatelessWidget {
  const _ProductAddedStatus();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFA8E6B0),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Product Added',
          style: TextStyle(
            color: Color(0xFFA8E6B0),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const Text(
          'Add Product',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEEAB8),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.labelColor,
    this.borderColor,
    this.textColor,
    this.trailingText,
    this.keyboardType,
    this.spinnerColor,
    this.onIncrement,
    this.onDecrement,
    this.prefixText,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final Color? labelColor;
  final Color? borderColor;
  final Color? textColor;
  final String? trailingText;
  final TextInputType? keyboardType;
  final Color? spinnerColor;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String? prefixText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? const Color(0xFF6C7078),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? const Color(0xFFC9CED6),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefixText != null) ...[
                const SizedBox(width: 12),
                Text(
                  prefixText!,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 16,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: textColor ?? const Color(0xFF272A2F),
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              if (onIncrement != null || onDecrement != null) ...[
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onIncrement,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: spinnerColor ?? const Color(0xFF272A2F),
                        size: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDecrement,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: spinnerColor ?? const Color(0xFF272A2F),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableOptionField extends StatelessWidget {
  const _EditableOptionField({
    required this.label,
    required this.controller,
    required this.options,
    this.prefixIcon,
    this.readOnly = false,
    this.onOptionSelected,
  });

  final String label;
  final TextEditingController controller;
  final List<String> options;
  final IconData? prefixIcon;
  final bool readOnly;
  final ValueChanged<String>? onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final fieldWidth = MediaQuery.sizeOf(context).width - 76;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6C7078),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: FocusNode(),
          optionsBuilder: (textEditingValue) {
            if (readOnly) {
              return const Iterable<String>.empty();
            }

            final query = textEditingValue.text.toLowerCase().trim();

            if (query.isEmpty) {
              return options;
            }

            return options.where(
              (option) => option.toLowerCase().contains(query),
            );
          },
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            return Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC9CED6)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      prefixIcon,
                      color: const Color(0xFF272A2F),
                      size: 20,
                    ),
                  ],
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      readOnly: readOnly,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF272A2F),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF272A2F),
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: SizedBox(
                  width: fieldWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);

                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                          onOptionSelected?.call(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScanBarcodeButton extends StatelessWidget {
  const _ScanBarcodeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF5C9B7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 14,
            ),
            SizedBox(width: 8),
            Text(
              'Scan Barcode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF5C9B7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
