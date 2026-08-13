import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import 'package:awe_pay/src/features/Registration/utils/registration_validator.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';

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
  bool _consentAccepted = false;
  String? _consentError;
  late final TapGestureRecognizer _termsLinkRecognizer;
  late final TapGestureRecognizer _privacyLinkRecognizer;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _termsLinkRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyLinkRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _termsLinkRecognizer.dispose();
    _privacyLinkRecognizer.dispose();
    super.dispose();
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _handleNext() async {
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

    setState(() => _isCheckingEmail = true);
    try {
      final eligibility =
          await ApiService().checkRegistrationEligibility(email: email);
      if (eligibility['emailAvailable'] == false) {
        setState(() {
          _emailError = eligibility['emailError'] as String? ??
              'This email is already registered';
          _isCheckingEmail = false;
        });
        return;
      }
    } catch (_) {
      // Network hiccup on the check itself — don't block the wizard on it.
      // Firebase Auth still rejects a genuinely duplicate email when the
      // account is actually created at the end of the flow.
    }
    setState(() => _isCheckingEmail = false);

    registrationDraft.fullName = fullName;
    registrationDraft.phoneNumber = phoneNumber;
    registrationDraft.email = email;
    registrationDraft.password = password;
    registrationDraft.termsAccepted = _consentAccepted;
    registrationDraft.privacyAccepted = _consentAccepted;

    setState(() {
      _consentError = _consentAccepted
          ? null
          : 'You must accept the Terms and Conditions and Privacy Policy';
    });

    if (_consentError != null) {
      return;
    }

    if (!mounted) return;
    context.push(AppRoutes.businessInformation);
  }

  Widget _buildConsentCheckbox({
    required bool value,
    required String? error,
    required ValueChanged<bool> onChanged,
  }) {
    const linkStyle = TextStyle(
      decoration: TextDecoration.underline,
      color: Color(0xFFE8A28D),
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      const TextSpan(text: 'I accept the '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: linkStyle,
                        recognizer: _termsLinkRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: linkStyle,
                        recognizer: _privacyLinkRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
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
              const SizedBox(height: 24),
              _buildConsentCheckbox(
                value: _consentAccepted,
                error: _consentError,
                onChanged: (checked) {
                  setState(() {
                    _consentAccepted = checked;
                    _consentError = null;
                  });
                },
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
                label: _isCheckingEmail ? 'Checking...' : 'Next',
                icon: Icons.arrow_forward,
                onPressed: _isCheckingEmail ? null : _handleNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
