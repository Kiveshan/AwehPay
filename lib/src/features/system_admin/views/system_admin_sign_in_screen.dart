import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'widgets/admin_primary_button.dart';
import 'widgets/admin_text_field.dart';

class SystemAdminSignInScreen extends StatelessWidget {
  const SystemAdminSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  const AdminTextField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    suffixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                  ),
                  const SizedBox(height: 18),
                  const AdminTextField(
                    label: 'Password',
                    hintText: '***************',
                    obscureText: true,
                    suffixIcon: Icon(Icons.visibility_off_outlined, size: 18),
                  ),
                  const SizedBox(height: 28),
                  AdminPrimaryButton(
                    label: 'Sign in',
                    onPressed: () => context.push(AppRoutes.adminHome),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.signUp),
                    child: const Text("Don't have an account? Sign up"),
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
