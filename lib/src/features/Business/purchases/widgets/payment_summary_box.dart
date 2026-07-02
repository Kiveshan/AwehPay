import 'package:flutter/material.dart';

import 'summary_row.dart';

class PaymentSummaryBox extends StatelessWidget {
  const PaymentSummaryBox({
    required this.changeDue,
    required this.subtotal,
    required this.tax,
    super.key,
  });

  final double changeDue;
  final double subtotal;
  final double tax;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SummaryRow(
            label: 'Change Due',
            value: 'R${changeDue.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: 'Subtotal',
            value: 'R${subtotal.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: 'Tax (15%)',
            value: 'R${tax.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

