import 'package:flutter/material.dart';

import 'scan_option_tile.dart';

class ScanTypeBottomSheet extends StatelessWidget {
  const ScanTypeBottomSheet({
    super.key,
    required this.onScanBarcode,
    required this.onScanInvoice,
  });

  final VoidCallback onScanBarcode;
  final VoidCallback onScanInvoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Scan Type',
            style: TextStyle(
              color: Color(0xFF272A2F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ScanOptionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Barcode',
            subtitle: 'Best for adding or finding one product',
            onTap: onScanBarcode,
          ),
          const SizedBox(height: 12),
          ScanOptionTile(
            icon: Icons.receipt_long_rounded,
            title: 'Scan Invoice',
            subtitle: 'Best for adding multiple products from an invoice',
            onTap: onScanInvoice,
          ),
        ],
      ),
    );
  }
}
