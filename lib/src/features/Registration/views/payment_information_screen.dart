import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/auth_service.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';

class PaymentInformationScreen extends StatefulWidget {
  const PaymentInformationScreen({super.key});

  @override
  State<PaymentInformationScreen> createState() =>
      _PaymentInformationScreenState();
}

class _PaymentInformationScreenState extends State<PaymentInformationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountTypeController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final bankName = _bankNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final accountType = _accountTypeController.text.trim();
    final branchName = _branchNameController.text.trim();
    final branchCode = _branchCodeController.text.trim();

    if (bankName.isEmpty ||
        accountNumber.isEmpty ||
        accountType.isEmpty ||
        branchName.isEmpty ||
        branchCode.isEmpty) {
      setState(() {
        _errorMessage = 'Complete all payment details';
      });
      return;
    }

    registrationDraft.bankName = bankName;
    registrationDraft.accountNumber = accountNumber;
    registrationDraft.accountType = accountType;
    registrationDraft.branchName = branchName;
    registrationDraft.branchCode = branchCode;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _authService.registerBusinessOwner(registrationDraft);

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.accountCreated);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message ?? 'Unable to create account';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to create account';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Payment Information',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminTextField(
                label: 'Bank',
                hintText: 'Enter your bank name',
                controller: _bankNameController,
                suffixIcon:
                    const Icon(Icons.account_balance_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Account Number',
                hintText: 'Enter your account number',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.numbers_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Account Type',
                hintText: 'Enter account type',
                controller: _accountTypeController,
                suffixIcon: const Icon(Icons.credit_card_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Branch Name',
                hintText: 'Enter branch name',
                controller: _branchNameController,
                suffixIcon: const Icon(Icons.store_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Branch Code',
                hintText: 'Enter branch code',
                controller: _branchCodeController,
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.code_outlined, size: 18),
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
                label: _isLoading ? 'Creating account...' : 'Complete',
                icon: Icons.arrow_forward,
                onPressed: _isLoading ? null : _handleComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
