import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: '',
      showBackButton: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your account has been created!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AdminPrimaryButton(
                label: 'Start',
                icon: Icons.arrow_forward,
                onPressed: () => context.go(AppRoutes.adminSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
