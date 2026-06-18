const express = require('express');
const admin = require('firebase-admin');

const { resolveBusinessId, productResponse } = require('../service/inventory_helpers');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

router.post('/details', async (req, res) => {
  try {
    const { idToken, productId } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!productId || typeof productId !== 'string') {
      return res.status(400).json({ error: 'productId is required' });
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const doc = await db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .doc(productId)
      .get();

    if (!doc.exists || doc.data()?.isDeleted) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ success: true, product: productResponse(doc) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
