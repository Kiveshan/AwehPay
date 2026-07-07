part of 'invoice_ocr_parser.dart';

// Shared regex/normalisation helpers used across the parser.

// Finds every price-like value in [text] and returns them as doubles in order.
// The regex handles all common South African price formats including R-prefix,
// space/comma/dot separators, and OCR misreads like "o" for "0".
List<double> _extractAllMoneyValues(String text) {
  return RegExp(
    r'R\s*\d{1,3}[.,]\d{3}[.,]\d{2}|R\s*\d+[.,]\d[oO]\b|R\s*\d{2,3}\s\d{2}\b|R\s*\d{1,3}(?:,\d{3})+\.\d{2}|R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:,\d{3})+\.\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}',
    caseSensitive: false,
  )
      .allMatches(text)
      .map((m) => _parseSaPrice(m.group(0)!))
      .whereType<double>()
      .toList();
}

// Converts a raw South African price string to a double.
// Handles the many ways OCR and different invoice styles encode prices:
//   "R 4,999.99", "R4.999.99" (OCR period-as-separator), "699 98" (space decimal),
//   "2 625,00" (space-thousands comma-decimal), "399.0o" (OCR o/O for 0).
double? _parseSaPrice(String raw) {
  var s = raw.replaceAll(RegExp(r'^R\s*', caseSensitive: false), '').trim();

  // OCR reads "R 4,999.99" as "R4.999.99" — period used for both separators.
  // Strip the first separator (thousands) to get "4999.99".
  if (RegExp(r'^\d{1,3}[.,]\d{3}[.,]\d{2}$').hasMatch(s)) {
    final firstSep = s.indexOf(RegExp(r'[.,]'));
    s = s.substring(0, firstSep) + s.substring(firstSep + 1);
    return double.tryParse(s.replaceAll(',', '.'));
  }

  // OCR misreads "0" as "o"/"O" at end of decimal: "399.0o" → "399.00".
  s = s.replaceAllMapped(
    RegExp(r'([.,]\d)[oO]$'),
    (m) => '${m.group(1)}0',
  );

  // Space as decimal separator (2–3 digit integer part only, to avoid
  // confusion with space-thousands format): "699 98" → 699.98.
  if (RegExp(r'^\d{2,3}\s\d{2}$').hasMatch(s)) {
    return double.tryParse(s.replaceFirst(' ', '.'));
  }

  // Comma-thousands, dot-decimal: "4,999.99"
  if (RegExp(r'^\d{1,3}(?:,\d{3})+\.\d{2}$').hasMatch(s)) {
    return double.tryParse(s.replaceAll(',', ''));
  }

  // Space-thousands, comma-decimal: "2 625,00"
  if (RegExp(r'\d,\d{2}$').hasMatch(s)) {
    s = s.replaceAll(' ', '').replaceAll(',', '.');
  } else {
    s = s.replaceAll(',', '').replaceAll(' ', '');
  }
  return double.tryParse(s);
}

// Convenience wrapper — returns just the last money value found in the text,
// which on table-style invoices is the line total.
double? _extractLastMoneyValue(String text) {
  final matches = RegExp(
    r'R\s*\d{1,3}[.,]\d{3}[.,]\d{2}|R\s*\d+[.,]\d[oO]\b|R\s*\d{2,3}\s\d{2}\b|R\s*\d{1,3}(?:,\d{3})+\.\d{2}|R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:,\d{3})+\.\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}',
    caseSensitive: false,
  ).allMatches(text).toList();

  if (matches.isEmpty) {
    return null;
  }

  return _parseSaPrice(matches.last.group(0)!);
}

