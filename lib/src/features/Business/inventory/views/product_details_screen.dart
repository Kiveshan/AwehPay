import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

part 'product_details_screen.widgets.dart';

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
                        Expanded(child: _DetailField(label: 'Total Cost', value: details.totalCost)),
                        const SizedBox(width: 28),
                        Expanded(
                          child: _VatField(vatEnabled: details.vat),
                        ),
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
                              'totalCost': details.rawTotalCost,
                              'vat': details.vat,
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
    required this.totalCost,
    required this.vat,
    required this.quantity,
    required this.category,
    required this.isLowStock,
    this.rawCostPrice,
    this.rawSellingPrice,
    this.rawTotalCost,
    this.rawStockQuantity,
    this.rawLowStockThreshold,
  });

  final String productId;
  final String name;
  final String barcode;
  final String costPrice;
  final String sellingPrice;
  final String totalCost;
  final bool vat;
  final String quantity;
  final String category;
  final bool isLowStock;
  final double? rawCostPrice;
  final double? rawSellingPrice;
  final double? rawTotalCost;
  final int? rawStockQuantity;
  final int? rawLowStockThreshold;

  factory _ProductDetailsData.fromMap(Map<String, Object>? product) {
    return _ProductDetailsData(
      productId: product?['productId'] as String? ?? '',
      name: product?['name'] as String? ?? 'Paper Plates',
      barcode: product?['barcode'] as String? ?? '',
      costPrice: product?['costPrice'] as String? ?? 'R 20.00',
      sellingPrice: product?['sellingPrice'] as String? ?? 'R 35.00',
      totalCost: product?['totalCost'] as String? ?? 'R 0.00',
      vat: product?['vat'] as bool? ?? false,
      quantity: product?['quantity'] as String? ?? '5',
      category: product?['category'] as String? ?? 'Household',
      isLowStock: product?['isLowStock'] as bool? ?? true,
      rawCostPrice: (product?['rawCostPrice'] as num?)?.toDouble(),
      rawSellingPrice: (product?['rawSellingPrice'] as num?)?.toDouble(),
      rawTotalCost: (product?['rawTotalCost'] as num?)?.toDouble(),
      rawStockQuantity: (product?['rawStockQuantity'] as num?)?.toInt(),
      rawLowStockThreshold:
          (product?['rawLowStockThreshold'] as num?)?.toInt(),
    );
  }
}

