part of 'api_service.dart';

mixin _InventoryApiMixin on _ApiServiceBase {
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

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String barcode,
    required double costPrice,
    required double sellingPrice,
    required double totalCost,
    required bool vat,
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
        'totalCost': totalCost,
        'vat': vat,
        'stockQuantity': stockQuantity,
        'category': category,
        'lowStockThreshold': lowStockThreshold,
      }),
    );

    return _decodeResponse(response);
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
    required double totalCost,
    required bool vat,
    required int stockQuantity,
    required int lowStockThreshold,
    required String category,
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
        'totalCost': totalCost,
        'vat': vat,
        'stockQuantity': stockQuantity,
        'lowStockThreshold': lowStockThreshold,
        'category': category,
      }),
    );

    return _decodeResponse(response);
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
}
