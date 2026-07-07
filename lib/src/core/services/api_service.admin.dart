part of 'api_service.dart';

mixin _AdminApiMixin on _ApiServiceBase {
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

  Future<List<Map<String, dynamic>>> listBanks() async {
    final response = await _client.get(_uri('/payments/banks'));
    final body = _decodeResponse(response);
    final banks = body['banks'] as List<dynamic>? ?? [];

    return banks.map((bank) => Map<String, dynamic>.from(bank as Map)).toList();
  }

  Future<String?> resolveAccountName({
    required String accountNumber,
    required String bankCode,
  }) async {
    final response = await _client.get(
      _uri('/payments/resolve-account?accountNumber=$accountNumber&bankCode=$bankCode'),
    );
    final body = _decodeResponse(response);
    return body['accountName'] as String?;
  }

  Future<Map<String, dynamic>> createPaystackSubaccount({
    required String businessId,
    required String bankAccountId,
    required String businessName,
    required String bankCode,
    required String accountNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No Firebase user is signed in');

    final idToken = await user.getIdToken();
    final response = await _client.post(
      _uri('/payments/subaccount'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'businessId': businessId,
        'bankAccountId': bankAccountId,
        'businessName': businessName,
        'bankCode': bankCode,
        'accountNumber': accountNumber,
      }),
    );

    return _decodeResponse(response);
  }
}
