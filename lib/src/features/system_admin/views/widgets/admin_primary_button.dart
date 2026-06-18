import 'package:flutter/material.dart';

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFEEAB8),
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );
  }
}
