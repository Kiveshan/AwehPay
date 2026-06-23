import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
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
  final ApiService _apiService = ApiService();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = true;
  String? _banksLoadError;
  String? _selectedBankCode;

  bool _isVerifyingAccount = false;
  String? _resolvedAccountName;
  String? _accountVerifyError;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _accountNumberController.addListener(_resetAccountVerification);
  }

  void _resetAccountVerification() {
    if (_resolvedAccountName != null || _accountVerifyError != null) {
      setState(() {
        _resolvedAccountName = null;
        _accountVerifyError = null;
      });
    }
  }

  Future<void> _verifyAccount() async {
    final accountNumber = _accountNumberController.text.trim();

    if (_selectedBankCode == null || accountNumber.isEmpty) {
      setState(() {
        _accountVerifyError = 'Select a bank and enter an account number first';
      });
      return;
    }

    setState(() {
      _isVerifyingAccount = true;
      _resolvedAccountName = null;
      _accountVerifyError = null;
    });

    try {
      final accountName = await _apiService.resolveAccountName(
        accountNumber: accountNumber,
        bankCode: _selectedBankCode!,
      );
      setState(() {
        _resolvedAccountName = accountName;
        _accountVerifyError = accountName == null ? 'Could not verify this account' : null;
      });
    } catch (e) {
      setState(() {
        _accountVerifyError = 'Could not verify this account';
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifyingAccount = false);
      }
    }
  }

  Future<void> _loadBanks() async {
    setState(() {
      _isLoadingBanks = true;
      _banksLoadError = null;
    });

    try {
      final banks = await _apiService.listBanks();
      setState(() {
        _banks = banks;
        _isLoadingBanks = false;
      });
    } catch (e) {
      setState(() {
        _banksLoadError = 'Failed to load banks';
        _isLoadingBanks = false;
      });
    }
  }

  @override
  void dispose() {
    _accountNumberController.removeListener(_resetAccountVerification);
    _accountNumberController.dispose();
    _accountTypeController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final accountNumber = _accountNumberController.text.trim();
    final accountType = _accountTypeController.text.trim();
    final branchName = _branchNameController.text.trim();
    final branchCode = _branchCodeController.text.trim();

    if (_selectedBankCode == null ||
        accountNumber.isEmpty ||
        accountType.isEmpty ||
        branchName.isEmpty ||
        branchCode.isEmpty) {
      setState(() {
        _errorMessage = 'Complete all payment details';
      });
      return;
    }

    final selectedBank =
        _banks.firstWhere((bank) => bank['code'] == _selectedBankCode);

    registrationDraft.bankName = selectedBank['name'] as String;
    registrationDraft.bankCode = _selectedBankCode!;
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
              const Text(
                'Bank',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              if (_isLoadingBanks)
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
              else if (_banksLoadError != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _banksLoadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadBanks,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedBankCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select your bank',
                    suffixIcon:
                        Icon(Icons.account_balance_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  items: _banks
                      .map(
                        (bank) => DropdownMenuItem<String>(
                          value: bank['code'] as String,
                          child: Text(bank['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBankCode = value;
                      _resolvedAccountName = null;
                      _accountVerifyError = null;
                    });
                  },
                ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Account Number',
                hintText: 'Enter your account number',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.numbers_outlined, size: 18),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isVerifyingAccount ? null : _verifyAccount,
                  icon: _isVerifyingAccount
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined, size: 16),
                  label: Text(_isVerifyingAccount ? 'Verifying...' : 'Verify account'),
                ),
              ),
              if (_resolvedAccountName != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Account holder: $_resolvedAccountName',
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              if (_accountVerifyError != null)
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _accountVerifyError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
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
