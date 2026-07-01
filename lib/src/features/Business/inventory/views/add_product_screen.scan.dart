part of 'add_product_screen.dart';

/// Barcode and invoice scanning flows for [AddProductScreen].
mixin _AddProductScanMixin on State<AddProductScreen>, _AddProductFormMixin {
  Future<void> _showScanOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return ScanTypeBottomSheet(
          onScanBarcode: () {
            Navigator.of(context).pop();
            _handleBarcodeScan();
          },
          onScanInvoice: () {
            Navigator.of(context).pop();
            _handleInvoiceScan();
          },
        );
      },
    );
  }

  Future<void> _handleBarcodeScan() async {
    final barcode = await context.push<String>(AppRoutes.barcodeScanner);
    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    try {
      final response = await _apiService.lookupProductByBarcode(barcode.trim());
      final product = response['product'];

      if (response['found'] == true && product is Map<String, dynamic>) {
        _applyProductPrefill(product);
        _showError('Product found. Review details before saving.');
      } else {
        if (!mounted) return;
        final addNew = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Product not found'),
            content: const Text('Product not found. Add as new product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add New'),
              ),
            ],
          ),
        );

        if (addNew == true && mounted) {
          setState(() {
            _selectedProductId = null;
            _productNameLockedBySelection = false;
            _selectedCategory = null;
            _hasScannedBarcode = true;
            _barcodeController.text = barcode.trim();
            _productNameController.clear();
            _categoryController.clear();
            _costPriceController.clear();
            _sellingPriceController.clear();
            _quantityController.clear();
            _alertQuantityController.clear();
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    }
  }

  Future<void> _handleInvoiceScan() async {
    InvoiceImageSource? source;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return InvoiceSourceBottomSheet(
          onSelect: (choice) {
            source = choice == InvoiceSourceChoice.camera
                ? InvoiceImageSource.camera
                : InvoiceImageSource.file;
            Navigator.of(context).pop();
          },
        );
      },
    );

    if (source == null) {
      return;
    }

    setState(() {
      _isSavingProduct = true;
      _isProcessingInvoice = true;
    });

    try {
      final filePath = await _invoiceScanService.pickInvoiceFilePath(source: source!);
      if (filePath == null) {
        return;
      }

      final recognizedText = await _invoiceScanService.recognizeFromFilePath(
        filePath,
      );

      debugPrint('=== RAW OCR TEXT ===');
      debugPrint(recognizedText.text);
      debugPrint('====================');

      final parser = InvoiceOcrParser();
      final parsed = parser.parseRecognizedText(recognizedText);

      debugPrint('=== PARSED PRODUCTS (${parsed.products.length}) ===');
      for (var i = 0; i < parsed.products.length; i++) {
        final p = parsed.products[i];
        debugPrint(
          '[${i + 1}] name="${p.name}"  qty=${p.quantity}  costPrice=${p.costPrice.toStringAsFixed(2)}  confidence=${p.confidence.toStringAsFixed(2)}',
        );
      }
      debugPrint('====================================================');

      if (parsed.products.isEmpty) {
        _showError('No readable invoice items were found. Please retry scanning.');
        return;
      }

      final response = await _apiService.matchScannedProducts(
        products: parsed.products
            .map((p) => p.toJson())
            .toList(),
      );

      final rawProducts = response['products'];
      final matchedProducts = rawProducts is List
          ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(ScannedProduct.fromJson)
              .toList()
          : <ScannedProduct>[];

      if (matchedProducts.isEmpty) {
        _showError('No readable invoice items were found. Please retry scanning.');
        return;
      }

      if (!mounted) return;
      await context.push(
        AppRoutes.reviewScannedProducts,
        extra: ReviewScannedProductsArgs(
          products: matchedProducts,
          rawOcrText: recognizedText.text,
          supplierName: parsed.supplierName,
          invoiceNumber: parsed.invoiceNumber,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProduct = false;
          _isProcessingInvoice = false;
        });
      }
    }
  }
}
