part of 'api_service.dart';

mixin _PurchasesApiMixin on _ApiServiceBase {
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

  /// Verifies a Google Play subscription purchase server-side and, on success, grants
  /// the matching tier. The client-local purchase state is never trusted directly —
  /// this call is what actually updates businesses/{id}.subscription in Firestore.
  Future<Map<String, dynamic>> verifyGooglePlayPurchase({
    required String purchaseToken,
    required String productId,
    String? basePlanId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/purchases/verify-google-play'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
        'basePlanId': basePlanId,
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> createCashTransaction({
    required List<Map<String, dynamic>> items,
    required double amountSubtotal,
    required double amountTotal,
    required double amountCollected,
    String? customerEmail,
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
        'customerEmail': customerEmail ?? '',
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
}
