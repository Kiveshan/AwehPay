const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// POST /purchases/cash-transaction
router.post('/cash-transaction', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');

    if (!idToken) {
      return res.status(401).json({ error: 'Authorization token is required' });
    }

    const { items, amountSubtotal, amountTotal, amountCollected, customerPhone } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'At least one item is required' });
    }

    if (typeof amountTotal !== 'number' || amountTotal <= 0) {
      return res.status(400).json({ error: 'Valid amountTotal is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    const businessId = userData?.businessId;

    if (!businessId) {
      return res.status(400).json({ error: 'No business linked to this account' });
    }

    const businessRef = db.collection('businesses').doc(businessId);
    const transactionRef = businessRef.collection('transactions').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const amountTax = parseFloat((amountSubtotal * 0.15).toFixed(2));
    const amountChange = parseFloat((amountCollected - amountTotal).toFixed(2));

    await db.runTransaction(async (t) => {
      // Fetch product docs for stock decrement (skip services — no barcode/productId)
      const productItems = items.filter((i) => i.type === 'product' && i.itemId);
      const productRefs = productItems.map((i) =>
        businessRef.collection('products').doc(i.itemId)
      );
      const productDocs = productRefs.length > 0
        ? await Promise.all(productRefs.map((ref) => t.get(ref)))
        : [];

      // Validate stock availability
      for (let idx = 0; idx < productDocs.length; idx++) {
        const doc = productDocs[idx];
        const item = productItems[idx];
        if (!doc.exists) continue;
        const current = doc.data().stockQuantity ?? 0;
        if (current < item.quantity) {
          throw new Error(`Insufficient stock for "${item.name}". Available: ${current}`);
        }
      }

      // Write transaction document
      t.set(transactionRef, {
        transactionId: transactionRef.id,
        businessId,
        createdBy: decodedToken.uid,
        currency: 'ZAR',
        paymentMethod: 'cash',
        type: 'sale',
        status: 'completed',
        amountSubtotal,
        amountTax,
        amountDiscount: 0,
        amountTotal,
        amountCollected,
        amountChange,
        customerPhone: customerPhone ?? '',
        items: items.map((item) => ({
          itemId: item.itemId ?? '',
          itemType: item.type ?? 'product',
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: parseFloat((item.unitPrice * item.quantity).toFixed(2)),
        })),
        saleDate: now,
        createdAt: now,
        updatedAt: now,
      });

      // Decrement stock for product items
      for (let idx = 0; idx < productRefs.length; idx++) {
        const item = productItems[idx];
        t.update(productRefs[idx], {
          stockQuantity: admin.firestore.FieldValue.increment(-item.quantity),
          updatedAt: now,
        });
      }
    });

    res.status(201).json({
      success: true,
      transactionId: transactionRef.id,
      businessId,
      amountChange,
    });
  } catch (error) {
    console.error('create_cash_transaction error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
