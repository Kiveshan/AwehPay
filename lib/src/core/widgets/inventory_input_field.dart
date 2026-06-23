import 'package:flutter/material.dart';

class InventoryInputField extends StatelessWidget {
  const InventoryInputField({
    super.key,
    required this.label,
    required this.controller,
    this.labelColor,
    this.borderColor,
    this.textColor,
    this.trailingText,
    this.keyboardType,
    this.spinnerColor,
    this.onIncrement,
    this.onDecrement,
    this.prefixText,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final Color? labelColor;
  final Color? borderColor;
  final Color? textColor;
  final String? trailingText;
  final TextInputType? keyboardType;
  final Color? spinnerColor;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String? prefixText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? const Color(0xFF272A2F),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? const Color(0xFFC9CED6),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefixText != null) ...[
                const SizedBox(width: 12),
                Text(
                  prefixText!,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 16,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: textColor ?? const Color(0xFF272A2F),
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              if (onIncrement != null || onDecrement != null) ...[
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onIncrement,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: spinnerColor ?? const Color(0xFF272A2F),
                        size: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDecrement,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: spinnerColor ?? const Color(0xFF272A2F),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
