import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scanned_product.dart';

part 'invoice_ocr_parser.rows.dart';
part 'invoice_ocr_parser.lines.dart';
part 'invoice_ocr_parser.helpers.dart';

class ParsedInvoice {
  const ParsedInvoice({
    required this.products,
    this.supplierName = '',
    this.invoiceNumber = '',
    this.invoiceDate = '',
  });

  final List<ScannedProduct> products;
  final String supplierName;
  final String invoiceNumber;
  final String invoiceDate;
}

class _OcrTextLine {
  const _OcrTextLine({required this.text, required this.left, required this.right, required this.top, required this.bottom});

  final String text;
  final double left;
  final double right;
  final double top;
  final double bottom;

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

class _OcrVisualRow {
  _OcrVisualRow(this.lines);

  final List<_OcrTextLine> lines;

  double get centerY => lines.map((line) => line.centerY).reduce((a, b) => a + b) / lines.length;

  String get text {
    final sorted = [...lines]..sort((a, b) => a.left.compareTo(b.left));
    return sorted.map((line) => line.text).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class InvoiceOcrParser {
  // Convenience method — parses raw text and returns only the product list.
  List<ScannedProduct> parse(String rawText) {
    return parseInvoice(rawText).products;
  }

  // Main entry point when ML Kit's structured RecognizedText is available.
  // Tries visual-row parsing first (uses bounding boxes) because it handles
  // table-style invoices accurately. Falls back to line-by-line regex parsing
  // if visual rows return nothing.
  ParsedInvoice parseRecognizedText(RecognizedText recognizedText) {
    // Parse the full flat text once to extract header metadata (supplier, number, date).
    final fullInvoice = parseInvoice(recognizedText.text);

    // Attempt the bounding-box strategy — groups OCR lines by their Y position.
    final rowProducts = _parseVisualRows(recognizedText);
    if (rowProducts.isNotEmpty) {
      return ParsedInvoice(
        products: rowProducts,
        supplierName: fullInvoice.supplierName,
        invoiceNumber: fullInvoice.invoiceNumber,
        invoiceDate: fullInvoice.invoiceDate,
      );
    }

    // Visual rows found nothing — try parsing block by block to avoid duplicates
    // that can appear when the same item spans multiple ML Kit blocks.
    final products = <ScannedProduct>[];
    final seenProducts = <String>{};

    for (final block in recognizedText.blocks) {
      final blockInvoice = parseInvoice(block.text);

      for (final product in blockInvoice.products) {
        // Deduplicate by name + quantity + price so the same line isn't added twice.
        final key = [
          product.name.toLowerCase(),
          product.quantity,
          product.costPrice.toStringAsFixed(2),
        ].join('|');

        if (seenProducts.add(key)) {
          products.add(product);
        }
      }
    }

    return ParsedInvoice(
      products: products.isEmpty ? fullInvoice.products : products,
      supplierName: fullInvoice.supplierName,
      invoiceNumber: fullInvoice.invoiceNumber,
      invoiceDate: fullInvoice.invoiceDate,
    );
  }

  // Parses a plain text string (no spatial data). Splits into lines, extracts
  // metadata from the header, then tries to match each line as a product.
  ParsedInvoice parseInvoice(String rawText) {
    final products = <ScannedProduct>[];
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Pull supplier name, invoice number and date from the top of the document.
    final supplierName = _extractSupplierName(lines);
    final invoiceNumber = _extractValue(
      lines,
      RegExp(
        r'(?:invoice|inv|tax invoice)\s*(?:no|number|#)?\s*[:#-]?\s*([A-Za-z0-9\-_/]+)',
        caseSensitive: false,
      ),
    );
    final invoiceDate = _extractValue(
      lines,
      RegExp(
        r'(?:date|invoice date)\s*[:#-]?\s*([0-9]{1,4}[\/\-.][0-9]{1,2}[\/\-.][0-9]{1,4})',
        caseSensitive: false,
      ),
    );

    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];

      // Skip header/footer noise: totals, VAT lines, dates, banking details, etc.
      if (_shouldIgnore(line)) {
        continue;
      }

      // Try matching the line as a self-contained product row (name + qty + price).
      final product = _parseLine(line);
      if (product != null) {
        products.add(product);
        continue;
      }

      // Receipt-style: product name on one line, price on the next 1–3 lines.
      final receiptProduct = _parseReceiptLine(lines, i);
      if (receiptProduct != null) {
        products.add(receiptProduct);
      }
    }

    // Last-resort: if nothing was found and the receipt says "item count - 1",
    // try a dedicated single-item handler that looks for the most repeated price.
    if (products.isEmpty) {
      final itemCountMatch = RegExp(
        r'item\s*count\s*-?\s*(\d+)',
        caseSensitive: false,
      );
      int? itemCount;
      for (final line in lines) {
        final match = itemCountMatch.firstMatch(line);
        if (match != null) {
          itemCount = int.tryParse(match.group(1)!);
          break;
        }
      }

      if (itemCount == 1) {
        final single = _parseSingleItemReceipt(lines);
        if (single != null) {
          products.add(single);
        }
      }
    }

    return ParsedInvoice(
      products: products,
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
    );
  }
}
