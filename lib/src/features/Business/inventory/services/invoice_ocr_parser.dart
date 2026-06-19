import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scanned_product.dart';

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
  List<ScannedProduct> parse(String rawText) {
    return parseInvoice(rawText).products;
  }

  ParsedInvoice parseRecognizedText(RecognizedText recognizedText) {
    final fullInvoice = parseInvoice(recognizedText.text);
    final rowProducts = _parseVisualRows(recognizedText);
    if (rowProducts.isNotEmpty) {
      return ParsedInvoice(
        products: rowProducts,
        supplierName: fullInvoice.supplierName,
        invoiceNumber: fullInvoice.invoiceNumber,
        invoiceDate: fullInvoice.invoiceDate,
      );
    }

    final products = <ScannedProduct>[];
    final seenProducts = <String>{};

    for (final block in recognizedText.blocks) {
      final blockInvoice = parseInvoice(block.text);

      for (final product in blockInvoice.products) {
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

  List<ScannedProduct> _parseVisualRows(RecognizedText recognizedText) {
    final ocrLines = <_OcrTextLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        final text = line.text.trim();
        if (text.isEmpty) continue;
        ocrLines.add(_OcrTextLine(
          text: text,
          left: box.left,
          right: box.right,
          top: box.top,
          bottom: box.bottom,
        ));
      }
    }

    if (ocrLines.isEmpty) return [];

    ocrLines.sort((a, b) => a.centerY.compareTo(b.centerY));

    // Group OCR lines into visual rows. Max tolerance 50px covers moderate
    // page tilt where price (right edge) lands at a different Y than the name.
    final rows = <_OcrVisualRow>[];
    for (final line in ocrLines) {
      if (rows.isEmpty) {
        rows.add(_OcrVisualRow([line]));
        continue;
      }
      final previous = rows.last;
      final tolerance = (line.height * 0.9).clamp(12.0, 50.0);
      if ((line.centerY - previous.centerY).abs() <= tolerance) {
        previous.lines.add(line);
      } else {
        rows.add(_OcrVisualRow([line]));
      }
    }

    final products = <ScannedProduct>[];
    final consumed = <int>{};

    for (var i = 0; i < rows.length; i++) {
      if (consumed.contains(i)) continue;

      final rowText = rows[i].text;
      if (_isSummaryRow(rowText)) continue;

      // Collect ALL money values in the row — needed for table-format detection.
      var allPrices = _extractAllMoneyValues(rowText);

      // Orphan recovery pass A: no price here, check if next row is price-only.
      if (allPrices.isEmpty && i + 1 < rows.length && !consumed.contains(i + 1)) {
        final nextText = rows[i + 1].text;
        if (!_isSummaryRow(nextText)) {
          final nextPrices = _extractAllMoneyValues(nextText);
          final nextResidue = _removeMoneyValues(nextText).trim();
          if (nextPrices.isNotEmpty && nextResidue.isEmpty) {
            allPrices = nextPrices;
            consumed.add(i + 1);
          }
        }
      }

      if (allPrices.isEmpty) continue;

      // Always use the LAST money value as the cost price (line total on
      // structured invoices) and read the qty directly from the row text —
      // no calculations or math validation.
      final namePortion = _removeMoneyValues(rowText);
      final price = allPrices.last;
      final tableQty = _extractTableQuantity(namePortion);

      // Apply ignore checks only to the name portion (not full row text) to
      // avoid rejecting products whose reference column has stray keywords.
      if (_shouldIgnoreInVisualRow(namePortion)) continue;

      var name = namePortion;

      // Remove the extracted table qty number from the name so it doesn't
      // pollute the product name field.
      if (tableQty != null) {
        name = name
            .replaceFirst(
              RegExp('(?<![A-Za-z0-9\\-/])$tableQty(?![A-Za-z.,/\\-])'),
              ' ',
            )
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      // x-pattern quantity (e.g. "3x" / "x 3") overrides table qty.
      var quantity = _extractQuantity(name) ?? tableQty;
      name = _removeQuantityText(name);

      // Extend name with detail text from subsequent no-price rows.
      for (var offset = 1; offset <= 2 && i + offset < rows.length; offset++) {
        if (consumed.contains(i + offset)) break;
        final detailText = rows[i + offset].text;
        if (_extractAllMoneyValues(detailText).isNotEmpty || _isSummaryRow(detailText)) {
          break;
        }
        quantity ??= _extractQuantity(detailText);
        final cleanedDetail = _removeQuantityText(detailText);
        if (_looksLikeProductName(cleanedDetail) &&
            !name.toLowerCase().contains(cleanedDetail.toLowerCase())) {
          name = '$name $cleanedDetail';
        }
      }

      final product = _buildProduct(
        name: name,
        quantity: quantity ?? 1,
        costPrice: price,
        confidence: 0.9,
      );
      if (product != null) products.add(product);
    }

    // Orphan recovery pass B: price-only rows that weren't consumed get paired
    // with the nearest preceding name-only row.
    for (var i = 1; i < rows.length; i++) {
      if (consumed.contains(i)) continue;
      final rowText = rows[i].text;
      if (_isSummaryRow(rowText)) continue;
      final prices = _extractAllMoneyValues(rowText);
      final residue = _removeMoneyValues(rowText).trim();
      if (prices.isEmpty || residue.isNotEmpty) continue;

      for (var j = i - 1; j >= 0 && j >= i - 3; j--) {
        if (consumed.contains(j)) continue;
        final prevText = rows[j].text;
        if (_isSummaryRow(prevText) || _extractAllMoneyValues(prevText).isNotEmpty) break;
        final namePortion = _removeMoneyValues(prevText).trim();
        if (namePortion.isEmpty || _shouldIgnoreInVisualRow(namePortion)) continue;

        var name = namePortion;
        final quantity = _extractQuantity(name);
        name = _removeQuantityText(name);
        final product = _buildProduct(
          name: name,
          quantity: quantity ?? 1,
          costPrice: prices.last,
          confidence: 0.75,
        );
        if (product != null) {
          products.add(product);
          consumed.add(i);
          consumed.add(j);
        }
        break;
      }
    }

    return products;
  }

  /// Returns every parseable money value found in [text], in left-to-right order.
  List<double> _extractAllMoneyValues(String text) {
    return RegExp(
      r'R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}',
      caseSensitive: false,
    )
        .allMatches(text)
        .map((m) => _parseSaPrice(m.group(0)!))
        .whereType<double>()
        .toList();
  }

  /// Finds a standalone integer in [nameText] that is plausibly a Qty column
  /// value — not embedded inside a product code, SKU, or unit suffix like
  /// "700g", "2L", "18s".  Returns the LAST such number (closest to the price
  /// columns) that is between 1 and 999.
  ///
  /// Uses word-splitting rather than regex lookahead/lookbehind so that "700g"
  /// is never split into "70" + "0g" by the regex engine.
  int? _extractTableQuantity(String nameText) {
    final words = nameText.trim().split(RegExp(r'\s+'));
    final pureInt = RegExp(r'^\d+$');
    final monthName = RegExp(
      r'^(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)$',
      caseSensitive: false,
    );
    // Search right-to-left for a pure integer that is NOT part of a date
    // (e.g. skip "19" when the next word is "June").
    for (var i = words.length - 1; i >= 0; i--) {
      final word = words[i];
      if (!pureInt.hasMatch(word)) continue;
      // Skip if the following word is a month name (date context).
      if (i + 1 < words.length && monthName.hasMatch(words[i + 1])) continue;
      // Skip four-digit years.
      if (word.length == 4 && word.startsWith('20')) continue;
      final value = int.tryParse(word);
      if (value != null && value >= 1 && value <= 999) return value;
    }
    return null;
  }

  /// Ignore check used inside [_parseVisualRows] — applied only to the
  /// name portion (money values already removed), NOT to the full row text.
  ///
  /// Uses word-boundary matching for keywords that legitimately appear inside
  /// product codes and reference numbers (excl, incl, date, amount, price)
  /// to avoid false positives from reference column text.
  bool _shouldIgnoreInVisualRow(String namePortion) {
    final v = namePortion.toLowerCase().trim();
    if (v.isEmpty) return true;

    // Definite header / footer patterns — substring match is safe here
    // because these phrases don't appear as parts of product codes.
    if (v.startsWith('subtotal') ||
        v.startsWith('sub total') ||
        v.startsWith('sub tot') ||
        v == 'total' ||
        v.startsWith('total ') ||
        v.startsWith('vat') ||
        v.contains('banking') ||
        v.contains('branch') ||
        v.contains('order summary') ||
        v.contains('thank you') ||
        v.contains('served by') ||
        v.contains('tax invoice') ||
        v.contains('aerial cableway') ||
        v.contains('cableway') ||
        v.contains('.net') ||
        v.contains('.com') ||
        v.contains('invoice') ||
        v.contains('unit price') ||
        v.contains('unit pric') ||
        v.contains('line total') ||
        v.contains('line tot') ||
        // Date rows — month names indicate a date string, not a product
        RegExp(r'\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b').hasMatch(v) ||
        // Four-digit year (2020–2099) almost never appears in a product name
        RegExp(r'\b20[2-9]\d\b').hasMatch(v)) {
      return true;
    }

    // Keywords that CAN appear inside reference codes — only ignore when
    // they appear as standalone words (word-boundary check).
    return RegExp(r'\bvat\b').hasMatch(v) ||
        RegExp(r'\bexcl\b').hasMatch(v) ||
        RegExp(r'\bincl\b').hasMatch(v) ||
        RegExp(r'\bdescription\b').hasMatch(v) ||
        RegExp(r'\bqty\b').hasMatch(v) ||
        RegExp(r'\bquantity\b').hasMatch(v) ||
        RegExp(r'\bamount\b').hasMatch(v) ||
        RegExp(r'\bprice\b').hasMatch(v);
  }

  // Normalises an SA price string (e.g. "R 2 625,00") to a parseable double.
  double? _parseSaPrice(String raw) {
    // Remove currency symbol and leading/trailing space.
    var s = raw.replaceAll(RegExp(r'^R\s*', caseSensitive: false), '').trim();
    // If comma is the decimal separator (SA style: "2 625,00"), swap it to dot
    // and strip the thousands space.
    if (RegExp(r'\d,\d{2}$').hasMatch(s)) {
      s = s.replaceAll(' ', '').replaceAll(',', '.');
    } else {
      // Otherwise treat comma as thousands separator ("2,625.00") – just drop it.
      s = s.replaceAll(',', '').replaceAll(' ', '');
    }
    return double.tryParse(s);
  }

  double? _extractLastMoneyValue(String text) {
    // Match SA price: optional R, then digits with optional space-thousands
    // separator, then a comma or dot followed by exactly 2 decimal digits.
    final matches = RegExp(
      r'R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}',
      caseSensitive: false,
    ).allMatches(text).toList();

    if (matches.isEmpty) {
      return null;
    }

    return _parseSaPrice(matches.last.group(0)!);
  }

  String _removeMoneyValues(String text) {
    return text
        .replaceAll(
          RegExp(
            r'R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}(?:\s*ZAR)?',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int? _extractQuantity(String text) {
    final match = RegExp(
      r'(?:^|\s)(?:x\s*(\d+)|(\d+)\s*x)(?:\s|$)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1) ?? match.group(2) ?? '');
  }

  String _removeQuantityText(String text) {
    return text
        .replaceAll(
          RegExp(r'(?:^|\s)(?:x\s*\d+|\d+\s*x)(?:\s|$)', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isSummaryRow(String text) {
    final value = text.toLowerCase();
    return value.contains('subtotal') ||
        value.contains('sub total') ||
        value.contains('sub tot') ||
        value.contains('taxes') ||
        value.contains('total') ||
        value.contains('order summary') ||
        value.contains('banking') ||
        value.contains('branch') ||
        value.contains('invoice') ||
        value.contains('unit price') ||
        value.contains('unit pric') ||
        value.contains('line total') ||
        value.startsWith('vat') ||
        value.contains(' vat ') ||
        RegExp(r'\bvat\b').hasMatch(value) ||
        RegExp(r'\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b').hasMatch(value) ||
        RegExp(r'\b20[2-9]\d\b').hasMatch(value);
  }

  ParsedInvoice parseInvoice(String rawText) {
    final products = <ScannedProduct>[];
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
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
      if (_shouldIgnore(line)) {
        continue;
      }

      final product = _parseLine(line);
      if (product != null) {
        products.add(product);
        continue;
      }

      final receiptProduct = _parseReceiptLine(lines, i);
      if (receiptProduct != null) {
        products.add(receiptProduct);
      }
    }

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

  ScannedProduct? _parseSingleItemReceipt(List<String> lines) {
    final plainValues = <double, int>{};
    final rPrefixedValues = <double, int>{};
    for (final line in lines) {
      final normalized = line
          .replaceAll(',', '.')
          .replaceAll(RegExp(r'\s+'), '');
      final match = RegExp(
        r'^(R)?(\d+\.\d{2})$',
        caseSensitive: false,
      ).firstMatch(normalized);

      if (match != null) {
        final value = double.tryParse(match.group(2)!);
        if (value != null && value > 0) {
          final bucket = match.group(1) != null ? rPrefixedValues : plainValues;
          bucket[value] = (bucket[value] ?? 0) + 1;
        }
      }
    }

    if (plainValues.isEmpty && rPrefixedValues.isEmpty) {
      return null;
    }

    // The VAT-inclusive total (e.g. "INCL 54.00") and the total charged
    // (e.g. "TOTAL R54.00") share the same value for a single-item receipt,
    // whereas change/cash amounts only appear in one form.
    double? price;
    for (final value in plainValues.keys) {
      if (rPrefixedValues.containsKey(value)) {
        price = value;
        break;
      }
    }

    if (price == null) {
      final allValues = <double, int>{};
      for (final entry in plainValues.entries) {
        allValues[entry.key] = (allValues[entry.key] ?? 0) + entry.value;
      }
      for (final entry in rPrefixedValues.entries) {
        allValues[entry.key] = (allValues[entry.key] ?? 0) + entry.value;
      }

      var bestValue = allValues.keys.first;
      var bestCount = 0;
      allValues.forEach((value, count) {
        if (count > bestCount) {
          bestCount = count;
          bestValue = value;
        }
      });
      price = bestValue;
    }

    String? name;
    for (final line in lines) {
      if (!RegExp(r'\d').hasMatch(line) && _looksLikeProductName(line)) {
        name = line;
        break;
      }
    }

    if (name == null) {
      return null;
    }

    return _buildProduct(
      name: name,
      quantity: 1,
      costPrice: price,
      confidence: 0.55,
    );
  }

  String _extractSupplierName(List<String> lines) {
    for (final line in lines.take(6)) {
      final value = line.trim();
      final lower = value.toLowerCase();
      if (value.length >= 3 &&
          !_shouldIgnore(value) &&
          !lower.contains('invoice') &&
          !RegExp(r'^\d').hasMatch(value)) {
        return value;
      }
    }

    return '';
  }

  String _extractValue(List<String> lines, RegExp pattern) {
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }

    return '';
  }

  bool _shouldIgnore(String line) {
    final value = line.toLowerCase();
    return value.contains('subtotal') ||
        value == 'total' ||
        value.startsWith('total ') ||
        value == 'rate' ||
        value.startsWith('rate ') ||
        value == 'uat' ||
        value == 'table mountain' ||
        value.contains('cableway') ||
        value.contains('.net') ||
        value.contains('.com') ||
        value.contains(' vat') ||
        value.startsWith('vat') ||
        value.contains(' tax') ||
        value.startsWith('tax') ||
        value.contains('invoice no') ||
        value.contains('invoice number') ||
        value.contains('date') ||
        value.contains('bank') ||
        value.contains('account') ||
        value.contains('address') ||
        value.contains('description') ||
        value.contains('qty') ||
        value.contains('quantity') ||
        value.contains('amount') ||
        value.contains('price') ||
        value.contains('cash') ||
        value.contains('change') ||
        value.contains('item count') ||
        value.contains('vat analysis') ||
        value.contains('thank you') ||
        value.contains('visiting us') ||
        value.contains('online') ||
        value.contains('shop') ||
        value.contains('served by') ||
        value.contains('tax invoice') ||
        value.contains('aerial cableway') ||
        value.contains('cableway co') ||
        value.contains('excl') ||
        value.contains('incl') ||
        value.contains('banking') ||
        value.contains('branch') ||
        value.contains('sub total') ||
        value.contains('sub tot');
  }

  ScannedProduct? _parseLine(String line) {
    final normalized = line
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final xMatch = RegExp(
      r'^(.+?)\s+(\d+)\s*x\s*R?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (xMatch != null) {
      return _buildProduct(
        name: xMatch.group(1)!,
        quantity: int.parse(xMatch.group(2)!),
        costPrice: double.parse(xMatch.group(3)!),
        confidence: 0.85,
      );
    }

    final tableMatch = RegExp(
      r'^(.+?)\s+(\d+)\s+R?\s*(\d+(?:\.\d{1,2})?)\s+R?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (tableMatch != null) {
      final quantity = int.parse(tableMatch.group(2)!);
      final unitPrice = double.parse(tableMatch.group(3)!);
      final lineTotal = double.parse(tableMatch.group(4)!);
      final costPrice = (lineTotal / quantity - unitPrice).abs() < 0.05
          ? unitPrice
          : lineTotal / quantity;

      return _buildProduct(
        name: tableMatch.group(1)!,
        quantity: quantity,
        costPrice: costPrice,
        confidence: 0.8,
      );
    }

    final receiptPriceMatch = RegExp(
      r'^(.+?)\s+R?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (receiptPriceMatch != null) {
      return _buildProduct(
        name: receiptPriceMatch.group(1)!,
        quantity: 1,
        costPrice: double.parse(receiptPriceMatch.group(2)!),
        confidence: 0.65,
      );
    }

    final simpleMatch = RegExp(
      r'^(.+?)\s+(\d+)\s+R?\s*(\d+(?:\.\d{1,2})?)(?:\s+R?\s*\d+(?:\.\d{1,2})?)?$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (simpleMatch != null) {
      return _buildProduct(
        name: simpleMatch.group(1)!,
        quantity: int.parse(simpleMatch.group(2)!),
        costPrice: double.parse(simpleMatch.group(3)!),
        confidence: 0.75,
      );
    }

    final codeMatch = RegExp(
      r'^[A-Za-z0-9\-_/]+\s+(.+?)\s+(\d+)\s+R?\s*(\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (codeMatch != null) {
      return _buildProduct(
        name: codeMatch.group(1)!,
        quantity: int.parse(codeMatch.group(2)!),
        costPrice: double.parse(codeMatch.group(3)!),
        confidence: 0.7,
      );
    }

    return null;
  }

  ScannedProduct? _parseReceiptLine(List<String> lines, int index) {
    final nameLine = lines[index]
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (!_looksLikeProductName(nameLine)) {
      return null;
    }

    for (var offset = 1; offset <= 3 && index + offset < lines.length; offset += 1) {
      final priceLine = lines[index + offset]
          .replaceAll(',', '.')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final priceMatch = RegExp(
        r'(?:^|\s)R?\s*(\d+(?:\.\d{1,2})?)\s*$',
        caseSensitive: false,
      ).firstMatch(priceLine);

      if (priceMatch == null) {
        continue;
      }

      final price = double.tryParse(priceMatch.group(1)!);
      if (price == null || price <= 0) {
        continue;
      }

      return _buildProduct(
        name: nameLine,
        quantity: 1,
        costPrice: price,
        confidence: 0.6,
      );
    }

    return null;
  }

  bool _looksLikeProductName(String line) {
    final value = line.trim();
    final lower = value.toLowerCase();

    if (value.length < 3 ||
        _shouldIgnore(value) ||
        RegExp(r'^\d').hasMatch(value) ||
        RegExp(r'^\W+$').hasMatch(value) ||
        RegExp(
          r'^(?:r?\s*)?\d+(?:[\.,]\d{1,2})?$',
          caseSensitive: false,
        ).hasMatch(value)) {
      return false;
    }

    return RegExp(r'[A-Za-z]').hasMatch(value) &&
        !lower.contains('total') &&
        !lower.contains('vat') &&
        !lower.contains('invoice');
  }

  /// Returns true when a name is clearly OCR garbage — e.g. the price column
  /// read sideways produces names like "R R R R R R R1 R12 6M SHIPMENT 08"
  /// where the majority of tokens are currency/number fragments.
  bool _isGarbageName(String name) {
    final words = name.split(RegExp(r'\s+'));
    if (words.isEmpty) return true;
    final junkCount = words.where((w) {
      return RegExp(r'^R\d*$', caseSensitive: false).hasMatch(w) ||
          RegExp(r'^\d+$').hasMatch(w);
    }).length;
    return junkCount / words.length > 0.55;
  }

  ScannedProduct? _buildProduct({
    required String name,
    required int quantity,
    required double costPrice,
    required double confidence,
  }) {
    var cleanedName = name
        .replaceAll(RegExp(r'[^A-Za-z0-9\s\-_/]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Strip a leading line-number prefix (e.g. "1 MSMU4243999" → "MSMU4243999").
    cleanedName = cleanedName.replaceFirst(RegExp(r'^\d+\s+'), '').trim();

    // Strip leading or trailing SKU / code column like "SKU-1001", "PROD-A12".
    // Pattern: 1-6 letters, hyphen, 1-10 alphanumeric chars.
    // This intentionally does NOT match bare product codes without a hyphen
    // (e.g. "TCUJ3176418") so those are kept as the product name.
    cleanedName = cleanedName
        .replaceFirst(RegExp(r'^[A-Za-z]{1,6}-[A-Za-z0-9]{1,10}\s+'), '')
        .replaceFirst(RegExp(r'\s+[A-Za-z]{1,6}-[A-Za-z0-9]{1,10}$'), '')
        .trim();

    // Strip trailing column-header fragments that bleed into the name row
    // (e.g. "…Eggs Large 18s SKU" or "…Bread CODE").
    cleanedName = cleanedName
        .replaceAll(RegExp(r'\s+(?:SKU|CODE|REF|ITEM)\s*$', caseSensitive: false), '')
        .trim();

    // Remove leftover standalone currency prefix "R" tokens (e.g. "R POLYFIBRO" → "POLYFIBRO").
    cleanedName = cleanedName
        .replaceAll(RegExp(r'\bR\b\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Remove orphaned unit fragments like "0g", "0L", "0ml" that are left when
    // OCR splits "700g" into "70" (extracted as qty) + "0g" (left in name).
    cleanedName = cleanedName
        .replaceAll(RegExp(r'\b0[A-Za-z]+\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanedName.isEmpty || quantity <= 0 || costPrice <= 0) {
      return null;
    }

    // Reject names that are clearly OCR garbage from a rotated price column —
    // e.g. "R R R R R R R1 R12" where most tokens are currency fragments.
    if (_isGarbageName(cleanedName)) {
      return null;
    }

    return ScannedProduct(
      name: cleanedName,
      quantity: quantity,
      costPrice: costPrice,
      category: 'Other',
      confidence: confidence,
    );
  }
}
