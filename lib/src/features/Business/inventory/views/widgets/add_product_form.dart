import 'package:flutter/material.dart';

import '../../../../../core/widgets/editable_option_field.dart';
import '../../../../../core/widgets/inventory_input_field.dart';
import '../../../../../core/widgets/product_added_status.dart';
import '../../../../../core/widgets/save_button.dart';

class AddProductForm extends StatelessWidget {
  const AddProductForm({
    super.key,
    required this.isProductAdded,
    required this.isSavingProduct,
    required this.hasScannedBarcode,
    required this.lockedProductName,
    required this.lockedCategory,
    required this.productOptions,
    required this.categoryOptions,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.productNameController,
    required this.categoryController,
    required this.barcodeController,
    required this.costPriceController,
    required this.sellingPriceController,
    required this.quantityController,
    required this.alertQuantityController,
    required this.onProductOptionSelected,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
    required this.onIncrementAlertQuantity,
    required this.onDecrementAlertQuantity,
    required this.onSave,
  });

  final bool isProductAdded;
  final bool isSavingProduct;
  final bool hasScannedBarcode;
  final String? lockedProductName;
  final String? lockedCategory;

  final List<String> productOptions;
  final List<String> categoryOptions;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  final TextEditingController productNameController;
  final TextEditingController categoryController;
  final TextEditingController barcodeController;
  final TextEditingController costPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController quantityController;
  final TextEditingController alertQuantityController;

  final ValueChanged<String> onProductOptionSelected;
  final VoidCallback? onIncrementQuantity;
  final VoidCallback? onDecrementQuantity;
  final VoidCallback? onIncrementAlertQuantity;
  final VoidCallback? onDecrementAlertQuantity;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFF5C9B7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isProductAdded) ...[
            Center(child: const ProductAddedStatus()),
            const SizedBox(height: 24),
          ],
          EditableOptionField(
            label: 'Product Name',
            controller: productNameController,
            options: productOptions,
            prefixIcon: Icons.search_rounded,
            readOnly: isProductAdded || lockedProductName != null,
            onOptionSelected: onProductOptionSelected,
          ),
          if (hasScannedBarcode) ...[
            const SizedBox(height: 18),
            InventoryInputField(
              label: 'Product Barcode',
              controller: barcodeController,
              readOnly: isProductAdded,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InventoryInputField(
                  label: 'Cost Price',
                  controller: costPriceController,
                  keyboardType: TextInputType.number,
                  prefixText: 'R',
                  readOnly: isProductAdded,
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: InventoryInputField(
                  label: 'Selling Price',
                  controller: sellingPriceController,
                  keyboardType: TextInputType.number,
                  prefixText: 'R',
                  readOnly: isProductAdded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InventoryInputField(
                  label: 'Quantity',
                  labelColor: null,
                  borderColor: null,
                  textColor: null,
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  spinnerColor: const Color(0xFFF5C9B7),
                  readOnly: isProductAdded,
                  onIncrement: isProductAdded ? null : onIncrementQuantity,
                  onDecrement: isProductAdded ? null : onDecrementQuantity,
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: _CategoryDropdown(
                  value: selectedCategory,
                  options: categoryOptions,
                  enabled: !isProductAdded && lockedCategory == null,
                  onChanged: onCategoryChanged,
                ),
              ),
            ],
          ),
          if (selectedCategory == 'Other') ...[
            const SizedBox(height: 18),
            InventoryInputField(
              label: 'Other Product Category',
              controller: categoryController,
              readOnly: isProductAdded,
            ),
          ],
          const SizedBox(height: 18),
          InventoryInputField(
            label: 'Alert me when stock reaches below',
            controller: alertQuantityController,
            keyboardType: TextInputType.number,
            trailingText: 'Units',
            spinnerColor: const Color(0xFFF5C9B7),
            readOnly: isProductAdded,
            onIncrement: isProductAdded ? null : onIncrementAlertQuantity,
            onDecrement: isProductAdded ? null : onDecrementAlertQuantity,
          ),
          if (!isProductAdded) ...[
            const SizedBox(height: 24),
            SaveButton(
              label: 'Add Product',
              icon: Icons.add_rounded,
              onTap: isSavingProduct ? null : onSave,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && options.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Category',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9CED6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF272A2F),
              ),
              style: const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
              hint: const Text(
                'Select a category',
                style: TextStyle(color: Color(0xFF4A4E57), fontSize: 13),
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
