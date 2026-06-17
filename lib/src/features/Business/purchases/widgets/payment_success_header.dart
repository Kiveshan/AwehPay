import 'package:flutter/material.dart';

class PaymentSuccessHeader extends StatelessWidget {
  const PaymentSuccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF4CAF50),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Payment confirmed',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

