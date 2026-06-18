import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

enum _Frequency { monthly, weekly }

class _Expense {
  final String expenseId;
  final String name;
  final _Frequency frequency;
  final double amount;

  const _Expense({
    required this.expenseId,
    required this.name,
    required this.frequency,
    required this.amount,
  });
}

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  _Frequency _selectedFrequency = _Frequency.monthly;
  final _apiService = ApiService();

  List<_Expense> _expenses = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await _apiService.getFixedExpenses();
      setState(() {
        _expenses = data
            .map((e) => _Expense(
                  expenseId: e['expenseId'] as String,
                  name: e['name'] as String,
                  frequency: (e['frequency'] as String) == 'weekly'
                      ? _Frequency.weekly
                      : _Frequency.monthly,
                  amount: (e['amount'] as num).toDouble(),
                ))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load expenses: $e')),
        );
      }
    }
  }

  double get _estimatedMonthly {
    double total = 0;
    for (final e in _expenses) {
      total += e.frequency == _Frequency.weekly ? e.amount * 4 : e.amount;
    }
    return total;
  }

  Future<void> _addExpense() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null) return;

    setState(() => _saving = true);
    try {
      final result = await _apiService.addFixedExpense(
        name: name,
        frequency:
            _selectedFrequency == _Frequency.monthly ? 'monthly' : 'weekly',
        amount: amount,
      );
      setState(() {
        _expenses.add(_Expense(
          expenseId: result['expenseId'] as String,
          name: name,
          frequency: _selectedFrequency,
          amount: amount,
        ));
        _nameController.clear();
        _amountController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _removeExpense(int index) async {
    final expense = _expenses[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${expense.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteFixedExpense(expenseId: expense.expenseId);
      setState(() => _expenses.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              const Text(
                'Set Your Monthly Expenses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add the costs you pay regularly.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              _buildEstimatedCard(),
              const SizedBox(height: 24),
              const Text(
                'Add Custom Expense',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildNameField(),
              const SizedBox(height: 10),
              _buildAmountRow(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _buildAddButton(),
              ),
              const SizedBox(height: 24),
              _buildExpenseList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const Text(
          'Business Insights',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEEAB8),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedCard() {
    final amount = _estimatedMonthly;
    final intPart = amount.toInt();
    final decPart =
        ((amount - intPart) * 100).toInt().toString().padLeft(2, '0');
    final formatted = 'R${_formatNumber(intPart)}.$decPart';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Monthly',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Name (e.g. Wi-Fi)',
          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_TwoDecimalInputFormatter()],
              decoration: const InputDecoration(
                hintText: 'Amount (R)',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildFrequencyToggle(),
      ],
    );
  }

  Widget _buildFrequencyToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption('monthly', _Frequency.monthly),
          _toggleOption('weekly', _Frequency.weekly),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, _Frequency freq) {
    final selected = _selectedFrequency == freq;
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = freq),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _saving ? null : _addExpense,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _saving
              ? AppColors.secondary.withValues(alpha: 0.6)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return Column(
      children: List.generate(_expenses.length, (index) {
        final expense = _expenses[index];
        final freqLabel =
            expense.frequency == _Frequency.monthly ? 'monthly' : 'weekly';
        final amountStr = 'R${_formatNumber(expense.amount.toInt())}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  size: 24, color: Colors.black54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      freqLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amountStr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _removeExpense(index),
                child: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TwoDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Allow only digits and a single decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    // Allow at most two digits after the decimal point
    final dotIndex = text.indexOf('.');
    if (dotIndex != -1 && text.length - dotIndex - 1 > 2) return oldValue;

    return newValue;
  }
}
