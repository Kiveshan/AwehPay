import 'package:flutter/material.dart';

class AdminTextField extends StatelessWidget {
  const AdminTextField({
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.maxLines = 1,
    this.isDense = false,
    this.suffixIcon,
    this.keyboardType,
    this.readOnly = false,
    this.alignLabelAbove = false,
    this.errorText,
    super.key,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final int maxLines;
  final bool isDense;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool alignLabelAbove;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: alignLabelAbove ? null : label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        errorText: errorText,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(color: Colors.grey.shade400),
                child: suffixIcon!,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8A28D)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDense ? 8 : 16,
          vertical: isDense ? 8 : 16,
        ),
      ),
    );

    if (!alignLabelAbove) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }
}
