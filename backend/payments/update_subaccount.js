const express = require('express');
const admin = require('firebase-admin');
const axios = require('axios');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

function lastFour(value) {
  const digits = String(value).replace(/\s+/g, '');
  return digits.length <= 4 ? digits : digits.slice(-4);
}

// PUT /payments/subaccount
// Lets a business owner change the bank account their payouts settle to.
// Mirrors create_subaccount.js, but updates the existing Paystack subaccount
// (or creates one if the business somehow never got one) instead of always
// creating a new one, so the owner keeps a single subaccount code over time.
router.put('/subaccount', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(401).json({ error: 'Authorization token is required' });

    const { businessId, bankAccountId, bankName, bankCode, accountNumber, accountType, branchName, branchCode } = req.body;

    if (!businessId || !bankAccountId || !bankName || !bankCode || !accountNumber || !accountType || !branchName || !branchCode) {
      return res.status(400).json({
        error: 'businessId, bankAccountId, bankName, bankCode, accountNumber, accountType, branchName and branchCode are required',
      });
    }

    const decodedToken = await auth.verifyIdToken(idToken);

    const businessRef = db.collection('businesses').doc(businessId);
    const businessDoc = await businessRef.get();
    if (!businessDoc.exists || businessDoc.data()?.ownerId !== decodedToken.uid) {
      return res.status(403).json({ error: 'Not authorized for this business' });
    }

    const businessData = businessDoc.data();
    const existingSubaccountCode = businessData.paystackSubaccountCode;

    // Paystack's create and update subaccount endpoints inconsistently name the bank
    // field: create takes `bank_code`, update takes `settlement_bank`.
    const paystackResponse = existingSubaccountCode
      ? await axios.put(
          `https://api.paystack.co/subaccount/${existingSubaccountCode}`,
          {
            business_name: businessData.businessName,
            settlement_bank: bankCode,
            account_number: accountNumber,
          },
          {
            headers: {
              Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
              'Content-Type': 'application/json',
            },
          }
        )
      : await axios.post(
          'https://api.paystack.co/subaccount',
          {
            business_name: businessData.businessName,
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

    await businessRef.update({
      paystackSubaccountCode: subaccountData.subaccount_code,
      paystackSubaccountId: subaccountData.id,
      updatedAt: now,
    });

    await businessRef.collection('bankAccounts').doc(bankAccountId).update({
      bankName,
      bankCode,
      accountNumberLast4: lastFour(accountNumber),
      accountType,
      branchName,
      branchCode,
      paystackSubaccountCode: subaccountData.subaccount_code,
      verificationStatus: 'subaccount_updated',
      updatedAt: now,
    });

    res.json({
      success: true,
      subaccountCode: subaccountData.subaccount_code,
    });
  } catch (error) {
    console.error('update_subaccount error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

module.exports = router;
