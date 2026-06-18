import 'package:flutter/material.dart';

import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import 'purchases_screen.dart';
import 'widgets/summary_row.dart';

class QRPaymentRejectedScreen extends StatelessWidget {
  const QRPaymentRejectedScreen({
    super.key,
    required this.items,
    required this.totalAmount,
    this.onRetry,
    this.onChangeMethod,
  });

  final List<PurchaseItem> items;
  final double totalAmount;
  final VoidCallback? onRetry;
  final VoidCallback? onChangeMethod;

  double get _tax => totalAmount * 0.10;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchases',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE57373),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Payment Rejected',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...items.map((item) {
                    final unitPrice = double.tryParse(
                          item.price.replaceAll('R', '').replaceAll(',', ''),
                        ) ??
                        0.0;
                    final lineTotal = unitPrice * item.quantity;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.name} x${item.quantity}',
                                  style: const TextStyle(
                                    color: Color(0xFF272A2F),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.barcode.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.barcode,
                                    style: const TextStyle(
                                      color: Color(0xFF9B9B9B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'R${lineTotal % 1 == 0 ? lineTotal.toInt() : lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF272A2F),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  _buildSummaryBox(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: AdminPrimaryButton(
                    label: 'Retry',
                    icon: Icons.refresh,
                    onPressed: onRetry ?? () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminPrimaryButton(
                    label: 'Change Method',
                    icon: Icons.swap_horiz,
                    onPressed: onChangeMethod ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SummaryRow(
            label: 'Subtotal',
            value: 'R${totalAmount.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: 'Tax (10%)',
            value: 'R${_tax.toStringAsFixed(2)}',
            bold: true,
          ),
          const Divider(height: 24, color: Color(0xFFE0E0E0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Rejected',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'R${totalAmount.toInt()}',
                    style: const TextStyle(
                      color: Color(0xFFE57373),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

