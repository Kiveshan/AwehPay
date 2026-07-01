import 'package:flutter/material.dart';

import 'editable_scanned_product.dart';

class ScannedProductCard extends StatelessWidget {
  const ScannedProductCard({
    super.key,
    required this.product,
    required this.onRemove,
  });

  final EditableScannedProduct product;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF5C9B7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.original.isExistingProduct ? 'Existing product' : 'New product',
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF272A2F)),
              ),
            ],
          ),
          _TextInput(label: 'Product name', controller: product.nameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TextInput(label: 'Quantity', controller: product.quantityController, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _TextInput(label: 'Cost price', controller: product.costPriceController, keyboardType: TextInputType.number, prefixText: 'R')),
            ],
          ),
          const SizedBox(height: 12),
          _TextInput(label: 'Category', controller: product.categoryController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TextInput(label: 'Selling price', controller: product.sellingPriceController, keyboardType: TextInputType.number, prefixText: 'R')),
              const SizedBox(width: 12),
              Expanded(child: _TextInput(label: 'Low stock', controller: product.lowStockThresholdController, keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9CED6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefixText != null) ...[
                const SizedBox(width: 10),
                Text(prefixText!, style: const TextStyle(color: Color(0xFF272A2F), fontWeight: FontWeight.w600)),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
