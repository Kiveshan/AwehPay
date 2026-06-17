import 'package:flutter/material.dart';

import 'summary_row.dart';

class PaymentSummaryBox extends StatelessWidget {
  const PaymentSummaryBox({
    required this.changeDue,
    required this.subtotal,
    required this.tax,
    required this.total,
    super.key,
  });

  final double changeDue;
  final double subtotal;
  final double tax;
  final double total;

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
          const SizedBox(height: 12),
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
                  const Text(
                    'Success',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'R${total.toInt()}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 16,
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

