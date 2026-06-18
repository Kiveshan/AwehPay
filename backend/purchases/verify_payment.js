const express = require('express');
const admin = require('firebase-admin');
const axios = require('axios');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// GET /purchases/verify-payment/:reference
router.get('/verify-payment/:reference', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(401).json({ error: 'Authorization token is required' });

    const { reference } = req.params;
    if (!reference) return res.status(400).json({ error: 'Reference is required' });

    await auth.verifyIdToken(idToken);

    const verifyResponse = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      {
        headers: { Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}` },
      }
    );

    const txData = verifyResponse.data?.data;
    const status = txData?.status;

    if (status === 'success') {
      // Find the transaction in Firestore and mark as completed
      const userDoc = await db
        .collection('users')
        .where('email', '==', txData.customer?.email)
        .limit(1)
        .get();

      // Try to update via collectionGroup query
      const snapshot = await db
        .collectionGroup('transactions')
        .where('paystackReference', '==', reference)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        await snapshot.docs[0].ref.update({
          status: 'completed',
          amountCollected: txData.amount / 100,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return res.json({ success: true, status: 'completed' });
    }

    if (status === 'failed' || status === 'reversed') {
      const snapshot = await db
        .collectionGroup('transactions')
        .where('paystackReference', '==', reference)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        await snapshot.docs[0].ref.update({
          status: 'failed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return res.json({ success: true, status: 'failed' });
    }

    // Still pending
    return res.json({ success: true, status: 'pending' });
  } catch (error) {
    console.error('verify_payment error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

module.exports = router;
