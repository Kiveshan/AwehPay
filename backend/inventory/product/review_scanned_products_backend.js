const express = require('express');
const admin = require('firebase-admin');

const {
  resolveBusinessId,
  normalizeName,
  productResponse,
  serverTimestamp,
} = require('../service/inventory_helpers');

const {
  parseInvoiceFromRawText,
} = require('../service/invoice_parser_service');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

async function matchProductsForBusiness({ businessId, products }) {
  const productsRef = db
    .collection('businesses')
    .doc(businessId)
    .collection('products');

  const matchedProducts = [];

  for (const product of products) {
    const barcode =
      typeof product.barcode === 'string' ? product.barcode.trim() : '';
    const nameLower = normalizeName(product.name);
    let matchDoc = null;

    if (barcode) {
      const barcodeSnapshot = await productsRef
        .where('barcode', '==', barcode)
        .where('isDeleted', '==', false)
        .limit(1)
        .get();

      if (!barcodeSnapshot.empty) {
        matchDoc = barcodeSnapshot.docs[0];
      }
    }

    if (!matchDoc && nameLower) {
      const nameSnapshot = await productsRef
        .where('nameLower', '==', nameLower)
        .where('isDeleted', '==', false)
        .limit(1)
        .get();

      if (!nameSnapshot.empty) {
        matchDoc = nameSnapshot.docs[0];
      } else {
        const fallbackSnapshot = await productsRef
          .where('isDeleted', '==', false)
          .get();

        matchDoc =
          fallbackSnapshot.docs.find(
            (doc) => normalizeName(doc.data()?.name) === nameLower
          ) || null;
      }
    }

    const matchData = matchDoc ? productResponse(matchDoc) : null;
    matchedProducts.push({
      ...product,
      isExistingProduct: Boolean(matchDoc),
      matchedProductId: matchDoc?.id || null,
      existingProduct: matchData,
    });
  }

  return matchedProducts;
}

router.post('/match-scanned-products', async (req, res) => {
  try {
    const { idToken, products } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!Array.isArray(products)) {
      return res.status(400).json({ error: 'products must be an array' });
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const matchedProducts = await matchProductsForBusiness({
      businessId,
      products,
    });

    res.json({ success: true, businessId, products: matchedProducts });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/match-scanned-products-from-raw-text', async (req, res) => {
  try {
    const { idToken, rawOcrText } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!rawOcrText || typeof rawOcrText !== 'string') {
      return res.status(400).json({ error: 'rawOcrText is required' });
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const parsed = parseInvoiceFromRawText(rawOcrText);
    const matchedProducts = await matchProductsForBusiness({
      businessId,
      products: parsed.products,
    });

    res.json({
      success: true,
      businessId,
      products: matchedProducts,
      supplierName: parsed.supplierName,
      invoiceNumber: parsed.invoiceNumber,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/save-invoice-scan', async (req, res) => {
  try {
    const {
      idToken,
      rawOcrText,
      products,
      supplierName,
      invoiceNumber,
      invoiceImageUrl,
    } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!Array.isArray(products) || products.length === 0) {
      return res
        .status(400)
        .json({ error: 'At least one scanned product is required' });
    }

    for (const product of products) {
      if (
        !product.name ||
        !Number.isInteger(product.quantity) ||
        product.quantity <= 0 ||
        typeof product.costPrice !== 'number' ||
        product.costPrice <= 0 ||
        typeof product.sellingPrice !== 'number' ||
        product.sellingPrice <= 0 ||
        !Number.isInteger(product.lowStockThreshold) ||
        product.lowStockThreshold < 0
      ) {
        return res
          .status(400)
          .json({ error: 'All scanned products must be valid before saving' });
      }
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const businessRef = db.collection('businesses').doc(businessId);
    const invoiceRef = businessRef.collection('invoiceScans').doc();
    const productsRef = businessRef.collection('products');
    const now = serverTimestamp();

    const batch = db.batch();
    let createdCount = 0;

    batch.set(invoiceRef, {
      invoiceScanId: invoiceRef.id,
      businessId,
      rawOcrText: typeof rawOcrText === 'string' ? rawOcrText : '',
      supplierName: typeof supplierName === 'string' ? supplierName.trim() : '',
      invoiceNumber:
        typeof invoiceNumber === 'string' ? invoiceNumber.trim() : '',
      invoiceImageUrl: typeof invoiceImageUrl === 'string' ? invoiceImageUrl : '',
      status: 'reviewed',
      createdAt: now,
      updatedAt: now,
      extractedItems: products.map((product) => ({
        name: product.name.trim(),
        quantity: product.quantity,
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        lowStockThreshold: product.lowStockThreshold,
        barcode: typeof product.barcode === 'string' ? product.barcode.trim() : '',
        category:
          typeof product.category === 'string' && product.category.trim()
            ? product.category.trim()
            : 'Other',
        unit:
          typeof product.unit === 'string' && product.unit.trim()
            ? product.unit.trim()
            : 'item',
        matchedProductId: product.matchedProductId || '',
        confidence: typeof product.confidence === 'number' ? product.confidence : 0,
      })),
    });

    for (const product of products) {
      const category =
        typeof product.category === 'string' && product.category.trim()
          ? product.category.trim()
          : 'Other';
      const unit =
        typeof product.unit === 'string' && product.unit.trim()
          ? product.unit.trim()
          : 'item';

      if (product.matchedProductId) {
        const productRef = productsRef.doc(product.matchedProductId);
        batch.update(productRef, {
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          stockQuantity: admin.firestore.FieldValue.increment(product.quantity),
          lowStockThreshold: product.lowStockThreshold,
          category,
          unit,
          updatedAt: now,
          lastScannedAt: now,
          source: 'invoice',
        });
      } else {
        const productRef = productsRef.doc();
        batch.set(productRef, {
          productId: productRef.id,
          businessId,
          name: product.name.trim(),
          nameLower: normalizeName(product.name),
          barcode: typeof product.barcode === 'string' ? product.barcode.trim() : '',
          category,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          stockQuantity: product.quantity,
          lowStockThreshold: product.lowStockThreshold,
          unit,
          sku: '',
          description: '',
          imageUrl: '',
          source: 'invoice',
          invoiceId: invoiceRef.id,
          isActive: true,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
          lastScannedAt: now,
        });
        createdCount += 1;
      }
    }

    if (createdCount > 0) {
      batch.update(businessRef, {
        'totals.totalProducts': admin.firestore.FieldValue.increment(createdCount),
        updatedAt: now,
      });
    }

    await batch.commit();

    res.status(201).json({
      success: true,
      invoiceScanId: invoiceRef.id,
      createdCount,
      updatedCount: products.length - createdCount,
      message: 'Scanned products saved successfully',
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
