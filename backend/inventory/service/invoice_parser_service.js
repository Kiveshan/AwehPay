function _extractMoneyValues(line) {
  if (typeof line !== 'string') return [];
  const matches = line.match(/\b\d+[\.,]\d{2}\b/g);
  if (!matches) return [];
  return matches
    .map((value) => Number.parseFloat(value.replace(',', '.')))
    .filter((value) => Number.isFinite(value));
}

function _extractQuantity(line) {
  if (typeof line !== 'string') return null;
  const match = line.match(/\b(?:qty|quantity)\s*[:x]?\s*(\d+)\b/i);
  if (match) return Number.parseInt(match[1], 10);
  const xMatch = line.match(/\b(\d+)\s*[xX]\b/);
  if (xMatch) return Number.parseInt(xMatch[1], 10);
  return null;
}

function parseInvoiceFromRawText(rawOcrText) {
  const text = typeof rawOcrText === 'string' ? rawOcrText : '';
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  const invoiceNumberMatch = text.match(
    /\b(?:invoice\s*(?:no|number)?|inv\s*#)\s*[:#-]?\s*([A-Za-z0-9-]+)\b/i
  );
  const invoiceNumber = invoiceNumberMatch ? invoiceNumberMatch[1] : '';

  const supplierName = lines.length > 0 ? lines[0].slice(0, 64) : '';

  const products = [];
  for (const line of lines) {
    if (/\b(total|subtotal|vat|tax|change|cash|card)\b/i.test(line)) {
      continue;
    }

    const moneyValues = _extractMoneyValues(line);
    if (moneyValues.length === 0) {
      continue;
    }

    const costPrice = moneyValues[moneyValues.length - 1];
    if (!Number.isFinite(costPrice) || costPrice <= 0) {
      continue;
    }

    const quantity = _extractQuantity(line) ?? 1;
    const name = line
      .replace(/\b\d+[\.,]\d{2}\b/g, ' ')
      .replace(/\b(?:qty|quantity)\s*[:x]?\s*\d+\b/gi, ' ')
      .replace(/\b\d+\s*[xX]\b/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    if (!name || name.length < 2) {
      continue;
    }

    products.push({
      name,
      quantity,
      costPrice,
      category: 'Other',
      barcode: '',
      sellingPrice: costPrice,
      lowStockThreshold: 0,
      unit: 'item',
      confidence: 0.5,
    });
  }

  return { products, supplierName, invoiceNumber };
}

module.exports = {
  parseInvoiceFromRawText,
};
