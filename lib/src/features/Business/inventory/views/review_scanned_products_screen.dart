import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/scanned_product.dart';
import '../inventory_timestamp.dart';
import 'widgets/editable_scanned_product.dart';
import 'widgets/scanned_product_card.dart';

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
  late List<EditableScannedProduct> _products;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _products = widget.args.products.map(EditableScannedProduct.new).toList();
  }

  void _addBlankProduct() {
    setState(() {
      _products.add(
        EditableScannedProduct(
          const ScannedProduct(
            name: '',
            quantity: 1,
            costPrice: 0,
            category: 'Other',
            confidence: 1,
          ),
        ),
      );
    });
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
      InventoryTimestamp.markChanged();
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isSaving ? null : _addBlankProduct,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFA890),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSaving ? null : () => context.pop(false),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEAB8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirm each item before saving. Existing products fill selling price and low stock automatically when matched.',
                style: TextStyle(
                  color: Color(0xFF272A2F),
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
                          return ScannedProductCard(
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
                      color: const Color(0xFFDFA890),
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
