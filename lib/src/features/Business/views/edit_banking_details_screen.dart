import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import 'package:awe_pay/src/features/Registration/utils/registration_validator.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';

/// Lets a signed-in business owner change the bank account their payouts
/// settle to. Mirrors the registration Payment Information form, but the full
/// account number is never stored client-side (only the last 4 digits are),
/// so the account number field always starts blank and must be re-entered to
/// save a change — same as at registration.
class EditBankingDetailsScreen extends StatefulWidget {
  const EditBankingDetailsScreen({super.key});

  @override
  State<EditBankingDetailsScreen> createState() =>
      _EditBankingDetailsScreenState();
}

class _EditBankingDetailsScreenState extends State<EditBankingDetailsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  String? _selectedAccountType;
  String? _selectedBankCode;

  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = true;
  String? _banksLoadError;

  String? _businessId;
  String? _bankAccountId;
  String? _currentBankName;
  String? _currentLast4;
  bool _isLoadingAccount = true;
  String? _accountLoadError;

  bool _isSaving = false;
  String? _errorMessage;
  String? _bankError;
  String? _accountNumberError;
  String? _accountTypeError;
  String? _branchNameError;
  String? _branchCodeError;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _loadCurrentAccount();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    super.dispose();
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
    } catch (_) {
      setState(() {
        _banksLoadError = 'Failed to load banks';
        _isLoadingBanks = false;
      });
    }
  }

  Future<void> _loadCurrentAccount() async {
    setState(() {
      _isLoadingAccount = true;
      _accountLoadError = null;
    });

    try {
      final businessId = await _apiService.getCurrentBusinessId();
      if (businessId == null) {
        setState(() {
          _accountLoadError = 'No business found for this account';
          _isLoadingAccount = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('bankAccounts')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted) return;

      _businessId = businessId;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _accountLoadError = 'No bank account found for this business';
          _isLoadingAccount = false;
        });
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      setState(() {
        _bankAccountId = doc.id;
        _currentBankName = data['bankName'] as String?;
        _currentLast4 = data['accountNumberLast4'] as String?;
        _selectedBankCode = data['bankCode'] as String?;
        _selectedAccountType = data['accountType'] as String?;
        _branchNameController.text = data['branchName'] as String? ?? '';
        _branchCodeController.text = data['branchCode'] as String? ?? '';
        _isLoadingAccount = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accountLoadError = 'Failed to load your current banking details';
        _isLoadingAccount = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final accountNumber = _accountNumberController.text.trim();
    final accountType = _selectedAccountType ?? '';
    final branchName = _branchNameController.text.trim();
    final branchCode = _branchCodeController.text.trim();

    setState(() {
      _bankError = RegistrationValidator.bankSelected(_selectedBankCode);
      _accountNumberError =
          RegistrationValidator.accountNumber(accountNumber);
      _accountTypeError =
          accountType.isEmpty ? 'Please select an account type' : null;
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

    final businessId = _businessId;
    final bankAccountId = _bankAccountId;
    if (businessId == null || bankAccountId == null) {
      setState(() => _errorMessage = 'No bank account found for this business');
      return;
    }

    final selectedBank =
        _banks.firstWhere((bank) => bank['code'] == _selectedBankCode);

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _apiService.updateBankingDetails(
        businessId: businessId,
        bankAccountId: bankAccountId,
        bankName: selectedBank['name'] as String,
        bankCode: _selectedBankCode!,
        accountNumber: accountNumber,
        accountType: accountType,
        branchName: branchName,
        branchCode: branchCode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banking details updated')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to update banking details. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingBanks || _isLoadingAccount;

    return AdminScaffold(
      title: 'Banking Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentBankName != null && _currentLast4 != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Currently linked: $_currentBankName •••• $_currentLast4',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C7078),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_accountLoadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _accountLoadError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
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
                hintText: 'Enter your new account number',
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
                  DropdownMenuItem(
                    value: 'Transmission',
                    child: Text('Transmission'),
                  ),
                  DropdownMenuItem(value: 'Business', child: Text('Business')),
                  DropdownMenuItem(
                    value: 'Corporate',
                    child: Text('Corporate'),
                  ),
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
                label: _isSaving ? 'Saving...' : 'Save Changes',
                icon: Icons.check,
                onPressed: (isLoading || _isSaving) ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
