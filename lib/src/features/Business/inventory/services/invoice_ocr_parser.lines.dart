part of 'invoice_ocr_parser.dart';

// Text-line based parsing of receipt/list-style invoices.

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
    final lineTotal = double.parse(tableMatch.group(4)!);

    return _buildProduct(
      name: tableMatch.group(1)!,
      quantity: quantity,
      costPrice: lineTotal,
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
    r'^(.+?)\s+(\d+)\s+R?\s*(\d+(?:\.\d{1,2})?)(?:\s+R?\s*(\d+(?:\.\d{1,2})?))?$',
    caseSensitive: false,
  ).firstMatch(normalized);

  if (simpleMatch != null) {
    final unitPrice = double.parse(simpleMatch.group(3)!);
    final lineTotalStr = simpleMatch.group(4);
    final costPrice = lineTotalStr != null ? double.parse(lineTotalStr) : unitPrice;
    return _buildProduct(
      name: simpleMatch.group(1)!,
      quantity: int.parse(simpleMatch.group(2)!),
      costPrice: costPrice,
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
