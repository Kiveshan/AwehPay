import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';

/// Shown instead of the business home screen when /verify-token reports the
/// signed-in account was disabled by its own owner (Settings > Disable
/// Account). Offers to reactivate it — reactivating only clears the disabled
/// flag, the subscription itself stays cancelled, so the very next
/// /verify-token check routes on into the normal subscription paywall where
/// the owner has to pay to actually regain access.
class AccountDisabledScreen extends StatefulWidget {
  const AccountDisabledScreen({super.key, this.message});

  final String? message;

  @override
  State<AccountDisabledScreen> createState() => _AccountDisabledScreenState();
}

class _AccountDisabledScreenState extends State<AccountDisabledScreen> {
  bool _isEnabling = false;
  String? _errorMessage;

  Future<void> _enableAccount() async {
    setState(() {
      _isEnabling = true;
      _errorMessage = null;
    });

    try {
      await ApiService().enableAccount();

      try {
        await ApiService().verifyCurrentUserToken();
        if (!mounted) return;
        context.go(AppRoutes.businessHome);
      } on SubscriptionExpiredException catch (error) {
        if (!mounted) return;
        context.go(AppRoutes.subscriptionExpired, extra: error.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isEnabling = false;
        _errorMessage = 'Could not enable your account. Please try again.';
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRoutes.adminSignIn);
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
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.pause_circle_outline,
                    size: 56,
                    color: Color(0xFFDFA890),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Account Disabled',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF272A2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message ??
                        'This account was disabled at your request.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6C7078)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Would you like to enable it again? You will need to choose '
                    'and pay for a subscription plan to regain access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF6C7078)),
                  ),
                  const SizedBox(height: 28),
                  AdminPrimaryButton(
                    label: _isEnabling ? 'Enabling...' : 'Enable My Account',
                    onPressed: _isEnabling ? null : _enableAccount,
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isEnabling ? null : _logout,
                    child: const Text('Log out'),
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
