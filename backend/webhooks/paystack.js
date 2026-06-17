const express = require('express');
const crypto = require('crypto');
const admin = require('firebase-admin');
const axios = require('axios');

const router = express.Router();
const db = admin.firestore();

// POST /webhooks/paystack
// Must use express.raw() — registered in server.js before express.json()
router.post('/', express.raw({ type: 'application/json' }), async (req, res) => {
  // Always respond 200 immediately so Paystack doesn't retry
  res.sendStatus(200);

  try {
    const signature = req.headers['x-paystack-signature'];
    if (!signature) return;

    // Verify the request is genuinely from Paystack
    const hash = crypto
      .createHmac('sha512', process.env.PAYSTACK_SECRET_KEY)
      .update(req.body)
      .digest('hex');

    if (hash !== signature) {
      console.warn('Paystack webhook: invalid signature — ignoring');
      return;
    }

    const event = JSON.parse(req.body.toString());

    if (event.event !== 'charge.success') return;

    const reference = event.data?.reference;
    if (!reference) return;

    // Double-verify with Paystack API before trusting
    const verifyResponse = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      {
        headers: { Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}` },
      }
    );

    const txData = verifyResponse.data?.data;
    if (!txData || txData.status !== 'success') {
      console.warn(`Paystack verify failed for ${reference}`);
      return;
    }

    // Find the transaction in Firestore by reference
    // Transactions are stored as businesses/{businessId}/transactions/{reference}
    const businessId = txData.metadata?.businessId || event.data?.metadata?.businessId;

    let transactionRef;

    if (businessId) {
      transactionRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('transactions')
        .doc(reference);
    } else {
      // Fallback: query across all businesses
      const snapshot = await db
        .collectionGroup('transactions')
        .where('paystackReference', '==', reference)
        .limit(1)
        .get();

      if (snapshot.empty) {
        console.warn(`No transaction found for reference ${reference}`);
        return;
      }
      transactionRef = snapshot.docs[0].ref;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    await transactionRef.update({
      status: 'completed',
      amountCollected: txData.amount / 100,
      updatedAt: now,
    });

    console.log(`Transaction ${reference} marked as completed`);
  } catch (error) {
    console.error('Paystack webhook error:', error.message);
  }
});

module.exports = router;
