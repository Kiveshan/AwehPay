import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionTier {
  final String tierId;
  final String name;
  final String code;
  final double price;
  final String currency;
  final String billingPeriod;
  final double setupFee;
  final String description;
  final int displayOrder;
  final bool isActive;
  final bool isRecommended;
  final List<String> features;
  final SubscriptionLimits limits;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionTier({
    required this.tierId,
    required this.name,
    required this.code,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.setupFee,
    required this.description,
    required this.displayOrder,
    required this.isActive,
    required this.isRecommended,
    required this.features,
    required this.limits,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionTier.fromMap(Map<String, dynamic> map, String docId) {
    final limitsMap = map['limits'] as Map<String, dynamic>? ?? {};

    return SubscriptionTier(
      tierId: map['tierId'] as String? ?? docId,
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'ZAR',
      billingPeriod: map['billingPeriod'] as String? ?? 'free',
      setupFee: (map['setupFee'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? false,
      isRecommended: map['isRecommended'] as bool? ?? false,
      features: (map['features'] as List<dynamic>?)?.cast<String>() ?? [],
      limits: SubscriptionLimits.fromMap(limitsMap),
      createdBy: map['createdBy'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tierId': tierId,
      'name': name,
      'code': code,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'setupFee': setupFee,
      'description': description,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'isRecommended': isRecommended,
      'features': features,
      'limits': limits.toMap(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class SubscriptionLimits {
  final int? maxProducts;
  final int? maxServices;
  final int? maxCardPaymentsPerDay;
  final bool barcodeScannerEnabled;
  final bool lowStockAlertsEnabled;
  final bool analyticsEnabled;
  final bool cashSalesEnabled;
  final bool cardPaymentsEnabled;
  final bool expenseTrackingEnabled;

  SubscriptionLimits({
    this.maxProducts,
    this.maxServices,
    this.maxCardPaymentsPerDay,
    required this.barcodeScannerEnabled,
    required this.lowStockAlertsEnabled,
    required this.analyticsEnabled,
    required this.cashSalesEnabled,
    required this.cardPaymentsEnabled,
    required this.expenseTrackingEnabled,
  });

  bool get hasRestrictions =>
      maxProducts != null ||
      maxServices != null ||
      maxCardPaymentsPerDay != null ||
      !barcodeScannerEnabled ||
      !lowStockAlertsEnabled ||
      !analyticsEnabled ||
      !cashSalesEnabled ||
      !cardPaymentsEnabled ||
      !expenseTrackingEnabled;

  factory SubscriptionLimits.fromMap(Map<String, dynamic> map) {
    return SubscriptionLimits(
      maxProducts: map['maxProducts'] == null
          ? null
          : (map['maxProducts'] as num).toInt(),
      maxServices: map['maxServices'] == null
          ? null
          : (map['maxServices'] as num).toInt(),
      maxCardPaymentsPerDay: map['maxCardPaymentsPerDay'] == null
          ? null
          : (map['maxCardPaymentsPerDay'] as num).toInt(),
      barcodeScannerEnabled: map['barcodeScannerEnabled'] as bool? ?? false,
      lowStockAlertsEnabled: map['lowStockAlertsEnabled'] as bool? ?? false,
      analyticsEnabled: map['analyticsEnabled'] as bool? ?? false,
      cashSalesEnabled: map['cashSalesEnabled'] as bool? ?? true,
      cardPaymentsEnabled: map['cardPaymentsEnabled'] as bool? ?? true,
      expenseTrackingEnabled: map['expenseTrackingEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxProducts': maxProducts,
      'maxServices': maxServices,
      'maxCardPaymentsPerDay': maxCardPaymentsPerDay,
      'barcodeScannerEnabled': barcodeScannerEnabled,
      'lowStockAlertsEnabled': lowStockAlertsEnabled,
      'analyticsEnabled': analyticsEnabled,
      'cashSalesEnabled': cashSalesEnabled,
      'cardPaymentsEnabled': cardPaymentsEnabled,
      'expenseTrackingEnabled': expenseTrackingEnabled,
    };
  }
}