// Strips all money values out of [text], leaving only the non-price portions
// (typically the product name and quantity). Used to isolate the name column.
String _removeMoneyValues(String text) {
  return text
      .replaceAll(
        RegExp(
          r'R\s*\d{1,3}[.,]\d{3}[.,]\d{2}|R\s*\d+[.,]\d[oO]\b|R\s*\d{2,3}\s\d{2}\b|R\s*\d{1,3}(?:,\d{3})+\.\d{2}|R\s*\d{1,3}(?:\s\d{3})*[.,]\d{2}|\d{1,3}(?:,\d{3})+\.\d{2}|\d{1,3}(?:\s\d{3})+[.,]\d{2}|\d+[.,]\d{2}(?:\s*ZAR)?|R\s*\d{1,3}[.,]\d{3}\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// Extracts an "x-pattern" quantity from text, e.g. "3x" or "x 3".
// Returns null if no such pattern is found.
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

// Removes the "x-pattern" quantity token from text so it doesn't end up
// in the product name (e.g. "Bread 3x" → "Bread").
String _removeQuantityText(String text) {
  return text
      .replaceAll(
        RegExp(r'(?:^|\s)(?:x\s*\d+|\d+\s*x)(?:\s|$)', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// Returns true if this row is a summary/header/footer line that should never
// be treated as a product — totals, VAT, subtotals, dates, banking details, etc.
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
      // Month names indicate a date row.
      RegExp(r'\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b').hasMatch(value) ||
      // Four-digit years (2020–2099) signal a date, not a product.
      RegExp(r'\b20[2-9]\d\b').hasMatch(value);
}

// Broader ignore list used by the text-line parser.
// Covers all header/footer/summary keywords that should never be product names.
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

// Returns true when a name is clearly OCR garbage — e.g. the price column
// read sideways produces names like "R R R R R R R1 R12 6M SHIPMENT 08"
// where the majority of tokens are currency/number fragments.
bool _isGarbageName(String name) {
  final words = name.split(RegExp(r'\s+'));
  if (words.isEmpty) return true;
  final junkCount = words.where((w) {
    return RegExp(r'^R\d*$', caseSensitive: false).hasMatch(w) ||
        RegExp(r'^\d+$').hasMatch(w);
  }).length;
  // Reject if more than 55% of tokens are currency/number fragments.
  return junkCount / words.length > 0.55;
}

// Final step for every candidate product: strips OCR noise from the name,
// validates the values, and constructs a ScannedProduct or returns null.
ScannedProduct? _buildProduct({
  required String name,
  required int quantity,
  required double costPrice,
  double totalCost = 0.0,
  required double confidence,
}) {
  // Remove all characters that aren't letters, digits, spaces, or common punctuation.
  var cleanedName = name
      .replaceAll(RegExp(r'[^A-Za-z0-9\s\-_/]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Strip leading digit-only tokens and OCR-corrupted barcodes.
  // Pure-digit groups handle split barcodes ("600970 1234567 ").
  // The 8+ char pattern handles barcodes where OCR swapped digits for similar
  // letters: B→8, g/q→9, O/o→0, S→5, Z→2, l/I→1.
  cleanedName = cleanedName
      .replaceFirst(
        RegExp(r'^(?:[0-9BOoSZzlIgq]{8,}\s+|\d+\s+)+', caseSensitive: false),
        '',
      )
      .trim();

  // Strip leading or trailing SKU/code columns like "SKU-1001" or "PROD-A12".
  // Intentionally does NOT match bare product codes without a hyphen
  // (e.g. "TCUJ3176418") so those are kept as the product name.
  cleanedName = cleanedName
      .replaceFirst(RegExp(r'^[A-Za-z]{1,6}-[A-Za-z0-9]{1,10}\s+'), '')
      .replaceFirst(RegExp(r'\s+[A-Za-z]{1,6}-[A-Za-z0-9]{1,10}$'), '')
      .trim();

  // Strip trailing column-header fragments that bleed into the name row
  // (e.g. "Eggs Large 18s SKU" or "Bread CODE").
  cleanedName = cleanedName
      .replaceAll(RegExp(r'\s+(?:SKU|CODE|REF|ITEM)\s*$', caseSensitive: false), '')
      .trim();

  // Remove leftover standalone "R" currency prefix tokens (e.g. "R POLYFIBRO" → "POLYFIBRO").
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

  // Reject names that are clearly OCR garbage from a rotated price column.
  if (_isGarbageName(cleanedName)) {
    return null;
  }

  return ScannedProduct(
    name: cleanedName,
    quantity: quantity,
    costPrice: costPrice,
    totalCost: totalCost,
    category: 'Other',
    confidence: confidence,
  );
}
