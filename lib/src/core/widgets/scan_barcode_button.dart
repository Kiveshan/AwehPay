import 'package:flutter/material.dart';

class ScanBarcodeButton extends StatelessWidget {
  const ScanBarcodeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFDFA890),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 14,
            ),
            SizedBox(width: 8),
            Text(
              'Scan Barcode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
