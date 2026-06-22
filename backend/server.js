const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const admin = require('firebase-admin');

dotenv.config();

const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const addProductBackend = require('./inventory/product/add_product_backend');
const getProductsServices = require('./purchases/get_products_services');
const createCashTransaction = require('./purchases/create_cash_transaction');
const createQrTransaction = require('./purchases/create_qr_transaction');
const verifyPayment = require('./purchases/verify_payment');
const paystackWebhook = require('./webhooks/paystack');
const productListBackend = require('./inventory/product/product_list_backend');
const barcodeScannerBackend = require('./inventory/product/barcode_scanner_backend');
const reviewScannedProductsBackend = require('./inventory/product/review_scanned_products_backend');
const productDetailsBackend = require('./inventory/product/product_details_backend');
const fixedExpenseBackend = require('./business/business_insights/add_fixed_expense');
const analyticsBackend = require('./business/business_insights/analytics');
const addServiceBackend = require('./inventory/service/add_service_backend');
const subscriptionTierBackend = require('./subscription/subscription_tier_backend');
const salesTrackingBackend = require('./business/Sales_tracking/sales_tracking_backend');
const salesTrackingQueries = require('./business/Sales_tracking/sales_tracking_queries');
const adminBusinessBackend = require('./admin/admin_business_backend');
const adminAnalyticsBackend = require('./admin/analytics_backend');
const paystackBanks = require('./payments/paystack_banks');
const createSubaccount = require('./payments/create_subaccount');

const app = express();

app.use(cors());

// Webhook must be registered before express.json() — needs raw body for HMAC verification
app.use('/webhooks/paystack', paystackWebhook);

app.use(express.json());
app.use('/inventory/product', addProductBackend);
app.use('/purchases', getProductsServices);
app.use('/purchases', createCashTransaction);
app.use('/purchases', createQrTransaction);
app.use('/purchases', verifyPayment);
app.use('/business/insights', fixedExpenseBackend);
app.use('/business/insights', analyticsBackend);
app.use('/inventory/service', addServiceBackend);
app.use('/subscription-tiers', subscriptionTierBackend);
app.use('/business/sales', salesTrackingBackend);
app.use('/business/sales', salesTrackingQueries);
app.use('/inventory/product', productListBackend);
app.use('/inventory/product', barcodeScannerBackend);
app.use('/inventory/product', reviewScannedProductsBackend);
app.use('/inventory/product', productDetailsBackend);
app.use('/admin/businesses', adminBusinessBackend);
app.use('/admin/analytics', adminAnalyticsBackend);
app.use('/payments', paystackBanks);
app.use('/payments', createSubaccount);

const db = admin.firestore();
const auth = admin.auth();

app.get('/', (req, res) => {
  res.send('AwehPay backend connected to Firebase');
});

app.get('/health', async (req, res) => {
  res.json({
    status: 'ok',
    firebase: 'connected',
  });
});

app.post('/verify-token', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);

    res.json({
      success: true,
      uid: decodedToken.uid,
      email: decodedToken.email,
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      error: error.message,
    });
  }
});

app.post('/test-user-profile', async (req, res) => {
  try {
    const { uid, name, email } = req.body;

    if (!uid) {
      return res.status(400).json({ error: 'uid is required' });
    }

    await db.collection('users').doc(uid).set(
      {
        name,
        email,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    res.json({
      success: true,
      message: 'User profile saved',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`AwehPay backend running on port ${PORT}`);
});