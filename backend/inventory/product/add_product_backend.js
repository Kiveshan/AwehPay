const express = require('express');
const admin = require('firebase-admin');

const {
  normalizeName,
  resolveBusinessContext,
} = require('../service/inventory_helpers');
const { checkSubscriptionLimit } = require('../../middleware/subscription_limits');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

router.post('/options', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    const businessId = userDoc.data()?.businessId;

    if (!businessId) {
      return res.status(400).json({ error: 'No business is linked to this account' });
    }

    const productsSnapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .where('isDeleted', '==', false)
      .get();

    const products = [];
    const categories = new Set(['Other']);

    productsSnapshot.forEach((doc) => {
      const product = { productId: doc.id, ...doc.data() };
      products.push(product);

      if (product.category) {
        categories.add(product.category);
      }
    });

    products.sort((a, b) => (a.name || '').localeCompare(b.name || ''));

    res.json({
      success: true,
      products,
      categories: Array.from(categories).sort((first, second) => {
        if (first === 'Other') {
          return 1;
        }

        if (second === 'Other') {
          return -1;
        }

        return first.localeCompare(second);
      }),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

router.post('/add-product', async (req, res) => {
  try {
    const {
      idToken,
      name,
      barcode,
      costPrice,
      sellingPrice,
      totalCost,
      vat,
      stockQuantity,
      category,
      lowStockThreshold,
    } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!name || !category) {
      return res.status(400).json({ error: 'Product name and category are required' });
    }

    if (
      typeof costPrice !== 'number' ||
      typeof sellingPrice !== 'number' ||
      !Number.isInteger(stockQuantity) ||
      !Number.isInteger(lowStockThreshold)
    ) {
      return res.status(400).json({ error: 'Valid prices, quantity, and low stock threshold are required' });
    }

    const { businessId, uid } = await resolveBusinessContext({ auth, db, idToken });

    // Check subscription limits for products
    const limitCheck = await checkSubscriptionLimit(businessId, 'products');
    if (!limitCheck.allowed) {
      return res.status(403).json({
        success: false,
        error: limitCheck.error,
        limitType: 'products',
        limit: limitCheck.limit,
        current: limitCheck.current,
        tierName: limitCheck.tierName,
        requiresUpgrade: true
      });
    }

    const businessRef = db.collection('businesses').doc(businessId);
    const productRef = businessRef.collection('products').doc();
    const movementRef = businessRef.collection('stockMovements').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const resolvedTotalCost = typeof totalCost === 'number' ? totalCost : 0;
    const resolvedVat = vat === true;

    await db.runTransaction(async (transaction) => {
      transaction.set(productRef, {
        productId: productRef.id,
        businessId,
        name: name.trim(),
        nameLower: normalizeName(name),
        barcode: typeof barcode === 'string' ? barcode.trim() : '',
        costPrice,
        sellingPrice,
        totalCost: resolvedTotalCost,
        vat: resolvedVat,
        stockQuantity,
        category: category.trim(),
        lowStockThreshold,
        sku: '',
        unit: 'item',
        description: '',
        imageUrl: '',
        isActive: true,
        isDeleted: false,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      });
      transaction.update(businessRef, {
        'totals.totalProducts': admin.firestore.FieldValue.increment(1),
        updatedAt: now,
      });
      transaction.set(movementRef, {
        movementId: movementRef.id,
        businessId,
        createdAt: now,
        createdBy: uid,
        productId: productRef.id,
        productName: name.trim(),
        type: 'initial_stock',
        previousQuantity: 0,
        newQuantity: stockQuantity,
        quantity: stockQuantity,
        reason: 'Initial stock',
        referenceId: null,
        referenceType: 'manual',
        total: resolvedTotalCost,
        vat: resolvedVat,
      });
    });

    res.status(201).json({
      success: true,
      productId: productRef.id,
      businessId,
      message: 'Product added successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
