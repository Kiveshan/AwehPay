import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

part 'api_service.inventory.dart';
part 'api_service.purchases.dart';
part 'api_service.admin.dart';

class _ApiServiceBase {
  _ApiServiceBase({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = String.fromEnvironment(
    'AWEHPAY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

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

class ApiService extends _ApiServiceBase
    with _InventoryApiMixin, _PurchasesApiMixin, _AdminApiMixin {
  ApiService({http.Client? client}) : super(client: client);

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client.get(_uri('/health'));
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
}
