import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/biometric_providers.dart';

class BiometricSettingsButton extends ConsumerWidget {
  const BiometricSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined, color: Color(0xFF272A2F)),
      onPressed: () => _showBiometricSettings(context, ref),
    );
  }

  Future<void> _showBiometricSettings(BuildContext context, WidgetRef ref) async {
    final canCheck = await ref.read(biometricAuthServiceProvider).canCheckBiometrics;
    final storage = ref.read(secureStorageServiceProvider);
    var isEnabled = await storage.getBiometricEnabled();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                        color: const Color(0xFFFEECC1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        color: Color(0xFF272A2F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Biometric Sign-In',
                      style: TextStyle(
                        color: Color(0xFF272A2F),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!canCheck)
                      const Text(
                        'Biometric authentication is not available on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6C7078),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      )
                    else ...[
                      const Text(
                        'Use your fingerprint for faster and more secure access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6C7078),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Enable Biometric Sign-In',
                              style: TextStyle(
                                color: Color(0xFF272A2F),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: isEnabled,
                            activeThumbColor: const Color(0xFFFEECC1),
                            activeTrackColor: const Color(0xFF272A2F),
                            onChanged: (value) async {
                              if (value) {
                                final authenticated = await ref
                                    .read(biometricAuthServiceProvider)
                                    .authenticate();
                                if (!authenticated) return;

                                final email = FirebaseAuth.instance.currentUser?.email;
                                if (email == null) return;

                                if (!context.mounted) return;

                                final passwordController = TextEditingController();
                                final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
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
                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                      email: email,
                                      password: passwordController.text,
                                    );
                                    await storage.setBiometricEmail(email);
                                    await storage.setBiometricPassword(passwordController.text);
                                    await storage.setBiometricEnabled(true);
                                    setState(() => isEnabled = true);
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Incorrect password. Biometric sign-in was not enabled.'),
                                        ),
                                      );
                                    }
                                  }
                                }
                                passwordController.dispose();
                              } else {
                                await storage.clearBiometricCredentials();
                                setState(() => isEnabled = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEECC1),
                          foregroundColor: const Color(0xFF272A2F),
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
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
