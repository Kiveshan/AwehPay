const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

async function verifyAdmin(idToken) {
  const decodedToken = await auth.verifyIdToken(idToken);
  return { uid: decodedToken.uid, role: decodedToken.role || 'admin' };
}

router.get('/list', async (req, res) => {
  try {
    const snapshot = await db
      .collection('subscriptionTiers')
      .orderBy('displayOrder')
      .get();

    const tiers = snapshot.docs.map((doc) => ({
      tierId: doc.id,
      ...doc.data(),
    }));

    res.json({ success: true, tiers });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/:tierId', async (req, res) => {
  try {
    const { tierId } = req.params;
    const doc = await db.collection('subscriptionTiers').doc(tierId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Tier not found' });
    }

    res.json({ success: true, tier: { tierId: doc.id, ...doc.data() } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/create', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const adminUser = await verifyAdmin(idToken);

    const {
      name,
      code,
      price,
      currency,
      billingPeriod,
      setupFee,
      description,
      displayOrder,
      isActive,
      isRecommended,
      features,
      limits,
    } = req.body;

    if (!name || !code) {
      return res.status(400).json({ error: 'Name and code are required' });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    const tierRef = db.collection('subscriptionTiers').doc();
    await tierRef.set({
      tierId: tierRef.id,
      name: name.trim(),
      code: code.trim(),
      price: typeof price === 'number' ? price : 0,
      currency: currency || 'ZAR',
      billingPeriod: billingPeriod || 'monthly',
      setupFee: typeof setupFee === 'number' ? setupFee : 0,
      description: description || '',
      displayOrder: typeof displayOrder === 'number' ? displayOrder : 0,
      isActive: typeof isActive === 'boolean' ? isActive : true,
      isRecommended: typeof isRecommended === 'boolean' ? isRecommended : false,
      features: Array.isArray(features) ? features : [],
      limits: limits || {},
      createdBy: adminUser.uid,
      updatedBy: adminUser.uid,
      createdAt: now,
      updatedAt: now,
    });

    res.status(201).json({
      success: true,
      tierId: tierRef.id,
      message: 'Subscription tier created successfully',
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.put('/:tierId', async (req, res) => {
  try {
    const { idToken } = req.body;
    const { tierId } = req.params;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const adminUser = await verifyAdmin(idToken);

    const {
      name,
      code,
      price,
      currency,
      billingPeriod,
      setupFee,
      description,
      displayOrder,
      isActive,
      isRecommended,
      features,
      limits,
    } = req.body;

    const tierRef = db.collection('subscriptionTiers').doc(tierId);
    const tierDoc = await tierRef.get();

    if (!tierDoc.exists) {
      return res.status(404).json({ success: false, error: 'Tier not found' });
    }

    const updateData = {
      updatedBy: adminUser.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (name !== undefined) updateData.name = name.trim();
    if (code !== undefined) updateData.code = code.trim();
    if (price !== undefined) updateData.price = price;
    if (currency !== undefined) updateData.currency = currency;
    if (billingPeriod !== undefined) updateData.billingPeriod = billingPeriod;
    if (setupFee !== undefined) updateData.setupFee = setupFee;
    if (description !== undefined) updateData.description = description;
    if (displayOrder !== undefined) updateData.displayOrder = displayOrder;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (isRecommended !== undefined) updateData.isRecommended = isRecommended;
    if (features !== undefined) updateData.features = features;
    if (limits !== undefined) updateData.limits = limits;

    await tierRef.update(updateData);

    res.json({
      success: true,
      tierId,
      message: 'Subscription tier updated successfully',
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
