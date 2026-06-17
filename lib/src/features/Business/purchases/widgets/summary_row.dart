import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    super.key,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF272A2F),
            fontSize: 16,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

