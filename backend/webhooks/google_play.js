const express = require('express');
const admin = require('firebase-admin');
const { OAuth2Client } = require('google-auth-library');
const { getSubscriptionPurchase } = require('../google_play/google_play_client');

const router = express.Router();
const db = admin.firestore();
const oidcClient = new OAuth2Client();

// Google Play delivers Real-time Developer Notifications (RTDN) via a Pub/Sub PUSH
// subscription, not a direct webhook — the request body is a Pub/Sub envelope
// ({ message: { data: base64, ... }, subscription }), and auth is an OIDC bearer token
// Pub/Sub attaches to the request (not an HMAC/signature header). Both of these differ
// from the legacy flat-JSON-plus-signature shape this file previously assumed.
//
// Configure PUBSUB_PUSH_AUDIENCE (the exact push endpoint URL registered with Pub/Sub)
// and PUBSUB_PUSH_SERVICE_ACCOUNT_EMAIL (the service account the push subscription
// authenticates as) once the Pub/Sub push subscription is created (see Play Console ->
// Monetization setup -> RTDN, and GCP Pub/Sub push subscription config).
async function verifyPushRequest(authorizationHeader) {
  const audience = process.env.PUBSUB_PUSH_AUDIENCE;
  const expectedEmail = process.env.PUBSUB_PUSH_SERVICE_ACCOUNT_EMAIL;
  if (!audience || !expectedEmail) {
    throw new Error(
      'PUBSUB_PUSH_AUDIENCE and PUBSUB_PUSH_SERVICE_ACCOUNT_EMAIL must be set to verify RTDN push requests'
    );
  }

  const token = authorizationHeader?.replace('Bearer ', '');
  if (!token) throw new Error('Missing Authorization bearer token');

  const ticket = await oidcClient.verifyIdToken({ idToken: token, audience });
  const payload = ticket.getPayload();
  if (payload.email !== expectedEmail || !payload.email_verified) {
    throw new Error('Unexpected push subscription identity');
  }
}

// Numeric RTDN notification types (SubscriptionNotification.notificationType) —
// Google Play's actual enum, not the descriptive strings the old placeholder compared against.
const NOTIFICATION_TYPE = {
  SUBSCRIPTION_RECOVERED: 1,
  SUBSCRIPTION_RENEWED: 2,
  SUBSCRIPTION_CANCELED: 3,
  SUBSCRIPTION_PURCHASED: 4,
  SUBSCRIPTION_ON_HOLD: 5,
  SUBSCRIPTION_IN_GRACE_PERIOD: 6,
  SUBSCRIPTION_RESTARTED: 7,
  SUBSCRIPTION_PRICE_CHANGE_CONFIRMED: 8,
  SUBSCRIPTION_DEFERRED: 9,
  SUBSCRIPTION_PAUSED: 10,
  SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED: 11,
  SUBSCRIPTION_REVOKED: 12,
  SUBSCRIPTION_EXPIRED: 13,
};

router.post('/google-play', async (req, res) => {
  try {
    await verifyPushRequest(req.headers['authorization']);
  } catch (err) {
    console.error('Google Play RTDN auth failed:', err.message);
    return res.status(401).json({ error: 'Invalid push request' });
  }

  try {
    const messageData = req.body?.message?.data;
    if (!messageData) {
      // Ack (2xx) unknown/empty envelopes so Pub/Sub doesn't retry-storm on malformed input.
      return res.status(200).json({ success: true, ignored: true });
    }

    const notification = JSON.parse(Buffer.from(messageData, 'base64').toString('utf8'));
    const subscriptionNotification = notification.subscriptionNotification;

    if (!subscriptionNotification) {
      // Other RTDN types (e.g. testNotification, oneTimeProductNotification) — nothing to do.
      return res.status(200).json({ success: true, ignored: true });
    }

    const { subscriptionId, purchaseToken, notificationType } = subscriptionNotification;

    const businessQuery = await db
      .collection('businesses')
      .where('subscription.purchaseToken', '==', purchaseToken)
      .limit(1)
      .get();

    if (businessQuery.empty) {
      // Fragile fallback only — multiple businesses can share a tierId. Log loudly rather
      // than silently act on a possibly-wrong match.
      console.error(
        `Google Play RTDN: no business found for purchaseToken (subscriptionId=${subscriptionId}). ` +
          'This purchase was likely not made through verify-google-play first.'
      );
      // Still 200 so Pub/Sub doesn't retry indefinitely for a purchase we'll never resolve.
      return res.status(200).json({ success: true, businessFound: false });
    }

    await handleSubscriptionEvent(businessQuery.docs[0], notificationType, purchaseToken);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Google Play webhook error:', error);
    // 500 so Pub/Sub retries — this path is for our own processing failures, not bad input.
    res.status(500).json({ error: error.message });
  }
});

