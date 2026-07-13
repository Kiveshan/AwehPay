const express = require('express');
const admin = require('firebase-admin');
const crypto = require('crypto');

const router = express.Router();
const db = admin.firestore();

// Google Play Developer API integration would be needed here
// For now, this is a placeholder for the webhook structure

// Verify webhook signature (Google Play uses RSA public key verification)
function verifyWebhookSignature(signature, payload, publicKey) {
  // TODO: Implement RSA signature verification
  // This requires the Google Play public key from the Play Console
  return true; // Placeholder - always return true for now
}

// Handle subscription events from Google Play
router.post('/google-play', async (req, res) => {
  try {
    const signature = req.headers['authorization'];
    const payload = req.body;

    // Verify webhook signature
    // const publicKey = process.env.GOOGLE_PLAY_PUBLIC_KEY;
    // if (!verifyWebhookSignature(signature, payload, publicKey)) {
    //   return res.status(401).json({ error: 'Invalid signature' });
    // }

    const { notificationType, subscriptionNotification, eventTimeMillis } = payload;

    if (!subscriptionNotification) {
      return res.status(400).json({ error: 'Missing subscription notification' });
    }

    const { subscriptionId, purchaseToken } = subscriptionNotification;

    // Find business by purchase token or subscription ID
    const businessQuery = await db
      .collection('businesses')
      .where('subscription.purchaseToken', '==', purchaseToken)
      .limit(1)
      .get();

    if (businessQuery.empty) {
      // Try to find by subscription ID
      const businessBySubId = await db
        .collection('businesses')
        .where('subscription.tierId', '==', subscriptionId)
        .limit(1)
        .get();

      if (businessBySubId.empty) {
        console.log('Business not found for subscription:', subscriptionId);
        return res.status(404).json({ error: 'Business not found' });
      }

      const businessDoc = businessBySubId.docs[0];
      await handleSubscriptionEvent(businessDoc, notificationType, eventTimeMillis);
    } else {
      const businessDoc = businessQuery.docs[0];
      await handleSubscriptionEvent(businessDoc, notificationType, eventTimeMillis);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Google Play webhook error:', error);
    res.status(500).json({ error: error.message });
  }
});

async function handleSubscriptionEvent(businessDoc, notificationType, eventTimeMillis) {
  const businessId = businessDoc.id;
  const updateData = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  switch (notificationType) {
    case 'SUBSCRIPTION_PURCHASED':
    case 'SUBSCRIPTION_RENEWED':
      // Subscription is active
      updateData['subscription.status'] = 'active';
      updateData.status = 'active';
      updateData['subscription.expiresAt'] = calculateExpiryDate(eventTimeMillis);
      break;

    case 'SUBSCRIPTION_CANCELLED':
      // Subscription cancelled - disable business immediately
      updateData['subscription.status'] = 'cancelled';
      updateData.status = 'disabled';
      break;

    case 'SUBSCRIPTION_EXPIRED':
      // Subscription expired - disable business
      updateData['subscription.status'] = 'expired';
      updateData.status = 'disabled';
      break;

    case 'SUBSCRIPTION_ON_HOLD':
      // Payment failed - revoke access
      updateData['subscription.status'] = 'payment_failed';
      updateData.status = 'disabled';
      break;

    case 'SUBSCRIPTION_IN_PRICE_CHANGE_PENDING':
      // Price change notification - no action needed
      break;

    case 'SUBSCRIPTION_RESTARTED':
      // Subscription restarted after cancellation
      updateData['subscription.status'] = 'active';
      updateData.status = 'active';
      updateData['subscription.expiresAt'] = calculateExpiryDate(eventTimeMillis);
      break;

    default:
      console.log('Unknown notification type:', notificationType);
      return;
  }

  await db.collection('businesses').doc(businessId).update(updateData);
  console.log(`Updated business ${businessId} for event: ${notificationType}`);
}

function calculateExpiryDate(eventTimeMillis) {
  // Calculate expiry based on billing period
  // This would need to be customized based on the subscription tier
  const eventTime = new Date(parseInt(eventTimeMillis));
  const expiryDate = new Date(eventTime);
  expiryDate.setMonth(expiryDate.getMonth() + 1); // Default to 1 month
  return admin.firestore.Timestamp.fromDate(expiryDate);
}

module.exports = router;
