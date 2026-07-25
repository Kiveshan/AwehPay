const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const admin = require('firebase-admin');

dotenv.config();

// Load Firebase service-account credentials.
// - Cloud (Elastic Beanstalk): PREFER FIREBASE_SERVICE_ACCOUNT_B64 — the base64 of the
//   JSON key file. base64 has no newlines/quotes, so the private key survives EB
//   environment-property transport intact. FIREBASE_SERVICE_ACCOUNT (raw JSON) also works
//   but can corrupt the PEM newlines depending on how it's set.
// - Local dev: GOOGLE_APPLICATION_CREDENTIALS points at the JSON key file on disk.
function loadServiceAccount() {
  let serviceAccount;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_B64) {
    const json = Buffer.from(
      process.env.FIREBASE_SERVICE_ACCOUNT_B64,
      'base64'
    ).toString('utf8');
    try {
      serviceAccount = JSON.parse(json);
    } catch (err) {
      throw new Error(
        `FIREBASE_SERVICE_ACCOUNT_B64 did not decode to valid JSON: ${err.message}`
      );
    }
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (err) {
      throw new Error(
        `FIREBASE_SERVICE_ACCOUNT is set but is not valid JSON: ${err.message}`
      );
    }
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  } else {
    throw new Error(
      'No Firebase credentials found. Set FIREBASE_SERVICE_ACCOUNT_B64 (base64 JSON, ' +
        'preferred for cloud/Beanstalk) or GOOGLE_APPLICATION_CREDENTIALS (file path, ' +
        'for local dev).'
    );
  }

  // Safety net: if the private key arrived with escaped "\n" literals instead of real
  // newlines, restore them so node-forge can parse the PEM.
  if (
    serviceAccount.private_key &&
    serviceAccount.private_key.includes('\\n')
  ) {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
  }

  return serviceAccount;
}

const serviceAccount = loadServiceAccount();

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const addProductBackend = require('./inventory/product/add_product_backend');
const getProductsServices = require('./purchases/get_products_services');
const createCashTransaction = require('./purchases/create_cash_transaction');
const createQrTransaction = require('./purchases/create_qr_transaction');
const verifyPayment = require('./purchases/verify_payment');
const verifyGooglePlayPurchase = require('./purchases/verify_google_play_purchase');
const privacyPolicy = require('./legal/privacy_policy');
const paystackWebhook = require('./webhooks/paystack');
const googlePlayWebhook = require('./webhooks/google_play');
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

// Paystack webhook must be registered before express.json() — it needs the raw body for
// HMAC signature verification (see webhooks/paystack.js, which applies express.raw() itself).
app.use('/webhooks/paystack', paystackWebhook);

app.use(express.json());

// Google Play RTDN arrives as a Pub/Sub push (plain JSON body, OIDC bearer auth) rather
// than an HMAC-signed payload, so — unlike Paystack — it can sit after express.json().
app.use('/webhooks/google-play', googlePlayWebhook);

app.use('/inventory/product', addProductBackend);
app.use('/purchases', getProductsServices);
app.use('/purchases', createCashTransaction);
app.use('/purchases', createQrTransaction);
app.use('/purchases', verifyPayment);
app.use('/purchases', verifyGooglePlayPurchase);
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

// Required by Google Play's Data safety declaration: a public URL users can use to
// request deletion of their account and associated data.
app.get('/delete-account', (req, res) => {
  res.set('Content-Type', 'text/html; charset=utf-8').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Delete Your AwehBiz Account</title>
  <style>
    body { font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif; max-width: 640px; margin: 48px auto; padding: 0 20px; color: #272A2F; line-height: 1.6; }
    h1 { font-size: 24px; }
    a { color: #7B61FF; }
  </style>
</head>
<body>
  <h1>Delete Your AwehBiz Account</h1>
  <p>To request deletion of your AwehBiz account and all associated data, email
    <a href="mailto:info@smart-builders.co.za">info@smart-builders.co.za</a> from the
    address registered on your account, with the subject line "Account Deletion Request".</p>
  <p>Please include your business name and registered email address so we can locate
    your account.</p>
  <p>We will process your request and permanently delete your account and associated
    data within 30 days.</p>
</body>
</html>`);
});

app.use('/privacy-policy', privacyPolicy);

app.post('/verify-token', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);

    // Check subscription status
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const userData = userDoc.data();
    const businessId = userData.businessId;

    if (businessId) {
      const businessDoc = await db.collection('businesses').doc(businessId).get();
      if (businessDoc.exists) {
        const businessData = businessDoc.data();
        const subscription = businessData.subscription || {};
        const subscriptionStatus = subscription.status || 'active';

        // Block login for invalid subscription states
        const blockedStatuses = ['expired', 'cancelled', 'payment_failed'];
        if (blockedStatuses.includes(subscriptionStatus)) {
          return res.status(403).json({
            success: false,
            error: `Subscription ${subscriptionStatus}. Please renew your subscription to access the system.`,
            subscriptionStatus,
          });
        }

        // Check if trial has expired
        if (subscription.trialEndDate) {
          const trialEnd = subscription.trialEndDate.toDate();
          const now = new Date();
          if (now > trialEnd && subscriptionStatus === 'active') {
            // Trial expired, check if subscription is still valid
            if (!subscription.expiresAt || new Date(subscription.expiresAt.toDate()) < now) {
              await db.collection('businesses').doc(businessId).update({
                'subscription.status': 'expired',
                'status': 'disabled',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
              return res.status(403).json({
                success: false,
                error: 'Trial period expired. Please subscribe to continue.',
                subscriptionStatus: 'expired',
              });
            }
          }
        }

        // Check if subscription has expired. Applies to 'active' and to
        // 'cancel_at_period_end' (a Play Billing cancellation that hasn't reached the end
        // of its paid period yet) — both should auto-expire once expiresAt passes.
        if (subscription.expiresAt) {
          const subscriptionEnd = subscription.expiresAt.toDate();
          const now = new Date();
          const stillWithinGrantedAccess =
            subscriptionStatus === 'active' || subscriptionStatus === 'cancel_at_period_end';
          if (now > subscriptionEnd && stillWithinGrantedAccess) {
            await db.collection('businesses').doc(businessId).update({
              'subscription.status': 'expired',
              'status': 'disabled',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return res.status(403).json({
              success: false,
              error: 'Subscription expired. Please renew to continue.',
              subscriptionStatus: 'expired',
            });
          }
        }
      }
    }

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