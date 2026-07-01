import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:awe_pay/src/core/router/app_routes.dart';
import 'package:awe_pay/src/features/Business/Inventory/models/scanned_product.dart';
import 'package:awe_pay/src/features/Business/Inventory/views/review_scanned_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/add_product_header.dart';
import '../../../../core/widgets/scan_barcode_button.dart';
import '../../../../core/widgets/scan_type_bottom_sheet.dart';
import '../../../../core/widgets/invoice_source_bottom_sheet.dart';

import '../services/invoice_ocr_parser.dart';
import '../inventory_timestamp.dart';
import '../services/invoice_scan_service.dart';
import 'widgets/add_product_form.dart';
import 'widgets/processing_invoice_overlay.dart';

part 'add_product_screen.form.dart';
part 'add_product_screen.scan.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.isReplenishStock = false,
    this.lockedProductId,
    this.lockedProductName,
    this.lockedCategory,
    this.prefillBarcode,
    this.prefillCostPrice,
    this.prefillSellingPrice,
    this.prefillStockQuantity,
    this.prefillLowStockThreshold,
  });

  final bool isReplenishStock;
  final String? lockedProductId;
  final String? lockedProductName;
  final String? lockedCategory;
  final String? prefillBarcode;
  final double? prefillCostPrice;
  final double? prefillSellingPrice;
  final int? prefillStockQuantity;
  final int? prefillLowStockThreshold;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with _AddProductFormMixin, _AddProductScanMixin {
  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.lockedProductName ?? '',
    );
    _categoryController = TextEditingController();
    if (widget.lockedCategory != null && widget.lockedCategory!.isNotEmpty) {
      _selectedCategory = widget.lockedCategory;
    }
    final hasPrefillBarcode =
        widget.prefillBarcode != null && widget.prefillBarcode!.isNotEmpty;
    _barcodeController = TextEditingController(
      text: hasPrefillBarcode ? widget.prefillBarcode : '',
    );
    _costPriceController = TextEditingController(
      text: widget.prefillCostPrice != null
          ? widget.prefillCostPrice!.toStringAsFixed(2)
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.prefillSellingPrice != null
          ? widget.prefillSellingPrice!.toStringAsFixed(2)
          : '',
    );
    _quantityController = TextEditingController(
      // In replenish mode the field represents the quantity being ADDED, so it
      // starts empty; the existing stock is added to it on save.
      text: (!widget.isReplenishStock && widget.prefillStockQuantity != null)
          ? '${widget.prefillStockQuantity}'
          : '',
    );
    _alertQuantityController = TextEditingController(
      text: widget.prefillLowStockThreshold != null
          ? '${widget.prefillLowStockThreshold}'
          : '',
    );
    if (hasPrefillBarcode) {
      _hasScannedBarcode = true;
    }
    _selectedProductId = widget.lockedProductId;
    _productNameController.addListener(() {
      if (_productNameLockedBySelection) {
        final currentText = _productNameController.text;
        final stillMatches = _productDataByName.containsKey(currentText);
        if (!stillMatches) {
          setState(() {
            _productNameLockedBySelection = false;
            _selectedProductId = null;
            _selectedCategory = null;
            _categoryController.clear();
            _costPriceController.clear();
            _sellingPriceController.clear();
            _quantityController.clear();
            _alertQuantityController.clear();
          });
        }
      }
    });
    _quantityController.addListener(() {
      if (widget.isReplenishStock && !_quantityModified) {
        final original = widget.prefillStockQuantity != null
            ? '${widget.prefillStockQuantity}'
            : '';
        if (_quantityController.text != original) {
          setState(() {
            _quantityModified = true;
          });
        }
      }
    });
    _loadProductOptions();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _alertQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AddProductHeader(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isProductAdded) ...[
                            Center(
                              child: ScanBarcodeButton(
                                onTap: _showScanOptions,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          AddProductForm(
                            isProductAdded: _isProductAdded,
                            isSavingProduct: _isSavingProduct,
                            hasScannedBarcode: _hasScannedBarcode,
                            lockedProductName: widget.lockedProductName,
                            lockedCategory: widget.lockedCategory,
                            productOptions: _productOptions,
                            categoryOptions: _categoryOptions,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                if (value != 'Other') {
                                  _categoryController.clear();
                                }
                              });
                            },
                            productNameController: _productNameController,
                            categoryController: _categoryController,
                            barcodeController: _barcodeController,
                            costPriceController: _costPriceController,
                            sellingPriceController: _sellingPriceController,
                            quantityController: _quantityController,
                            alertQuantityController: _alertQuantityController,
                            onProductOptionSelected: (name) {
                              final data = _productDataByName[name];
                              if (data != null) {
                                _fillFromProductMap(data, lockSelection: true);
                              } else {
                                setState(() {
                                  _selectedProductId = null;
                                  _productNameLockedBySelection = false;
                                });
                              }
                            },
                            onIncrementQuantity: () =>
                                _changeIntField(_quantityController, 1),
                            onDecrementQuantity: () =>
                                _changeIntField(_quantityController, -1),
                            onIncrementAlertQuantity: () =>
                                _changeIntField(_alertQuantityController, 1),
                            onDecrementAlertQuantity: () =>
                                _changeIntField(_alertQuantityController, -1),
                            onSave: _saveProduct,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessingInvoice)
            Container(
              color: Colors.white,
              child: const Center(
                child: ProcessingInvoiceOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}
