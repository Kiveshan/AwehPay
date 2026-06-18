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
        if (text.isEmpty) {
          continue;
        }

        ocrLines.add(
          _OcrTextLine(
            text: text,
            left: box.left,
            right: box.right,
            top: box.top,
            bottom: box.bottom,
          ),
        );
      }
    }

    if (ocrLines.isEmpty) {
      return [];
    }

    ocrLines.sort((a, b) => a.centerY.compareTo(b.centerY));
    final rows = <_OcrVisualRow>[];
    for (final line in ocrLines) {
      if (rows.isEmpty) {
        rows.add(_OcrVisualRow([line]));
        continue;
      }

      final previous = rows.last;
      final tolerance = (line.height * 0.8).clamp(12, 34).toDouble();
      if ((line.centerY - previous.centerY).abs() <= tolerance) {
        previous.lines.add(line);
      } else {
        rows.add(_OcrVisualRow([line]));
      }
    }

    final products = <ScannedProduct>[];
    for (var i = 0; i < rows.length; i += 1) {
      final rowText = rows[i].text;
      final price = _extractLastMoneyValue(rowText);
      if (price == null || _isSummaryRow(rowText) || _shouldIgnore(rowText)) {
        continue;
      }

      var name = _removeMoneyValues(rowText);
      var quantity = _extractQuantity(name);
      name = _removeQuantityText(name);

      for (var offset = 1; offset <= 2 && i + offset < rows.length; offset += 1) {
        final detailText = rows[i + offset].text;
        if (_extractLastMoneyValue(detailText) != null || _isSummaryRow(detailText)) {
          break;
        }

        quantity ??= _extractQuantity(detailText);
        final cleanedDetail = _removeQuantityText(detailText);
        if (_looksLikeProductName(cleanedDetail) && !name.toLowerCase().contains(cleanedDetail.toLowerCase())) {
          name = '$name $cleanedDetail';
        }
      }

      final product = _buildProduct(
        name: name,
        quantity: quantity ?? 1,
        costPrice: price,
        confidence: 0.9,
      );
      if (product != null) {
        products.add(product);
      }
    }

    return products;
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
        value.startsWith('vat') ||
        value.contains(' vat ') ||
        RegExp(r'\bvat\b').hasMatch(value);
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

    if (value.length < 4 ||
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

    if (cleanedName.isEmpty || quantity <= 0 || costPrice <= 0) {
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
