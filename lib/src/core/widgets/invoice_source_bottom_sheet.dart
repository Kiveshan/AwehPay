import 'package:flutter/material.dart';

import 'scan_option_tile.dart';

enum InvoiceSourceChoice { camera, gallery }

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
            icon: Icons.photo_library_rounded,
            title: 'Select Invoice Image',
            subtitle: 'Choose an existing image',
            onTap: () => onSelect(InvoiceSourceChoice.gallery),
          ),
        ],
      ),
    );
  }
}
