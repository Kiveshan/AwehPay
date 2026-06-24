import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_auth_service.dart';
import '../services/secure_storage_service.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return storage.getBiometricEnabled();
});

final canCheckBiometricsProvider = FutureProvider<bool>((ref) async {
  final biometric = ref.watch(biometricAuthServiceProvider);
  return biometric.canCheckBiometrics;
});
