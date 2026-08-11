const express = require('express');
const admin = require('firebase-admin');
const crypto = require('crypto');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// A stable, non-reversible identifier for a settlement bank account. Only the hash is
// ever stored — the full account number itself is never persisted anywhere (Flutter
// only keeps the last 4 digits, and this backend only sees the full number in transit
// on its way to Paystack) — so this is the one place duplicate bank accounts across
// businesses can be detected.
function bankAccountFingerprint(bankCode, accountNumber) {
  const digits = String(accountNumber).replace(/\D/g, '');
  return crypto.createHash('sha256').update(`${bankCode}:${digits}`).digest('hex');
}

// POST /registration/check
// Pre-flight validation for the sign-up wizard, called before the Firebase Auth
// account is created. Prevents the same person/business from dodging trial expiry by
// re-registering under a new email with the same settlement bank account, or
// re-using an email that's already registered. Fields are optional so the same
// endpoint can be called with just `email` early in the wizard (fast feedback) and
// again with `bankCode`/`accountNumber` once those are known, right before the
// account is actually created.
router.post('/check', async (req, res) => {
  try {
    const { email, bankCode, accountNumber } = req.body;

    const result = { emailAvailable: true, bankAccountAvailable: true };

    if (email) {
      try {
        await auth.getUserByEmail(String(email).trim().toLowerCase());
        result.emailAvailable = false;
        result.emailError = 'An account with this email already exists. Please sign in instead.';
      } catch (err) {
        if (err.code !== 'auth/user-not-found') throw err;
      }
    }

    if (bankCode && accountNumber) {
      const fingerprint = bankAccountFingerprint(bankCode, accountNumber);
      const doc = await db.collection('bankAccountFingerprints').doc(fingerprint).get();
      if (doc.exists) {
        result.bankAccountAvailable = false;
        result.bankAccountError =
          'This bank account is already linked to an AwehBiz account. Each business may only claim one free trial.';
      }
    }

    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
module.exports.bankAccountFingerprint = bankAccountFingerprint;
