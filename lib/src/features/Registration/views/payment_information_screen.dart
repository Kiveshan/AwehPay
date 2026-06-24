import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import 'package:awe_pay/src/features/Registration/utils/registration_validator.dart';
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
  String? _selectedAccountType;
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _bankError;
  String? _accountNumberError;
  String? _accountTypeError;
  String? _branchNameError;
  String? _branchCodeError;

  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = true;
  String? _banksLoadError;
  String? _selectedBankCode;

  @override
  void initState() {
    super.initState();
    _loadBanks();
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
    _accountNumberController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final accountNumber = _accountNumberController.text.trim();
    final accountType = _selectedAccountType ?? '';
    final branchName = _branchNameController.text.trim();
    final branchCode = _branchCodeController.text.trim();

    setState(() {
      _bankError = RegistrationValidator.bankSelected(_selectedBankCode);
      _accountNumberError =
          RegistrationValidator.accountNumber(accountNumber);
      _accountTypeError = accountType.isEmpty ? 'Please select an account type' : null;
      _branchNameError = RegistrationValidator.branchName(branchName);
      _branchCodeError = RegistrationValidator.branchCode(branchCode);
      _errorMessage = null;
    });

    if (_bankError != null ||
        _accountNumberError != null ||
        _accountTypeError != null ||
        _branchNameError != null ||
        _branchCodeError != null) {
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
                  decoration: InputDecoration(
                    hintText: 'Select your bank',
                    suffixIcon:
                        const Icon(Icons.account_balance_outlined, size: 18),
                    border: const OutlineInputBorder(),
                    errorText: _bankError,
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
                errorText: _accountNumberError,
              ),
              const SizedBox(height: 18),
              const Text(
                'Account Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountType,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select account type',
                  suffixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                  border: const OutlineInputBorder(),
                  errorText: _accountTypeError,
                ),
                items: const [
                  DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'Current', child: Text('Current')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'Transmission', child: Text('Transmission')),
                  DropdownMenuItem(value: 'Business', child: Text('Business')),
                  DropdownMenuItem(value: 'Corporate', child: Text('Corporate')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value;
                    _accountTypeError = null;
                  });
                },
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Branch Name',
                hintText: 'Enter branch name',
                controller: _branchNameController,
                suffixIcon: const Icon(Icons.store_outlined, size: 18),
                errorText: _branchNameError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Branch Code',
                hintText: 'Enter branch code',
                controller: _branchCodeController,
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.code_outlined, size: 18),
                errorText: _branchCodeError,
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
