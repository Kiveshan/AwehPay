import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricEmailKey = 'biometric_email';
  static const _biometricPasswordKey = 'biometric_password';

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<String?> getBiometricEmail() async {
    return _storage.read(key: _biometricEmailKey);
  }

  Future<void> setBiometricEmail(String email) async {
    await _storage.write(key: _biometricEmailKey, value: email);
  }

  Future<String?> getBiometricPassword() async {
    return _storage.read(key: _biometricPasswordKey);
  }

  Future<void> setBiometricPassword(String password) async {
    await _storage.write(key: _biometricPasswordKey, value: password);
  }

  Future<void> clearBiometricCredentials() async {
    await Future.wait([
      _storage.delete(key: _biometricEnabledKey),
      _storage.delete(key: _biometricEmailKey),
      _storage.delete(key: _biometricPasswordKey),
    ]);
  }
}
