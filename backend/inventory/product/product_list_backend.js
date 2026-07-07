const express = require('express');
const admin = require('firebase-admin');

const { resolveBusinessContext } = require('../service/inventory_helpers');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

router.post('/list', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const { businessId } = await resolveBusinessContext({ auth, db, idToken });

    const snapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .where('isDeleted', '==', false)
      .get();

    const products = [];

    snapshot.forEach((doc) => {
      products.push({ productId: doc.id, ...doc.data() });
    });

    res.json({ success: true, products });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/update-product', async (req, res) => {
  try {
    const {
      idToken,
      productId,
      barcode,
      costPrice,
      sellingPrice,
      totalCost,
      vat,
      stockQuantity,
      lowStockThreshold,
      category,
    } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!productId) {
      return res.status(400).json({ error: 'productId is required' });
    }

    if (
      typeof costPrice !== 'number' ||
      typeof sellingPrice !== 'number' ||
      !Number.isInteger(stockQuantity) ||
      !Number.isInteger(lowStockThreshold)
    ) {
      return res.status(400).json({
        error: 'Valid prices, quantity, and low stock threshold are required',
      });
    }

    const { businessId, uid } = await resolveBusinessContext({ auth, db, idToken });
    const businessRef = db.collection('businesses').doc(businessId);
    const productRef = businessRef.collection('products').doc(productId);

    const productDoc = await productRef.get();

    if (!productDoc.exists || productDoc.data()?.isDeleted) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const previousQuantity = productDoc.data()?.stockQuantity ?? 0;
    const productName = productDoc.data()?.name ?? '';
    const resolvedTotalCost = typeof totalCost === 'number' ? totalCost : 0;
    const resolvedVat = vat === true;
    const now = admin.firestore.FieldValue.serverTimestamp();

    const updateData = {
      costPrice,
      sellingPrice,
      totalCost: resolvedTotalCost,
      vat: resolvedVat,
      stockQuantity,
      lowStockThreshold,
      updatedAt: now,
    };

    if (typeof barcode === 'string') {
      updateData.barcode = barcode.trim();
    }

    if (typeof category === 'string' && category.trim()) {
      updateData.category = category.trim();
    }

    const quantityDelta = stockQuantity - previousQuantity;
    const movementType = quantityDelta > 0 ? 'replenish' : quantityDelta < 0 ? 'adjustment' : 'update';

    const movementRef = businessRef.collection('stockMovements').doc();
    const movementData = {
      movementId: movementRef.id,
      businessId,
      createdAt: now,
      createdBy: uid,
      productId,
      productName,
      type: movementType,
      previousQuantity,
      newQuantity: stockQuantity,
      quantity: quantityDelta,
      reason: quantityDelta > 0 ? 'Stock replenishment' : 'Product update',
      referenceId: null,
      referenceType: 'manual',
      total: resolvedTotalCost,
      vat: resolvedVat,
    };

    const batch = db.batch();
    batch.update(productRef, updateData);
    batch.set(movementRef, movementData);
    await batch.commit();

    res.json({ success: true, productId, message: 'Product updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
