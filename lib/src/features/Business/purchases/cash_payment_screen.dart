import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';
import 'payment_confirmed_screen.dart';
import 'purchases_screen.dart';
import 'widgets/purple_button.dart';
import 'widgets/quick_amount_chip.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  final List<PurchaseItem> items;
  final double totalAmount;

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  double _collectedAmount = 0;
  bool _isSubmitting = false;
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ApiService _apiService = ApiService();

  double get _changeDue => (_collectedAmount - widget.totalAmount).clamp(0, double.infinity);
  bool get _isExactOrOver => _collectedAmount >= widget.totalAmount;

  List<double> get _quickAmounts {
    final amount = widget.totalAmount;
    if (amount < 1) return [];
    if (amount <= 10) return [1, 2, 5];
    if (amount <= 20) return [5, 10, 20];
    if (amount <= 50) return [10, 20, 50];
    if (amount <= 100) return [20, 50, 100];
    if (amount <= 200) return [50, 100, 200];
    return [100, 200];
  }

  @override
  void initState() {
    super.initState();
    _collectedAmount = widget.totalAmount;
    _amountController.text = '${widget.totalAmount.toInt()}';
    // Add listener after text is set so initial value doesn't reset _collectedAmount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountController.addListener(_onAmountChanged);
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _cellController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _collectedAmount = double.tryParse(_amountController.text) ?? 0;
    });
  }

  void _selectQuickAmount(double amount) {
    _amountController.removeListener(_onAmountChanged);
    setState(() {
      _collectedAmount += amount;
      _amountController.text = '${_collectedAmount.toInt()}';
    });
    _amountController.addListener(_onAmountChanged);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final items = widget.items.map((item) {
        final unitPrice = double.tryParse(
              item.price.replaceAll('R', '').replaceAll(',', ''),
            ) ??
            0.0;
        return {
          'itemId': item.itemId,
          'name': item.name,
          'type': item.type,
          'quantity': 1,
          'unitPrice': unitPrice,
        };
      }).toList();

      await _apiService.createCashTransaction(
        items: items,
        amountSubtotal: widget.totalAmount,
        amountTotal: widget.totalAmount,
        amountCollected: _collectedAmount,
        customerPhone: _cellController.text.trim().isEmpty
            ? null
            : _cellController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentConfirmedScreen(
            items: widget.items,
            totalAmount: widget.totalAmount,
            collectedAmount: _collectedAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFE55353),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchases',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Service / Product',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Color(0xFF272A2F),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.barcode,
                              style: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.price,
                        style: const TextStyle(
                          color: Color(0xFF272A2F),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'Amount to be paid:',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R${widget.totalAmount.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Amount collected:',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD0CEFF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixText: 'R ',
                  prefixStyle: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey.shade500),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ),
            if (_quickAmounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: _quickAmounts
                    .map((amount) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: QuickAmountChip(
                            label: 'R${amount.toInt()}',
                            selected: false,
                            onTap: () => _selectQuickAmount(amount),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Change due:',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: _isExactOrOver ? const Color(0xFFE6F9F5) : const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R${_changeDue.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _isExactOrOver ? const Color(0xFF00B09B) : const Color(0xFFE55353),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isExactOrOver)
                    Text(
                      'Short by R${(widget.totalAmount - _collectedAmount).toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFE55353), fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AdminTextField(
              label: 'Customer Cell Number (for receipt)',
              hintText: '0734059910',
              controller: _cellController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 28),
            PurpleButton(
              label: _isSubmitting ? 'Processing...' : 'Mark as Paid',
              icon: Icons.check,
              onPressed: _isExactOrOver && !_isSubmitting ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
