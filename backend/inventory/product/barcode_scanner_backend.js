const express = require('express');
const admin = require('firebase-admin');

const { resolveBusinessId, productResponse } = require('../service/inventory_helpers');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

router.post('/lookup-barcode', async (req, res) => {
  try {
    const { idToken, barcode } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!barcode || typeof barcode !== 'string') {
      return res.status(400).json({ error: 'barcode is required' });
    }

    const businessId = await resolveBusinessId({ auth, db, idToken });
    const snapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .where('barcode', '==', barcode.trim())
      .where('isDeleted', '==', false)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.json({ success: true, found: false, barcode: barcode.trim() });
    }

    res.json({
      success: true,
      found: true,
      product: productResponse(snapshot.docs[0]),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
