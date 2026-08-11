import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/biometric_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _canCheckBiometrics = false;
  bool _biometricEnabled = false;
  bool _isLoadingBiometrics = true;
  bool _isDisablingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final canCheck =
        await ref.read(biometricAuthServiceProvider).canCheckBiometrics;
    final storage = ref.read(secureStorageServiceProvider);
    final enabled = await storage.getBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheck;
      _biometricEnabled = enabled;
      _isLoadingBiometrics = false;
    });
  }

  Future<void> _onBiometricToggle(bool value) async {
    final storage = ref.read(secureStorageServiceProvider);

    if (!value) {
      await storage.clearBiometricCredentials();
      if (mounted) setState(() => _biometricEnabled = false);
      return;
    }

    final authenticated =
        await ref.read(biometricAuthServiceProvider).authenticate();
    if (!authenticated) return;

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || !mounted) return;

    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter your password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwordController.text,
        );
        await storage.setBiometricEmail(email);
        await storage.setBiometricPassword(passwordController.text);
        await storage.setBiometricEnabled(true);
        if (mounted) setState(() => _biometricEnabled = true);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Incorrect password. Biometric sign-in was not enabled.',
              ),
            ),
          );
        }
      }
    }
    passwordController.dispose();
  }

  Future<void> _confirmDisableAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBD5CE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.no_accounts_outlined,
                    color: Color(0xFF272A2F),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Disable Account',
                  style: TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This cancels your trial or subscription and signs you out. '
                  'You will not be able to access your account until you sign in '
                  'again, choose to re-enable it, and pay for a plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6C7078),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: const Color(0xFF6C7078),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Disable'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDisablingAccount = true);

    try {
      await ApiService().disableAccount();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go(AppRoutes.launch);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDisablingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to disable account: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader('Security'),
              const SizedBox(height: 12),
              if (_isLoadingBiometrics)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (!_canCheckBiometrics)
                const _SettingsCard(
                  child: Text(
                    'Biometric authentication is not available on this device.',
                    style: TextStyle(color: Color(0xFF6C7078), fontSize: 14),
                  ),
                )
              else
                _SettingsCard(
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint, color: Color(0xFF272A2F)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Biometric Sign-In',
                          style: TextStyle(
                            color: Color(0xFF272A2F),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: _biometricEnabled,
                        activeThumbColor: const Color(0xFFFEECC1),
                        activeTrackColor: const Color(0xFF272A2F),
                        onChanged: _onBiometricToggle,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              const _SectionHeader('Payments'),
              const SizedBox(height: 12),
              _SettingsCard(
                onTap: () => context.push(AppRoutes.editBankingDetails),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_outlined,
                        color: Color(0xFF272A2F)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Banking Details',
                            style: TextStyle(
                              color: Color(0xFF272A2F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Update the account your payouts settle to',
                            style: TextStyle(
                              color: Color(0xFF6C7078),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF6C7078)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionHeader('Danger Zone', color: Colors.red),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isDisablingAccount ? null : _confirmDisableAccount,
                icon: _isDisablingAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.no_accounts_outlined, color: Colors.red),
                label: Text(
                  _isDisablingAccount ? 'Disabling...' : 'Disable Account',
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color ?? const Color(0xFF272A2F),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
