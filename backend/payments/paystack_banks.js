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

module.exports = router;
