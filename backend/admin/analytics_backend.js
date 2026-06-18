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

router.post('/summary', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    await verifyAdmin(idToken);

    const [
      businessesSnap,
      usersSnap,
      tiersSnap,
    ] = await Promise.all([
      db.collection('businesses').count().get(),
      db.collection('users').count().get(),
      db.collection('subscriptionTiers').count().get(),
    ]);

    // Fetch tiers and businesses for subscriber counts and status breakdown
    const [allTiersSnap, allBusinessesSnap] = await Promise.all([
      db.collection('subscriptionTiers').get(),
      db.collection('businesses').get(),
    ]);

    const tierMap = new Map();
    allTiersSnap.docs.forEach((doc) => {
      const data = doc.data();
      tierMap.set(doc.id, {
        tierId: doc.id,
        tierName: data.name || data.code || doc.id,
        code: data.code || '',
      });
    });

    const subscribersPerTier = new Map();
    let activeBusinesses = 0;
    let inactiveBusinesses = 0;

    allBusinessesSnap.docs.forEach((doc) => {
      const data = doc.data();
      const tierId = data.subscription?.tierId;
      if (tierId) {
        subscribersPerTier.set(tierId, (subscribersPerTier.get(tierId) || 0) + 1);
      }

      if (data.status === 'active') {
        activeBusinesses++;
      } else {
        inactiveBusinesses++;
      }
    });

    const tierSubscribers = [];
    tierMap.forEach((tier, tierId) => {
      tierSubscribers.push({
        tierId,
        tierName: tier.tierName,
        code: tier.code,
        subscriberCount: subscribersPerTier.get(tierId) || 0,
      });
    });

    // Also sort by subscriber count descending
    tierSubscribers.sort((a, b) => b.subscriberCount - a.subscriberCount);

    res.json({
      success: true,
      summary: {
        totalBusinesses: businessesSnap.data().count,
        totalUsers: usersSnap.data().count,
        totalSubscriptionTiers: tiersSnap.data().count,
        activeBusinesses,
        inactiveBusinesses,
        tierSubscribers,
      },
    });
  } catch (error) {
    if (error.message === 'Forbidden: admin access required') {
      return res.status(403).json({ success: false, error: error.message });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
