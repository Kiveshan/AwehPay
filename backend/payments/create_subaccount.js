const express = require('express');
const admin = require('firebase-admin');
const axios = require('axios');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// POST /payments/subaccount
router.post('/subaccount', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(401).json({ error: 'Authorization token is required' });

    const { businessId, bankAccountId, businessName, bankCode, accountNumber } = req.body;

    if (!businessId || !bankAccountId || !businessName || !bankCode || !accountNumber) {
      return res.status(400).json({
        error: 'businessId, bankAccountId, businessName, bankCode and accountNumber are required',
      });
    }

    const decodedToken = await auth.verifyIdToken(idToken);

    const businessDoc = await db.collection('businesses').doc(businessId).get();
    if (!businessDoc.exists || businessDoc.data()?.ownerId !== decodedToken.uid) {
      return res.status(403).json({ error: 'Not authorized for this business' });
    }

    const paystackResponse = await axios.post(
      'https://api.paystack.co/subaccount',
      {
        business_name: businessName,
        bank_code: bankCode,
        account_number: accountNumber,
        percentage_charge: 0,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const subaccountData = paystackResponse.data?.data;
    if (!subaccountData) {
      return res.status(502).json({ error: 'Invalid response from Paystack' });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('businesses').doc(businessId).update({
      paystackSubaccountCode: subaccountData.subaccount_code,
      paystackSubaccountId: subaccountData.id,
      updatedAt: now,
    });

    await db
      .collection('businesses')
      .doc(businessId)
      .collection('bankAccounts')
      .doc(bankAccountId)
      .update({
        bankCode,
        paystackSubaccountCode: subaccountData.subaccount_code,
        verificationStatus: 'subaccount_created',
        updatedAt: now,
      });

    res.status(201).json({
      success: true,
      subaccountCode: subaccountData.subaccount_code,
    });
  } catch (error) {
    console.error('create_subaccount error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

module.exports = router;
