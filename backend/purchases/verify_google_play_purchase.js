const express = require('express');
const admin = require('firebase-admin');
const { getSubscriptionPurchase, acknowledgeSubscriptionPurchase } = require('../google_play/google_play_client');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

const ACTIVE_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
]);

// POST /purchases/verify-google-play
// Body: { purchaseToken, productId, basePlanId }
// Mirrors the verify-then-write pattern in verify_payment.js, but for Play Billing:
// the client only tells us a purchase happened; this endpoint is the only place that
// actually grants entitlement, by re-checking the purchase directly with Google.
router.post('/verify-google-play', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(401).json({ error: 'Authorization token is required' });

    const { purchaseToken, productId, basePlanId } = req.body;
    if (!purchaseToken || !productId) {
      return res.status(400).json({ error: 'purchaseToken and productId are required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    const businessId = userDoc.data()?.businessId;
    if (!businessId) return res.status(400).json({ error: 'No business linked to this account' });

    // Anti-replay: this purchase token must not already be attached to a different business.
    const tokenOwnerQuery = await db
      .collection('businesses')
      .where('subscription.purchaseToken', '==', purchaseToken)
      .limit(1)
      .get();
    if (!tokenOwnerQuery.empty && tokenOwnerQuery.docs[0].id !== businessId) {
      return res.status(409).json({
        success: false,
        error: 'This purchase is already linked to a different business account',
      });
    }

    const purchase = await getSubscriptionPurchase(purchaseToken);
    const subscriptionState = purchase.subscriptionState;

    if (!ACTIVE_STATES.has(subscriptionState)) {
      return res.status(402).json({
        success: false,
        error: `Purchase is not active (state: ${subscriptionState})`,
        subscriptionState,
      });
    }

    const lineItem = purchase.lineItems?.find((item) => item.productId === productId) || purchase.lineItems?.[0];
    if (!lineItem) {
      return res.status(400).json({ error: 'No matching line item on this purchase' });
    }

    const resolvedBasePlanId = lineItem.offerDetails?.basePlanId || basePlanId || null;

    // Map the Play product/base plan back to an AwehBiz tier so we know what to grant.
    const tierQuery = await db
      .collection('subscriptionTiers')
      .where('playProductId', '==', productId)
      .limit(1)
      .get();
    if (tierQuery.empty) {
      return res.status(400).json({ error: `No subscription tier is mapped to product ${productId}` });
    }
    const tierDoc = tierQuery.docs[0];
    const tier = tierDoc.data();

    const expiresAt = lineItem.expiryTime ? new Date(lineItem.expiryTime) : null;
    const startedAt = purchase.startTime ? new Date(purchase.startTime) : new Date();

    const subscriptionData = {
      tierId: tierDoc.id,
      tierName: tier.name || '',
      status: 'active',
      platform: 'google_play',
      purchaseToken,
      productId,
      basePlanId: resolvedBasePlanId,
      startedAt: admin.firestore.Timestamp.fromDate(startedAt),
      expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
      nextBillingDate: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
      trialEndDate: null,
      price: typeof tier.price === 'number' ? tier.price : 0,
      currency: tier.currency || 'ZAR',
      billingPeriod: tier.billingPeriod || 'monthly',
    };

    await db.collection('businesses').doc(businessId).update({
      subscription: subscriptionData,
      status: 'active',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (purchase.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING') {
      await acknowledgeSubscriptionPurchase(purchaseToken, productId);
    }

    res.json({ success: true, subscriptionState, tierId: tierDoc.id });
  } catch (error) {
    console.error('verify_google_play_purchase error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data?.error?.message || error.message,
    });
  }
});

module.exports = router;
