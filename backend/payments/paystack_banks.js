const express = require('express');
const axios = require('axios');

const router = express.Router();

let cachedBanks = null;
let cachedAt = 0;
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

// GET /payments/banks
router.get('/banks', async (req, res) => {
  try {
    const now = Date.now();
    if (cachedBanks && now - cachedAt < CACHE_TTL_MS) {
      return res.json({ success: true, banks: cachedBanks });
    }

    const paystackResponse = await axios.get('https://api.paystack.co/bank', {
      params: { country: 'south africa', currency: 'ZAR' },
      headers: {
        Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
      },
    });

    const banks = (paystackResponse.data?.data || []).map((bank) => ({
      name: bank.name,
      code: bank.code,
    }));

    cachedBanks = banks;
    cachedAt = now;

    res.json({ success: true, banks });
  } catch (error) {
    console.error('paystack_banks error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

// GET /payments/resolve-account?accountNumber=...&bankCode=...
router.get('/resolve-account', async (req, res) => {
  try {
    const { accountNumber, bankCode } = req.query;

    if (!accountNumber || !bankCode) {
      return res.status(400).json({ error: 'accountNumber and bankCode are required' });
    }

    const paystackResponse = await axios.get('https://api.paystack.co/bank/resolve', {
      params: { account_number: accountNumber, bank_code: bankCode },
      headers: {
        Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
      },
    });

    const data = paystackResponse.data?.data;

    res.json({
      success: true,
      accountName: data?.account_name ?? null,
    });
  } catch (error) {
    console.error('resolve_account error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      error: error.response?.data?.message || error.message,
    });
  }
});

module.exports = router;
