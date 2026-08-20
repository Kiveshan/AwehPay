import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppUpdateRequiredException implements Exception {
  final String message;
  final String latestVersionName;
  final String currentVersionName;

  AppUpdateRequiredException({
    required this.message,
    required this.latestVersionName,
    required this.currentVersionName,
  });

  @override
  String toString() => message;
}

class VersionService {
  final http.Client _client;
  static const String baseUrl = String.fromEnvironment(
    'AWEHPAY_API_BASE_URL',
    defaultValue: 'https://api.awehpay.co.za',
  );

  VersionService({http.Client? client}) : _client = client ?? http.Client();

  /// Checks if the app needs to be updated by comparing current version
  /// with the latest version from the backend
  Future<void> checkForUpdates() async {
    // Get current app version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    // Send app version headers for backend compatibility check
    final headers = {
      'X-App-Version': currentVersion,
      'X-App-Version-Code': currentBuildNumber.toString(),
    };

    // Fetch latest version from backend
    final response = await _client.get(
      Uri.parse('$baseUrl/app-version'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      // If we can't check for updates, allow the user to proceed
      // (don't block login on network errors)
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (data['success'] != true) {
      // If backend returns error, allow user to proceed
      return;
    }

    // Check if backend indicates this version is too old for update check
    if (data['skipUpdateCheck'] == true) {
      // Backend determined this version should skip update check
      return;
    }

    final latestVersionData = data['latestVersion'] as Map<String, dynamic>;
    final latestVersionCode = int.tryParse(latestVersionData['versionCode'].toString()) ?? 0;
    final latestVersionName = latestVersionData['versionName'] as String;
    final isMandatory = latestVersionData['isMandatory'] as bool? ?? false;

    // Compare version codes
    if (latestVersionCode > currentBuildNumber && isMandatory) {
      throw AppUpdateRequiredException(
        message: 'A new version of the app is available. Please update to continue.',
        latestVersionName: latestVersionName,
        currentVersionName: currentVersion,
      );
    }
  }

  /// Gets the current app version info
  Future<PackageInfo> getCurrentVersionInfo() async {
    return PackageInfo.fromPlatform();
  }
}