import 'package:flutter/material.dart';

import '../../models/scanned_product.dart';

class EditableScannedProduct {
  EditableScannedProduct(ScannedProduct product)
      : original = product,
        userConfirmedExisting = null,
        nameController = TextEditingController(text: product.name),
        quantityController = TextEditingController(text: '${product.quantity}'),
        costPriceController = TextEditingController(text: product.costPrice.toStringAsFixed(2)),
        categoryController = TextEditingController(text: ''),
        sellingPriceController = TextEditingController(
          text: product.sellingPrice == null ? '' : product.sellingPrice!.toStringAsFixed(2),
        ),
        lowStockThresholdController = TextEditingController(
          text: product.lowStockThreshold == null ? '' : '${product.lowStockThreshold}',
        ),
        vatEnabled = ValueNotifier<bool>(product.vat) {
    // Initialize totalCost from OCR line total if available, otherwise qty × costPrice.
    final initialTotal = product.totalCost > 0
        ? product.totalCost
        : product.costPrice * product.quantity;
    totalCostController = TextEditingController(
      text: initialTotal > 0 ? initialTotal.toStringAsFixed(2) : '',
    );
    costPriceController.addListener(_updateTotalCost);
    quantityController.addListener(_updateTotalCost);
    vatEnabled.addListener(_updateTotalCost);
  }

  final ScannedProduct original;

  /// null  = undecided (only shown when original.isExistingProduct == true)
  /// true  = user confirmed it is the existing product → UPDATE, add qty
  /// false = user said it is a new product → ADD
  bool? userConfirmedExisting;

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController costPriceController;
  final TextEditingController categoryController;
  final TextEditingController sellingPriceController;
  final TextEditingController lowStockThresholdController;
  late final TextEditingController totalCostController;
  final ValueNotifier<bool> vatEnabled;

  int get existingStock =>
      (original.existingProduct?['stockQuantity'] as num?)?.toInt() ?? 0;

  void _updateTotalCost() {
    final cp = double.tryParse(
          costPriceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    var total = cp * qty;
    if (vatEnabled.value) total *= 1.15;
    final newText = total > 0 ? total.toStringAsFixed(2) : '';
    if (totalCostController.text != newText) {
      totalCostController.text = newText;
    }
  }

  ScannedProduct toScannedProduct() {
    final enteredQty = int.tryParse(quantityController.text.trim()) ?? 0;
    final costPrice = double.tryParse(
          costPriceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
    final totalCost = double.tryParse(
          totalCostController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final sellingPrice = double.tryParse(
      sellingPriceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final lowStock = int.tryParse(lowStockThresholdController.text.trim());
    final category = categoryController.text.trim();

    // User said it's a new product — strip all existing-product linkage.
    if (userConfirmedExisting == false) {
      return ScannedProduct(
        name: nameController.text.trim(),
        quantity: enteredQty,
        costPrice: costPrice,
        totalCost: totalCost,
        vat: vatEnabled.value,
        category: category,
        barcode: original.barcode,
        sellingPrice: sellingPrice,
        lowStockThreshold: lowStock,
        unit: original.unit,
        confidence: original.confidence,
        isExistingProduct: false,
        matchedProductId: null,
        existingProduct: null,
      );
    }

    // User confirmed existing product — add entered qty on top of current stock.
    final effectiveQty =
        userConfirmedExisting == true ? existingStock + enteredQty : enteredQty;

    return original.copyWith(
      name: nameController.text.trim(),
      quantity: effectiveQty,
      costPrice: costPrice,
      totalCost: totalCost,
      vat: vatEnabled.value,
      category: category,
      sellingPrice: sellingPrice,
      lowStockThreshold: lowStock,
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    costPriceController.dispose();
    categoryController.dispose();
    sellingPriceController.dispose();
    lowStockThresholdController.dispose();
    totalCostController.dispose();
    vatEnabled.dispose();
  }
}
