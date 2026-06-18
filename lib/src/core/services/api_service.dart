import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = String.fromEnvironment(
    'AWEHPAY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client.get(_uri('/health'));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> matchScannedProductsFromRawText({
    required String rawOcrText,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/match-scanned-products-from-raw-text'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'rawOcrText': rawOcrText}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> verifyCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/verify-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> saveUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final response = await _client.post(
      _uri('/test-user-profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'name': name,
        'email': email,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String barcode,
    required double costPrice,
    required double sellingPrice,
    required int stockQuantity,
    required String category,
    required int lowStockThreshold,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/add-product'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'name': name,
        'barcode': barcode,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'stockQuantity': stockQuantity,
        'category': category,
        'lowStockThreshold': lowStockThreshold,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> createQrTransaction({
    required List<Map<String, dynamic>> items,
    required double amountTotal,
    String? customerEmail,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/purchases/qr-transaction'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'items': items,
        'amountTotal': amountTotal,
        'customerEmail': customerEmail ?? '',
      }),
    );

    return _decodeResponse(response);
  }

  Future<String> verifyPayment(String reference) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.get(
      _uri('/purchases/verify-payment/$reference'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    final body = _decodeResponse(response);
    return body['status'] as String;
  }

  Future<Map<String, dynamic>> createCashTransaction({
    required List<Map<String, dynamic>> items,
    required double amountSubtotal,
    required double amountTotal,
    required double amountCollected,
    String? customerPhone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/purchases/cash-transaction'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'items': items,
        'amountSubtotal': amountSubtotal,
        'amountTotal': amountTotal,
        'amountCollected': amountCollected,
        'customerPhone': customerPhone ?? '',
      }),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> getProductsAndServices() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.get(
      _uri('/purchases/catalog'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    final body = _decodeResponse(response);
    return List<Map<String, dynamic>>.from(body['items'] as List);
  }

  Future<Map<String, dynamic>> fetchProductOptions() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/options'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> lookupProductByBarcode(String barcode) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/lookup-barcode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'barcode': barcode}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> matchScannedProducts({
    required List<Map<String, dynamic>> products,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/match-scanned-products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'products': products}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> saveInvoiceScan({
    required String rawOcrText,
    required List<Map<String, dynamic>> products,
    String supplierName = '',
    String invoiceNumber = '',
    String invoiceImageUrl = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/save-invoice-scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'rawOcrText': rawOcrText,
        'products': products,
        'supplierName': supplierName,
        'invoiceNumber': invoiceNumber,
        'invoiceImageUrl': invoiceImageUrl,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> fetchProductList() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required String barcode,
    required double costPrice,
    required double sellingPrice,
    required int stockQuantity,
    required int lowStockThreshold,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/product/update-product'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'productId': productId,
        'barcode': barcode,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'stockQuantity': stockQuantity,
        'lowStockThreshold': lowStockThreshold,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> addFixedExpense({
    required String name,
    required String frequency,
    required double amount,
    String description = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/business/insights/add-fixed-expense'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'name': name,
        'frequency': frequency,
        'amount': amount,
        'description': description,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteFixedExpense({
    required String expenseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.delete(
      _uri('/business/insights/delete-fixed-expense'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'expenseId': expenseId}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getAnalytics(String date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.get(
      _uri('/business/insights/analytics?date=$date'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> getFixedExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.get(
      _uri('/business/insights/fixed-expenses'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    final body = _decodeResponse(response);
    return List<Map<String, dynamic>>.from(body['expenses'] as List);
  }

  Future<Map<String, dynamic>> addService({
    required String name,
    required String category,
    required int durationMinutes,
    required double costPrice,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/service/add-service'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'name': name,
        'category': category,
        'durationMinutes': durationMinutes,
        'costPrice': costPrice,
      }),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listServices() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/inventory/service/list-services'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final body = _decodeResponse(response);
    final services = body['services'] as List<dynamic>? ?? [];

    return services
        .map((service) => Map<String, dynamic>.from(service as Map))
        .toList();
  }

  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    required String name,
    required String category,
    required int durationMinutes,
    required double costPrice,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.put(
      _uri('/inventory/service/update-service/$serviceId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'name': name,
        'category': category,
        'durationMinutes': durationMinutes,
        'costPrice': costPrice,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteService({
    required String serviceId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.delete(
      _uri('/inventory/service/delete-service/$serviceId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> recordSale({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double subtotal,
    required double totalAmount,
    double taxAmount = 0,
    double discountAmount = 0,
    String customerName = '',
    String customerPhoneNumber = '',
    String customerEmail = '',
    String notes = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/business/sales/record-sale'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'items': items,
        'paymentMethod': paymentMethod,
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'customerName': customerName,
        'customerPhoneNumber': customerPhoneNumber,
        'customerEmail': customerEmail,
        'notes': notes,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getDailySalesSummary({String? date}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/business/sales/daily-summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'date': date,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getTransactions({String? date}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/business/sales/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'date': date,
      }),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listBusinesses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/admin/businesses/list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final body = _decodeResponse(response);
    final businesses = body['businesses'] as List<dynamic>? ?? [];
    return businesses
        .map((b) => Map<String, dynamic>.from(b as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getBusinessDetails(String businessId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/admin/businesses/details'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'businessId': businessId}),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> getBusinessBankAccounts(
    String businessId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/admin/businesses/bank-accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'businessId': businessId}),
    );

    final body = _decodeResponse(response);
    final accounts = body['accounts'] as List<dynamic>? ?? [];
    return accounts
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getAdminUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/admin/businesses/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'uid': uid}),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listSubscriptionTiers() async {
    final response = await _client.get(
      _uri('/subscription-tiers/list'),
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decodeResponse(response);
    final tiers = body['tiers'] as List<dynamic>? ?? [];

    return tiers.map((tier) => Map<String, dynamic>.from(tier as Map)).toList();
  }

  Future<Map<String, dynamic>> createSubscriptionTier({
    required String name,
    required String code,
    required double price,
    required String currency,
    required String billingPeriod,
    required double setupFee,
    required String description,
    required int displayOrder,
    required bool isActive,
    required bool isRecommended,
    required List<String> features,
    required Map<String, dynamic> limits,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/subscription-tiers/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
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
        'limits': limits,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateSubscriptionTier({
    required String tierId,
    String? name,
    String? code,
    double? price,
    String? currency,
    String? billingPeriod,
    double? setupFee,
    String? description,
    int? displayOrder,
    bool? isActive,
    bool? isRecommended,
    List<String>? features,
    Map<String, dynamic>? limits,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No Firebase user is signed in');
    }

    final idToken = await user.getIdToken();
    final body = <String, dynamic>{'idToken': idToken};

    if (name != null) body['name'] = name;
    if (code != null) body['code'] = code;
    if (price != null) body['price'] = price;
    if (currency != null) body['currency'] = currency;
    if (billingPeriod != null) body['billingPeriod'] = billingPeriod;
    if (setupFee != null) body['setupFee'] = setupFee;
    if (description != null) body['description'] = description;
    if (displayOrder != null) body['displayOrder'] = displayOrder;
    if (isActive != null) body['isActive'] = isActive;
    if (isRecommended != null) body['isRecommended'] = isRecommended;
    if (features != null) body['features'] = features;
    if (limits != null) body['limits'] = limits;

    final response = await _client.put(
      _uri('/subscription-tiers/$tierId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getAdminAnalyticsSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/admin/analytics/summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['error'] ?? 'Request failed with ${response.statusCode}',
      );
    }

    return body;
  }
}
