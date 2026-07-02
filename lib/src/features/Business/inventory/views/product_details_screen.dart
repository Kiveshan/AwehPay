import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    this.product,
  });

  final Map<String, Object>? product;

  @override
  Widget build(BuildContext context) {
    final details = _ProductDetailsData.fromMap(product);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDFA890)),
                ),
                child: Column(
                  children: [
                    if (details.isLowStock) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: _LowStockBadge(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _DetailField(label: 'Product Name', value: details.name),
                    if (details.barcode.isNotEmpty) ...[  
                      const SizedBox(height: 18),
                      _DetailField(label: 'Product Barcode', value: details.barcode),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _DetailField(label: 'Cost Price', value: details.costPrice)),
                        const SizedBox(width: 28),
                        Expanded(child: _DetailField(label: 'Selling Price', value: details.sellingPrice)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _DetailField(label: 'Quantity', value: details.quantity, isLowStock: details.isLowStock)),
                        const SizedBox(width: 28),
                        Expanded(child: _DetailField(label: 'Product Category', value: details.category)),
                      ],
                    ),
                    if (details.isLowStock) ...[
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () async {
                          await context.push(
                            '${AppRoutes.addProduct}?mode=replenish',
                            extra: <String, dynamic>{
                              'productId': details.productId,
                              'productName': details.name,
                              'category': details.category,
                              'barcode': details.barcode,
                              'costPrice': details.rawCostPrice,
                              'sellingPrice': details.rawSellingPrice,
                              'stockQuantity': details.rawStockQuantity,
                              'lowStockThreshold': details.rawLowStockThreshold,
                            },
                          );
                          if (context.mounted) context.pop();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFA890),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Replenish Stock',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 70),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetailsData {
  const _ProductDetailsData({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.category,
    required this.isLowStock,
    this.rawCostPrice,
    this.rawSellingPrice,
    this.rawStockQuantity,
    this.rawLowStockThreshold,
  });

  final String productId;
  final String name;
  final String barcode;
  final String costPrice;
  final String sellingPrice;
  final String quantity;
  final String category;
  final bool isLowStock;
  final double? rawCostPrice;
  final double? rawSellingPrice;
  final int? rawStockQuantity;
  final int? rawLowStockThreshold;

  factory _ProductDetailsData.fromMap(Map<String, Object>? product) {
    return _ProductDetailsData(
      productId: product?['productId'] as String? ?? '',
      name: product?['name'] as String? ?? 'Paper Plates',
      barcode: product?['barcode'] as String? ?? '',
      costPrice: product?['costPrice'] as String? ?? 'R 20.00',
      sellingPrice: product?['sellingPrice'] as String? ?? 'R 35.00',
      quantity: product?['quantity'] as String? ?? '5',
      category: product?['category'] as String? ?? 'Household',
      isLowStock: product?['isLowStock'] as bool? ?? true,
      rawCostPrice: (product?['rawCostPrice'] as num?)?.toDouble(),
      rawSellingPrice: (product?['rawSellingPrice'] as num?)?.toDouble(),
      rawStockQuantity: (product?['rawStockQuantity'] as num?)?.toInt(),
      rawLowStockThreshold:
          (product?['rawLowStockThreshold'] as num?)?.toInt(),
    );
  }
}

class _Header extends StatelessWidget {
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
          'Product Details',
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

class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Low Stock',
        style: TextStyle(
          color: Color(0xFFE68888),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.isLowStock = false,
  });

  final String label;
  final String value;
  final bool isLowStock;

  @override
  Widget build(BuildContext context) {
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
        Container(
          height: 36,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(color: isLowStock ? const Color(0xFFE68888) : const Color(0xFFC9CED6)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isLowStock ? const Color(0xFFE68888) : const Color(0xFF272A2F),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
