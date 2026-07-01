part of 'invoice_ocr_parser.dart';

// Visual-row (bounding-box) based parsing of structured/table invoices.

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

    // Orphan recovery pass A: no price here, check if next row is price-only
    // OR has a leading QTY integer followed by prices (e.g. "5 15.00 75.00").
    int? orphanQty;
    if (allPrices.isEmpty && i + 1 < rows.length && !consumed.contains(i + 1)) {
      final nextText = rows[i + 1].text;
      if (!_isSummaryRow(nextText)) {
        final nextPrices = _extractAllMoneyValues(nextText);
        final nextResidue = _removeMoneyValues(nextText).trim();
        if (nextPrices.isNotEmpty && nextResidue.isEmpty) {
          allPrices = nextPrices;
          consumed.add(i + 1);
        } else if (nextPrices.isNotEmpty && RegExp(r'^\d+$').hasMatch(nextResidue)) {
          // Next row is "QTY UNIT_PRICE LINE_TOTAL" — capture all three.
          final qtyVal = int.tryParse(nextResidue);
          if (qtyVal != null && qtyVal >= 1 && qtyVal <= 9999) {
            allPrices = nextPrices;
            orphanQty = qtyVal;
            consumed.add(i + 1);
          }
        }
      }
    }

    if (allPrices.isEmpty) continue;

    // Always use the LAST money value as the cost price (line total on
    // structured invoices).
    final namePortion = _removeMoneyValues(rowText);
    var price = allPrices.last;

    // When two prices are present (unit price + line total), derive qty from
    // their ratio. OCR frequently misses or garbles the narrow QTY column,
    // and product names often contain numbers ("43 inch", "6 Way Plug") that
    // would be incorrectly extracted as qty by text scanning.
    int? calculatedQty;
    if (allPrices.length >= 2) {
      final unitPrice = allPrices[allPrices.length - 2];
      final lineTotal = allPrices.last;
      if (unitPrice > 0) {
        if (lineTotal < unitPrice * 0.9) {
          // Line total is lower than the unit price — impossible for qty≥1,
          // so the line total column was OCR-corrupted (e.g. "R4,999.99"
          // partially read as "R4.99"). Fall back to unit price, qty=1.
          price = unitPrice;
          calculatedQty = 1;
        } else {
          final ratio = lineTotal / unitPrice;
          final rounded = ratio.round();
          if (rounded >= 1 &&
              rounded <= 999 &&
              (ratio - rounded).abs() / rounded < 0.02) {
            calculatedQty = rounded;
          }
        }
      }
    }
    final tableQty = orphanQty ?? calculatedQty ?? _extractTableQuantity(namePortion);

    // Apply ignore checks only to the name portion (not full row text) to
    // avoid rejecting products whose reference column has stray keywords.
    if (_shouldIgnoreInVisualRow(namePortion)) continue;

    var name = namePortion;

    // Remove the extracted table qty number from the name so it doesn't
    // pollute the product name field.
    if (tableQty != null) {
      name = name
          .replaceFirst(
            RegExp('(?<![A-Za-z0-9\\-/])$tableQty(?![A-Za-z0-9.,/\\-])'),
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
