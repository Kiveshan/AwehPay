import '../models/app_user.dart';
import '../models/bank_account.dart';
import '../models/business.dart';
import 'api_service.dart';

class AdminBusinessService {
  AdminBusinessService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<Business>> getBusinesses() async {
    final response = await _apiService.listBusinesses();
    return response
        .map((data) => Business.fromMap(data, data['businessId'] as String? ?? ''))
        .toList();
  }

  Future<Business?> getBusinessById(String businessId) async {
    final response = await _apiService.getBusinessDetails(businessId);
    final businessData = response['business'] as Map<String, dynamic>?;
    if (businessData == null) return null;
    return Business.fromMap(
      businessData,
      businessData['businessId'] as String? ?? businessId,
    );
  }

  Future<AppUser?> getUserById(String uid) async {
    final response = await _apiService.getAdminUser(uid);
    final userData = response['user'] as Map<String, dynamic>?;
    if (userData == null) return null;
    return AppUser.fromMap(userData, userData['uid'] as String? ?? uid);
  }

  Future<List<BankAccount>> getBankAccounts(String businessId) async {
    final response = await _apiService.getBusinessBankAccounts(businessId);
    return response
        .map((data) => BankAccount.fromMap(data, data['bankAccountId'] as String? ?? ''))
        .toList();
  }
}