async function handleSubscriptionEvent(businessDoc, notificationType, purchaseToken) {
  const businessId = businessDoc.id;
  const updateData = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // RTDN only signals "something changed" — re-fetch the real state/expiry from Play
  // rather than guessing, per Google's documented RTDN handling pattern.
  let purchase = null;
  const needsRefetch = [
    NOTIFICATION_TYPE.SUBSCRIPTION_RECOVERED,
    NOTIFICATION_TYPE.SUBSCRIPTION_RENEWED,
    NOTIFICATION_TYPE.SUBSCRIPTION_PURCHASED,
    NOTIFICATION_TYPE.SUBSCRIPTION_RESTARTED,
    NOTIFICATION_TYPE.SUBSCRIPTION_DEFERRED,
  ].includes(notificationType);

  if (needsRefetch) {
    purchase = await getSubscriptionPurchase(purchaseToken);
  }

  switch (notificationType) {
    case NOTIFICATION_TYPE.SUBSCRIPTION_RECOVERED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_RENEWED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_PURCHASED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_RESTARTED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_DEFERRED: {
      updateData['subscription.status'] = 'active';
      updateData.status = 'active';
      const expiryTime = purchase?.lineItems?.[0]?.expiryTime;
      if (expiryTime) {
        updateData['subscription.expiresAt'] = admin.firestore.Timestamp.fromDate(new Date(expiryTime));
        updateData['subscription.nextBillingDate'] = admin.firestore.Timestamp.fromDate(new Date(expiryTime));
      }
      break;
    }

    case NOTIFICATION_TYPE.SUBSCRIPTION_CANCELED:
      // Play cancellations retain access through the already-paid period — do not revoke
      // immediately. subscription.expiresAt (set at purchase/renewal time) still governs
      // access; /verify-token's expiry check disables the business once that date passes.
      updateData['subscription.status'] = 'canceled';
      break;

    case NOTIFICATION_TYPE.SUBSCRIPTION_ON_HOLD:
      updateData['subscription.status'] = 'payment_failed';
      updateData.status = 'disabled';
      break;

    case NOTIFICATION_TYPE.SUBSCRIPTION_IN_GRACE_PERIOD:
      // Keep access during the grace period; status stays whatever it already was (active).
      break;

    case NOTIFICATION_TYPE.SUBSCRIPTION_REVOKED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_EXPIRED:
      updateData['subscription.status'] = 'expired';
      updateData.status = 'disabled';
      break;

    case NOTIFICATION_TYPE.SUBSCRIPTION_PAUSED:
      updateData['subscription.status'] = 'paused';
      updateData.status = 'disabled';
      break;

    case NOTIFICATION_TYPE.SUBSCRIPTION_PRICE_CHANGE_CONFIRMED:
    case NOTIFICATION_TYPE.SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED:
      // Informational only — no entitlement change.
      return;

    default:
      console.log('Unhandled Google Play notification type:', notificationType);
      return;
  }

  await db.collection('businesses').doc(businessId).update(updateData);
  console.log(`Updated business ${businessId} for Google Play notification type: ${notificationType}`);
}

module.exports = router;
