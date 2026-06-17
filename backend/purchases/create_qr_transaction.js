const express = require('express');
const admin = require('firebase-admin');
const axios = require('axios');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// POST /purchases/qr-transaction
router.post('/qr-transaction', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(401).json({ error: 'Authorization token is required' });

    const { items, amountTotal, customerEmail } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'At least one item is required' });
    }
    if (typeof amountTotal !== 'number' || amountTotal <= 0) {
      return res.status(400).json({ error: 'Valid amountTotal is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    if (!userDoc.exists) return res.status(404).json({ error: 'User not found' });

    const userData = userDoc.data();
    const businessId = userData?.businessId;
    if (!businessId) return res.status(400).json({ error: 'No business linked to this account' });

    const businessDoc = await db.collection('businesses').doc(businessId).get();
    const businessEmail = customerEmail || businessDoc.data()?.email || userData?.email;

    // Paystack amount must be in cents (multiply by 100)
    const amountInCents = Math.round(amountTotal * 100);

    const paystackResponse = await axios.post(
      'https://api.paystack.co/charge',
      {
        email: businessEmail,
        amount: amountInCents,
        currency: 'ZAR',
        qr: { provider: 'scan-to-pay' },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const paystackData = paystackResponse.data?.data;
    console.log('Paystack full response:', JSON.stringify(paystackResponse.data, null, 2));

    if (!paystackData) {
      return res.status(502).json({ error: 'Invalid response from Paystack' });
    }

    const reference = paystackData.reference;

    // Check all possible locations Paystack might put the QR image
    const qrImageUrl =
      paystackData.url ||
      paystackData.qr_image ||
      paystackData.display_url ||
      null;

    if (!qrImageUrl) {
      console.log('Paystack data fields:', Object.keys(paystackData));
      return res.status(502).json({
        error: 'Paystack did not return a QR image',
        paystackStatus: paystackData.status,
        paystackMessage: paystackResponse.data?.message,
        availableFields: Object.keys(paystackData),
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const transactionRef = db
      .collection('businesses')
      .doc(businessId)
      .collection('transactions')
      .doc(reference);

    await transactionRef.set({
      transactionId: reference,
      businessId,
      createdBy: decodedToken.uid,
      currency: 'ZAR',
      paymentMethod: 'qr',
      type: 'sale',
      status: 'pending',
      amountTotal,
      amountSubtotal: amountTotal,
      amountTax: 0,
      amountDiscount: 0,
      items: items.map((item) => ({
        itemId: item.itemId ?? '',
        itemType: item.type ?? 'product',
        name: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: parseFloat((item.unitPrice * item.quantity).toFixed(2)),
      })),
      paystackReference: reference,
      saleDate: now,
      createdAt: now,
      updatedAt: now,
    });

    res.status(201).json({
      success: true,
      reference,
      qrImageUrl,
      businessId,
    });
  } catch (error) {
    console.error('create_qr_transaction error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

module.exports = router;
