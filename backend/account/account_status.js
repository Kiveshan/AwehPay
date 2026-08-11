const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// Resolves the business a signed-in user owns, throwing an error carrying an
// HTTP status so route handlers can just forward it in their catch block.
async function loadOwnedBusiness(idToken) {
  const decodedToken = await auth.verifyIdToken(idToken);

  const userDoc = await db.collection('users').doc(decodedToken.uid).get();
  if (!userDoc.exists) {
    throw Object.assign(new Error('User not found'), { status: 404 });
  }

  const businessId = userDoc.data().businessId;
  if (!businessId) {
    throw Object.assign(new Error('No business associated with this account'), { status: 404 });
  }

  const businessRef = db.collection('businesses').doc(businessId);
  const businessDoc = await businessRef.get();
  if (!businessDoc.exists || businessDoc.data()?.ownerId !== decodedToken.uid) {
    throw Object.assign(new Error('Not authorized for this business'), { status: 403 });
  }

  return businessRef;
}

// POST /account/disable
// Self-service account disable, triggered from the app's Settings screen. Cancels
// the business's trial/subscription (so /verify-token blocks future sign-ins) and
// flags selfDisabled so /verify-token can tell the app to show the reactivation
// prompt instead of the generic "subscription expired" paywall.
router.post('/disable', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'idToken is required' });

    const businessRef = await loadOwnedBusiness(idToken);

    await businessRef.update({
      status: 'disabled',
      selfDisabled: true,
      selfDisabledAt: admin.firestore.FieldValue.serverTimestamp(),
      'subscription.status': 'cancelled',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true });
  } catch (error) {
    res.status(error.status || 500).json({ success: false, error: error.message });
  }
});

// POST /account/enable
// Clears the selfDisabled flag so the account no longer shows the reactivation
// prompt. This does NOT restore access by itself — the subscription stays
// 'cancelled', so the next /verify-token call routes the user to the normal
// subscription paywall where they must choose and pay for a plan.
router.post('/enable', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'idToken is required' });

    const businessRef = await loadOwnedBusiness(idToken);

    await businessRef.update({
      status: 'active',
      selfDisabled: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true });
  } catch (error) {
    res.status(error.status || 500).json({ success: false, error: error.message });
  }
});

module.exports = router;
