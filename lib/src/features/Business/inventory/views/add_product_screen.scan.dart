part of 'add_product_screen.dart';

/// Barcode and invoice scanning flows for [AddProductScreen].
mixin _AddProductScanMixin on State<AddProductScreen>, _AddProductFormMixin {
  // Shows a dialog asking whether the user wants to scan a barcode or an invoice.
  Future<void> _showScanOptions() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: ScanTypeBottomSheet(
            onScanBarcode: () {
              Navigator.of(context).pop();
              _handleBarcodeScan();
            },
            onScanInvoice: () {
              Navigator.of(context).pop();
              _handleInvoiceScan();
            },
          ),
        );
      },
    );
  }

  // Navigates to BarcodeScannerScreen and waits for it to return a barcode string.
  // Once returned, looks up the barcode in the backend:
  //   - Found → pre-fills the form with the existing product data.
  //   - Not found → asks the user if they want to add it as a new product.
  Future<void> _handleBarcodeScan() async {
    final barcode = await context.push<String>(AppRoutes.barcodeScanner);
    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    try {
      final response = await _apiService.lookupProductByBarcode(barcode.trim());
      final product = response['product'];

      if (response['found'] == true && product is Map<String, dynamic>) {
        // Product already exists — fill the form so the user can review and update it.
        _applyProductPrefill(product);
        _showError('Product found. Review details before saving.');
      } else {
        if (!mounted) return;
        // No match in inventory — ask if they want to create a new product.
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
          // Clear the form and pre-fill only the barcode field.
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

  // Full invoice scan flow: pick image → OCR → parse → match against inventory → review.
  Future<void> _handleInvoiceScan() async {
    // Step 1: ask the user whether to use the camera or pick a file.
    InvoiceImageSource? source;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: InvoiceSourceBottomSheet(
            onSelect: (choice) {
              source = choice == InvoiceSourceChoice.camera
                  ? InvoiceImageSource.camera
                  : InvoiceImageSource.file;
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );

    if (source == null) {
      return; // User cancelled the dialog.
    }

    // Show a loading overlay while OCR and parsing run.
    setState(() {
      _isSavingProduct = true;
      _isProcessingInvoice = true;
    });

    try {
      // Step 2: open camera or file picker and get the local file path.
      final filePath = await _invoiceScanService.pickInvoiceFilePath(source: source!);
      if (filePath == null) {
        return; // User cancelled the picker.
      }

      // Step 3: run ML Kit OCR on the file (handles rotation, PDFs, etc.).
      final recognizedText = await _invoiceScanService.recognizeFromFilePath(
        filePath,
      );

      debugPrint('=== RAW OCR TEXT ===');
      debugPrint(recognizedText.text);
      debugPrint('====================');

      // Step 4: parse the OCR result into structured product data.
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

      // Step 5: send parsed products to the backend which fuzzy-matches each
      // name against the business's existing inventory.
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

      // Step 6: navigate to the review screen where the user can confirm or edit
      // each matched product before it is saved to inventory.
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
      // Always hide the loading overlay, even if an error occurred.
      if (mounted) {
        setState(() {
          _isSavingProduct = false;
          _isProcessingInvoice = false;
        });
      }
    }
  }
}
