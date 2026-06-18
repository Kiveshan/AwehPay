import 'package:flutter/material.dart';

import '../../../core/models/bank_account.dart';
import '../../../core/services/admin_business_service.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_text_field.dart';

class BusinessBankingScreen extends StatefulWidget {
  const BusinessBankingScreen({super.key, this.businessId});

  final String? businessId;

  @override
  State<BusinessBankingScreen> createState() => _BusinessBankingScreenState();
}

class _BusinessBankingScreenState extends State<BusinessBankingScreen> {
  final _service = AdminBusinessService();
  BankAccount? _account;
  bool _isLoading = true;

  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _branchCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountTypeController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final businessId = widget.businessId;
    if (businessId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final accounts = await _service.getBankAccounts(businessId);
    if (mounted) {
      final account = accounts.isNotEmpty
          ? accounts.firstWhere(
              (a) => a.isPrimary,
              orElse: () => accounts.first,
            )
          : null;

      setState(() {
        _account = account;
        if (account != null) {
          _bankNameController.text = account.bankName;
          _accountNumberController.text = account.accountNumberLast4;
          _accountTypeController.text = account.accountType;
          _branchNameController.text = account.branchName;
          _branchCodeController.text = account.branchCode;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.businessId == null) {
      return const AdminScaffold(
        title: 'Banking Details',
        child: Center(child: Text('No business selected')),
      );
    }

    return AdminScaffold(
      title: 'Banking Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8A28D)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Banking Details',
                        style: TextStyle(
                          color: Color(0xFF6C7078),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AdminTextField(
                              label: 'Bank Name',
                              isDense: true,
                              readOnly: true,
                              alignLabelAbove: true,
                              controller: _bankNameController,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AdminTextField(
                              label: 'Account Number',
                              isDense: true,
                              readOnly: true,
                              alignLabelAbove: true,
                              controller: _accountNumberController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AdminTextField(
                        label: 'Account Type',
                        isDense: true,
                        readOnly: true,
                        alignLabelAbove: true,
                        controller: _accountTypeController,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AdminTextField(
                              label: 'Branch Name',
                              isDense: true,
                              readOnly: true,
                              alignLabelAbove: true,
                              controller: _branchNameController,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AdminTextField(
                              label: 'Branch Code',
                              isDense: true,
                              readOnly: true,
                              alignLabelAbove: true,
                              controller: _branchCodeController,
                            ),
                          ),
                        ],
                      ),
                      if (_account == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text('No bank account found'),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
