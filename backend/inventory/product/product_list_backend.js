const express = require('express');
const admin = require('firebase-admin');

const { resolveBusinessId } = require('../service/inventory_helpers');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

router.post('/list', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });

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
      stockQuantity,
      lowStockThreshold,
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

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const productRef = db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .doc(productId);

    const productDoc = await productRef.get();

    if (!productDoc.exists || productDoc.data()?.isDeleted) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const updateData = {
      costPrice,
      sellingPrice,
      stockQuantity,
      lowStockThreshold,
      updatedAt: now,
    };

    if (typeof barcode === 'string') {
      updateData.barcode = barcode.trim();
    }

    await productRef.update(updateData);

    res.json({ success: true, productId, message: 'Product updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
