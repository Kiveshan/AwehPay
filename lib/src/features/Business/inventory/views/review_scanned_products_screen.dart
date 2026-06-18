import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/scanned_product.dart';

class ReviewScannedProductsArgs {
  const ReviewScannedProductsArgs({
    required this.products,
    required this.rawOcrText,
    this.supplierName = '',
    this.invoiceNumber = '',
    this.invoiceImageUrl = '',
  });

  final List<ScannedProduct> products;
  final String rawOcrText;
  final String supplierName;
  final String invoiceNumber;
  final String invoiceImageUrl;
}

class ReviewScannedProductsScreen extends StatefulWidget {
  const ReviewScannedProductsScreen({super.key, required this.args});

  final ReviewScannedProductsArgs args;

  @override
  State<ReviewScannedProductsScreen> createState() =>
      _ReviewScannedProductsScreenState();
}

class _ReviewScannedProductsScreenState extends State<ReviewScannedProductsScreen> {
  final _apiService = ApiService();
  late List<_EditableScannedProduct> _products;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _products = widget.args.products.map(_EditableScannedProduct.new).toList();
  }

  @override
  void dispose() {
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProducts() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      _showMessage(errors.first);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _apiService.saveInvoiceScan(
        rawOcrText: widget.args.rawOcrText,
        supplierName: widget.args.supplierName,
        invoiceNumber: widget.args.invoiceNumber,
        invoiceImageUrl: widget.args.invoiceImageUrl,
        products: _products.map((product) => product.toScannedProduct().toJson()).toList(),
      );

      if (!mounted) return;
      _showMessage('Scanned products saved successfully.');
      context.pop(true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<String> _validate() {
    if (_products.isEmpty) {
      return ['No products to save.'];
    }

    for (final product in _products) {
      final name = product.nameController.text.trim();
      final quantity = int.tryParse(product.quantityController.text.trim());
      final costPrice = _parseMoney(product.costPriceController.text);
      final sellingPrice = _parseMoney(product.sellingPriceController.text);
      final lowStockThreshold = int.tryParse(
        product.lowStockThresholdController.text.trim(),
      );

      if (name.isEmpty) return ['Product name is required.'];
      if (quantity == null || quantity <= 0) return ['Quantity must be greater than 0.'];
      if (costPrice == null || costPrice <= 0) return ['Cost price must be greater than 0.'];
      if (sellingPrice == null || sellingPrice <= 0) return ['Selling price is required.'];
      if (lowStockThreshold == null || lowStockThreshold < 0) {
        return ['Low stock threshold is required.'];
      }
    }

    return [];
  }

  double? _parseMoney(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanedValue.isEmpty) return null;
    return double.tryParse(cleanedValue);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    'Review Scan',
                    style: TextStyle(
                      color: Color(0xFF272A2F),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : () => context.pop(false),
                    child: Container(
                      width: 58,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEEAB8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirm each item before saving. Existing products fill selling price and low stock automatically when matched.',
                style: TextStyle(
                  color: Color(0xFF6C7078),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _products.isEmpty
                    ? const Center(child: Text('No scanned products remaining.'))
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _ScannedProductCard(
                            product: product,
                            onRemove: () {
                              setState(() {
                                _products.removeAt(index).dispose();
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Cancel',
                      color: const Color(0xFFC9CED6),
                      onTap: _isSaving ? null : () => context.pop(false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      label: _isSaving ? 'Saving...' : 'Save Products',
                      color: const Color(0xFFF5C9B7),
                      onTap: _isSaving ? null : _saveProducts,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableScannedProduct {
  _EditableScannedProduct(ScannedProduct product)
      : original = product,
        nameController = TextEditingController(text: product.name),
        quantityController = TextEditingController(text: '${product.quantity}'),
        costPriceController = TextEditingController(text: product.costPrice.toStringAsFixed(2)),
        categoryController = TextEditingController(text: product.category),
        sellingPriceController = TextEditingController(
          text: product.sellingPrice == null ? '' : product.sellingPrice!.toStringAsFixed(2),
        ),
        lowStockThresholdController = TextEditingController(
          text: product.lowStockThreshold == null ? '' : '${product.lowStockThreshold}',
        );

  final ScannedProduct original;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController costPriceController;
  final TextEditingController categoryController;
  final TextEditingController sellingPriceController;
  final TextEditingController lowStockThresholdController;

  ScannedProduct toScannedProduct() {
    return original.copyWith(
      name: nameController.text.trim(),
      quantity: int.tryParse(quantityController.text.trim()) ?? 0,
      costPrice: double.tryParse(costPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      category: categoryController.text.trim().isEmpty ? 'Other' : categoryController.text.trim(),
      sellingPrice: double.tryParse(sellingPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
      lowStockThreshold: int.tryParse(lowStockThresholdController.text.trim()),
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    costPriceController.dispose();
    categoryController.dispose();
    sellingPriceController.dispose();
    lowStockThresholdController.dispose();
  }
}

class _ScannedProductCard extends StatelessWidget {
  const _ScannedProductCard({required this.product, required this.onRemove});

  final _EditableScannedProduct product;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF5C9B7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.original.isExistingProduct ? 'Existing product' : 'New product',
                  style: const TextStyle(
                    color: Color(0xFF6C7078),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF6C7078)),
              ),
            ],
          ),
          _TextInput(label: 'Product name', controller: product.nameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TextInput(label: 'Quantity', controller: product.quantityController, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _TextInput(label: 'Cost price', controller: product.costPriceController, keyboardType: TextInputType.number, prefixText: 'R')),
            ],
          ),
          const SizedBox(height: 12),
          _TextInput(label: 'Category', controller: product.categoryController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TextInput(label: 'Selling price', controller: product.sellingPriceController, keyboardType: TextInputType.number, prefixText: 'R')),
              const SizedBox(width: 12),
              Expanded(child: _TextInput(label: 'Low stock', controller: product.lowStockThresholdController, keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6C7078),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9CED6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefixText != null) ...[
                const SizedBox(width: 10),
                Text(prefixText!, style: const TextStyle(color: Color(0xFF272A2F))),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
