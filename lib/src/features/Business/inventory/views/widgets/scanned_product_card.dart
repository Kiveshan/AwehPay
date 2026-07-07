import 'package:flutter/material.dart';

import 'editable_scanned_product.dart';

class ScannedProductCard extends StatelessWidget {
  const ScannedProductCard({
    super.key,
    required this.product,
    required this.onRemove,
    required this.onDecisionMade,
  });

  final EditableScannedProduct product;
  final VoidCallback onRemove;
  final ValueChanged<bool> onDecisionMade;

  @override
  Widget build(BuildContext context) {
    final isMatched = product.original.isExistingProduct;
    final decision = product.userConfirmedExisting;
    final existingName =
        (product.original.existingProduct?['name'] as String?) ??
            product.original.name;
    final existingStock = product.existingStock;

    String headerLabel;
    if (!isMatched) {
      headerLabel = 'New product';
    } else if (decision == null) {
      headerLabel = 'Matched product';
    } else if (decision) {
      headerLabel = 'Updating existing';
    } else {
      headerLabel = 'New product';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDFA890)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  headerLabel,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isMatched && decision != null)
                GestureDetector(
                  onTap: () => onDecisionMade(!decision),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: Color(0xFFDFA890),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF272A2F),
                ),
              ),
            ],
          ),

          // Match confirmation banner — shown when undecided
          if (isMatched && decision == null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F5),
                border: Border.all(color: const Color(0xFFDFA890)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matched to: "$existingName"  ·  Current stock: $existingStock',
                    style: const TextStyle(
                      color: Color(0xFF272A2F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Is this the same product?',
                    style: TextStyle(color: Color(0xFF4A4E57), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _DecisionButton(
                        label: 'Yes, update it',
                        color: const Color(0xFFDFA890),
                        onTap: () => onDecisionMade(true),
                      ),
                      const SizedBox(width: 8),
                      _DecisionButton(
                        label: 'No, add as new',
                        color: const Color(0xFFC9CED6),
                        onTap: () => onDecisionMade(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stock info banner — shown after confirming as existing
          if (isMatched && decision == true) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFFDFA890),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Current stock: $existingStock',
                    style: const TextStyle(
                      color: Color(0xFF4A4E57),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Form fields
          _TextInput(
            label: 'Product name',
            controller: product.nameController,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TextInput(
                      label: (isMatched && decision == true)
                          ? 'Quantity to Add'
                          : 'Quantity',
                      controller: product.quantityController,
                      keyboardType: TextInputType.number,
                    ),
                    if (isMatched && decision == true) ...[
                      const SizedBox(height: 4),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: product.quantityController,
                        builder: (context, value, _) {
                          final entered =
                              int.tryParse(value.text.trim()) ?? 0;
                          final newTotal = existingStock + entered;
                          return Text(
                            'New total: $newTotal',
                            style: const TextStyle(
                              color: Color(0xFFDFA890),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TextInput(
                  label: 'Cost price',
                  controller: product.costPriceController,
                  keyboardType: TextInputType.number,
                  prefixText: 'R',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TextInput(
            label: 'Category',
            controller: product.categoryController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextInput(
                  label: 'Selling price',
                  controller: product.sellingPriceController,
                  keyboardType: TextInputType.number,
                  prefixText: 'R',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TextInput(
                  label: 'Low stock',
                  controller: product.lowStockThresholdController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextInput(
                  label: 'Total Cost',
                  controller: product.totalCostController,
                  keyboardType: TextInputType.number,
                  prefixText: 'R',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VatCheckbox(vatNotifier: product.vatEnabled),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VatCheckbox extends StatelessWidget {
  const _VatCheckbox({required this.vatNotifier});

  final ValueNotifier<bool> vatNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: vatNotifier,
      builder: (context, vatEnabled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VAT',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Checkbox(
                  value: vatEnabled,
                  onChanged: (v) => vatNotifier.value = v ?? false,
                  activeColor: const Color(0xFFDFA890),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  vatEnabled ? 'VAT Included' : 'No VAT',
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                Text(
                  prefixText!,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10),
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
