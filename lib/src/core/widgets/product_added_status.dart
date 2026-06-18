import 'package:flutter/material.dart';

class ProductAddedStatus extends StatelessWidget {
  const ProductAddedStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFA8E6B0),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Product Added',
          style: TextStyle(
            color: Color(0xFFA8E6B0),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
