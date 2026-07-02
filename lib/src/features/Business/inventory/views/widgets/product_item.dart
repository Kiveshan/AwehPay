class ProductItem {
  const ProductItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.category,
  });

  final String productId;
  final String name;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
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
      'quantity': '$stockQuantity',
      'category': category,
      'isLowStock': isLowStock,
      'rawCostPrice': costPrice,
      'rawSellingPrice': sellingPrice,
      'rawStockQuantity': stockQuantity,
      'rawLowStockThreshold': lowStockThreshold,
    };
  }
}
