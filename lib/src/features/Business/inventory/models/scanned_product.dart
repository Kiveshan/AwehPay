class ScannedProduct {
  const ScannedProduct({
    required this.name,
    required this.quantity,
    required this.costPrice,
    required this.category,
    required this.confidence,
    this.barcode,
    this.sellingPrice,
    this.lowStockThreshold,
    this.unit = 'item',
    this.isExistingProduct = false,
    this.matchedProductId,
    this.existingProduct,
  });

  final String name;
  final int quantity;
  final double costPrice;
  final String category;
  final String? barcode;
  final double? sellingPrice;
  final int? lowStockThreshold;
  final String unit;
  final double confidence;
  final bool isExistingProduct;
  final String? matchedProductId;
  final Map<String, dynamic>? existingProduct;

  ScannedProduct copyWith({
    String? name,
    int? quantity,
    double? costPrice,
    String? category,
    String? barcode,
    double? sellingPrice,
    int? lowStockThreshold,
    String? unit,
    double? confidence,
    bool? isExistingProduct,
    String? matchedProductId,
    Map<String, dynamic>? existingProduct,
  }) {
    return ScannedProduct(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      isExistingProduct: isExistingProduct ?? this.isExistingProduct,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      existingProduct: existingProduct ?? this.existingProduct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'costPrice': costPrice,
      'category': category,
      'barcode': barcode ?? '',
      'sellingPrice': sellingPrice,
      'lowStockThreshold': lowStockThreshold,
      'unit': unit,
      'confidence': confidence,
      'isExistingProduct': isExistingProduct,
      'matchedProductId': matchedProductId,
    };
  }

  factory ScannedProduct.fromJson(Map<String, dynamic> json) {
    final existingProduct = json['existingProduct'] is Map
        ? Map<String, dynamic>.from(json['existingProduct'] as Map)
        : null;

    return ScannedProduct(
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?) ?? 'Other',
      barcode: json['barcode'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ??
          (existingProduct?['sellingPrice'] as num?)?.toDouble(),
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ??
          (existingProduct?['lowStockThreshold'] as num?)?.toInt(),
      unit: (json['unit'] as String?) ??
          (existingProduct?['unit'] as String?) ??
          'item',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      isExistingProduct: json['isExistingProduct'] == true,
      matchedProductId: json['matchedProductId'] as String?,
      existingProduct: existingProduct,
    );
  }
}
