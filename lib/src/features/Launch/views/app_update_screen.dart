import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';

/// Shown when the app version check determines that a mandatory update
/// is required. The user cannot proceed until they update the app.
class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({super.key, this.message});

  final String? message;

  Future<void> _openGooglePlay() async {
    const url = 'https://play.google.com/store/apps/details?id=com.awehpay.app';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEECC1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.system_update,
                      color: Color(0xFF272A2F),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF272A2F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message ??
                        'A new version of AwehBiz is available. Please update to continue using the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6C7078),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AdminPrimaryButton(
                    label: 'Update Now',
                    onPressed: _openGooglePlay,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You need to update to the latest version to continue. This update includes important security fixes and new features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}