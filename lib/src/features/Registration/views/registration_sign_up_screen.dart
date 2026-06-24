import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import 'package:awe_pay/src/features/Registration/utils/registration_validator.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';

class RegistrationSignUpScreen extends StatefulWidget {
  const RegistrationSignUpScreen({super.key});

  @override
  State<RegistrationSignUpScreen> createState() =>
      _RegistrationSignUpScreenState();
}

class _RegistrationSignUpScreenState extends State<RegistrationSignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  String? _fullNameError;
  String? _phoneNumberError;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final fullName = _fullNameController.text.trim();
    final phoneNumber = _contactNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _fullNameError = RegistrationValidator.fullName(fullName);
      _phoneNumberError = RegistrationValidator.phoneNumber(phoneNumber);
      _emailError = RegistrationValidator.email(email);
      _passwordError = RegistrationValidator.password(password);
      _errorMessage = null;
    });

    if (_fullNameError != null ||
        _phoneNumberError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    registrationDraft.fullName = fullName;
    registrationDraft.phoneNumber = phoneNumber;
    registrationDraft.email = email;
    registrationDraft.password = password;

    context.push(AppRoutes.businessInformation);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Personal Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminTextField(
                label: 'Full Name',
                hintText: 'Enter your full name',
                controller: _fullNameController,
                suffixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                errorText: _fullNameError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Contact Number',
                hintText: 'Enter your cell number',
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                suffixIcon: const Icon(Icons.phone_outlined, size: 18),
                errorText: _phoneNumberError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Email Address',
                hintText: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                suffixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                errorText: _emailError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Password',
                hintText: 'Create a password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                errorText: _passwordError,
              ),
              const SizedBox(height: 28),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              AdminPrimaryButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: _handleNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
