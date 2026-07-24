const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

async function verifyAdmin(idToken) {
  const decodedToken = await auth.verifyIdToken(idToken);
  const uid = decodedToken.uid;
  const email = decodedToken.email;

  let snapshot = await db
    .collection('adminUsers')
    .where('uid', '==', uid)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return { uid, role: 'admin' };
  }

  if (email) {
    snapshot = await db
      .collection('adminUsers')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      return { uid, role: 'admin' };
    }
  }

  throw new Error('Forbidden: admin access required');
}

router.post('/list', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    await verifyAdmin(idToken);

    const snapshot = await db
      .collection('businesses')
      .orderBy('createdAt', 'desc')
      .get();

    const businesses = snapshot.docs.map((doc) => ({
      businessId: doc.id,
      ...doc.data(),
    }));

    res.json({ success: true, businesses });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/details', async (req, res) => {
  try {
    const { idToken, businessId } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!businessId) {
      return res.status(400).json({ error: 'businessId is required' });
    }

    await verifyAdmin(idToken);

    const doc = await db.collection('businesses').doc(businessId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Business not found' });
    }

    res.json({ success: true, business: { businessId: doc.id, ...doc.data() } });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/bank-accounts', async (req, res) => {
  try {
    const { idToken, businessId } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!businessId) {
      return res.status(400).json({ error: 'businessId is required' });
    }

    await verifyAdmin(idToken);

    const snapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('bankAccounts')
      .get();

    const accounts = snapshot.docs.map((doc) => ({
      bankAccountId: doc.id,
      ...doc.data(),
    }));

    res.json({ success: true, accounts });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/user', async (req, res) => {
  try {
    const { idToken, uid } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!uid) {
      return res.status(400).json({ error: 'uid is required' });
    }

    await verifyAdmin(idToken);

    const doc = await db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ success: true, user: { uid: doc.id, ...doc.data() } });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/disable', async (req, res) => {
  try {
    const { idToken, businessId, disabled } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!businessId) {
      return res.status(400).json({ error: 'businessId is required' });
    }

    if (typeof disabled !== 'boolean') {
      return res.status(400).json({ error: 'disabled (boolean) is required' });
    }

    const adminUser = await verifyAdmin(idToken);

    const doc = await db.collection('businesses').doc(businessId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Business not found' });
    }

    const updateData = {
      status: disabled ? 'disabled' : 'active',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('businesses').doc(businessId).update(updateData);

    res.json({ success: true, disabled: disabled });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/subscription/override', async (req, res) => {
  try {
    const { idToken, businessId, subscriptionStatus, extendTrialDays } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!businessId) {
      return res.status(400).json({ error: 'businessId is required' });
    }

    if (!subscriptionStatus) {
      return res.status(400).json({ error: 'subscriptionStatus is required' });
    }

    const validStatuses = ['active', 'pending_payment', 'expired', 'cancelled', 'payment_failed'];
    if (!validStatuses.includes(subscriptionStatus)) {
      return res.status(400).json({ error: `Invalid subscriptionStatus. Must be one of: ${validStatuses.join(', ')}` });
    }

    const adminUser = await verifyAdmin(idToken);

    const doc = await db.collection('businesses').doc(businessId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Business not found' });
    }

    const updateData = {
      'subscription.status': subscriptionStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Update business status based on subscription status
    if (subscriptionStatus === 'active') {
      updateData.status = 'active';
    } else if (['expired', 'cancelled', 'payment_failed'].includes(subscriptionStatus)) {
      updateData.status = 'disabled';
    }

    // Extend trial if requested
    if (extendTrialDays && subscriptionStatus === 'active') {
      const subscription = doc.data().subscription || {};
      const currentTrialEnd = subscription.trialEndDate;
      const newTrialEnd = currentTrialEnd 
        ? currentTrialEnd.toDate() 
        : new Date();
      newTrialEnd.setDate(newTrialEnd.getDate() + extendTrialDays);
      updateData['subscription.trialEndDate'] = admin.firestore.Timestamp.fromDate(newTrialEnd);
    }

    await db.collection('businesses').doc(businessId).update(updateData);

    res.json({ 
      success: true, 
      message: `Subscription status updated to ${subscriptionStatus}`,
      subscriptionStatus 
    });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/:businessId/subscription', async (req, res) => {
  try {
    const { idToken } = req.body;
    const { businessId } = req.params;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!businessId) {
      return res.status(400).json({ error: 'businessId is required' });
    }

    await verifyAdmin(idToken);

    const doc = await db.collection('businesses').doc(businessId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Business not found' });
    }

    const businessData = doc.data();
    const subscription = businessData.subscription || {};

    res.json({ 
      success: true, 
      subscription: {
        status: subscription.status || 'active',
        startedAt: subscription.startedAt,
        expiresAt: subscription.expiresAt,
        trialEndDate: subscription.trialEndDate,
        tier: subscription,
      }
    });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
