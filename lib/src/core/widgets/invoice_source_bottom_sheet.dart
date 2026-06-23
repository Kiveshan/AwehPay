import 'package:flutter/material.dart';

import 'scan_option_tile.dart';

enum InvoiceSourceChoice { camera, file }

class InvoiceSourceBottomSheet extends StatelessWidget {
  const InvoiceSourceBottomSheet({
    super.key,
    required this.onSelect,
  });

  final ValueChanged<InvoiceSourceChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScanOptionTile(
            icon: Icons.camera_alt_rounded,
            title: 'Capture Invoice',
            subtitle: 'Take a photo using the camera',
            onTap: () => onSelect(InvoiceSourceChoice.camera),
          ),
          const SizedBox(height: 12),
          ScanOptionTile(
            icon: Icons.upload_file_rounded,
            title: 'Upload Document',
            subtitle: 'Select a PDF or image from your device',
            onTap: () => onSelect(InvoiceSourceChoice.file),
          ),
        ],
      ),
    );
  }
}
