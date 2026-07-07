class ProductItem {
  const ProductItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalCost,
    required this.vat,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.category,
  });

  final String productId;
  final String name;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final double totalCost;
  final bool vat;
  final int stockQuantity;
  final int lowStockThreshold;
  final String category;

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  static ProductItem fromMap(Map<String, dynamic> map) {
    return ProductItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      barcode: (map['barcode'] as String?) ?? '',
      costPrice: ((map['costPrice'] as num?) ?? 0).toDouble(),
      sellingPrice: ((map['sellingPrice'] as num?) ?? 0).toDouble(),
      totalCost: ((map['totalCost'] as num?) ?? 0).toDouble(),
      vat: (map['vat'] as bool?) ?? false,
      stockQuantity: ((map['stockQuantity'] as num?) ?? 0).toInt(),
      lowStockThreshold: ((map['lowStockThreshold'] as num?) ?? 0).toInt(),
      category: (map['category'] as String?) ?? '',
    );
  }

  Map<String, Object> toDetailsExtra() {
    return {
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'costPrice': 'R ${costPrice.toStringAsFixed(2)}',
      'sellingPrice': 'R${sellingPrice.toStringAsFixed(2)}',
      'totalCost': 'R ${totalCost.toStringAsFixed(2)}',
      'quantity': '$stockQuantity',
      'category': category,
      'isLowStock': isLowStock,
      'vat': vat,
      'rawCostPrice': costPrice,
      'rawSellingPrice': sellingPrice,
      'rawTotalCost': totalCost,
      'rawStockQuantity': stockQuantity,
      'rawLowStockThreshold': lowStockThreshold,
    };
  }
}
