import 'package:flutter/material.dart';

import '../../models/scanned_product.dart';

class EditableScannedProduct {
  EditableScannedProduct(ScannedProduct product)
      : original = product,
        nameController = TextEditingController(text: product.name),
        quantityController = TextEditingController(text: '${product.quantity}'),
        costPriceController = TextEditingController(text: product.costPrice.toStringAsFixed(2)),
        categoryController = TextEditingController(text: product.category),
        sellingPriceController = TextEditingController(
          text: product.sellingPrice == null ? '' : product.sellingPrice!.toStringAsFixed(2),
        ),
        lowStockThresholdController = TextEditingController(
          text: product.lowStockThreshold == null ? '' : '${product.lowStockThreshold}',
        );

  final ScannedProduct original;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController costPriceController;
  final TextEditingController categoryController;
  final TextEditingController sellingPriceController;
  final TextEditingController lowStockThresholdController;

  ScannedProduct toScannedProduct() {
    return original.copyWith(
      name: nameController.text.trim(),
      quantity: int.tryParse(quantityController.text.trim()) ?? 0,
      costPrice: double.tryParse(costPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      category: categoryController.text.trim().isEmpty ? 'Other' : categoryController.text.trim(),
      sellingPrice: double.tryParse(sellingPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
      lowStockThreshold: int.tryParse(lowStockThresholdController.text.trim()),
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    costPriceController.dispose();
    categoryController.dispose();
    sellingPriceController.dispose();
    lowStockThresholdController.dispose();
  }
}
