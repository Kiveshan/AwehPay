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

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    const businessId = userDoc.data()?.businessId;
    if (!businessId) return res.status(400).json({ error: 'No business linked to this account' });

    // The transaction doc ID is set to the Paystack reference at creation time
    // (see create_qr_transaction.js), so this is a direct lookup — no index needed.
    const transactionRef = db
      .collection('businesses')
      .doc(businessId)
      .collection('transactions')
      .doc(reference);

    const verifyResponse = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      {
        headers: { Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}` },
      }
    );

    const txData = verifyResponse.data?.data;
    const status = txData?.status;

    if (status === 'success') {
      await transactionRef.update({
        status: 'completed',
        amountCollected: txData.amount / 100,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({ success: true, status: 'completed' });
    }

    if (status === 'failed' || status === 'reversed') {
      await transactionRef.update({
        status: 'failed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

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
