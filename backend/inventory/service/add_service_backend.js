const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

async function getBusinessId(idToken) {
  if (!idToken) {
    throw new Error('idToken is required');
  }

  const decodedToken = await auth.verifyIdToken(idToken);
  const userDoc = await db.collection('users').doc(decodedToken.uid).get();
  const businessId = userDoc.data()?.businessId;

  if (!businessId) {
    throw new Error('No business is linked to this account');
  }

  return businessId;
}

function validateServiceFields(name, category, durationMinutes, costPrice) {
  if (!name || !category) {
    return 'Service name and category are required';
  }

  if (!Number.isInteger(durationMinutes) || typeof costPrice !== 'number') {
    return 'Valid duration and cost price are required';
  }

  return null;
}

router.post('/list-services', async (req, res) => {
  try {
    const { idToken } = req.body;
    const businessId = await getBusinessId(idToken);

    const servicesSnapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('services')
      .where('isDeleted', '==', false)
      .get();

    const services = servicesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        serviceId: data.serviceId || doc.id,
        businessId: data.businessId || businessId,
        name: data.name || '',
        category: data.category || '',
        durationMinutes: data.durationMinutes || 0,
        costPrice: data.costPrice || 0,
        isActive: data.isActive !== false,
      };
    });

    res.json({
      success: true,
      services,
    });
  } catch (error) {
    res.status(error.message === 'idToken is required' ? 400 : 500).json({
      success: false,
      error: error.message,
    });
  }
});

router.post('/add-service', async (req, res) => {
  try {
    const {
      idToken,
      name,
      category,
      durationMinutes,
      costPrice,
    } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const validationError = validateServiceFields(name, category, durationMinutes, costPrice);
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const businessId = await getBusinessId(idToken);
    const businessRef = db.collection('businesses').doc(businessId);
    const serviceRef = businessRef.collection('services').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (transaction) => {
      transaction.set(serviceRef, {
        serviceId: serviceRef.id,
        businessId,
        name: name.trim(),
        category: category.trim(),
        durationMinutes,
        costPrice,
        description: '',
        imageUrl: '',
        isActive: true,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      });
      transaction.update(businessRef, {
        'totals.totalServices': admin.firestore.FieldValue.increment(1),
        updatedAt: now,
      });
    });

    res.status(201).json({
      success: true,
      serviceId: serviceRef.id,
      businessId,
      message: 'Service added successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

router.put('/update-service/:serviceId', async (req, res) => {
  try {
    const { serviceId } = req.params;
    const {
      idToken,
      name,
      category,
      durationMinutes,
      costPrice,
    } = req.body;

    if (!serviceId) {
      return res.status(400).json({ error: 'serviceId is required' });
    }

    const validationError = validateServiceFields(name, category, durationMinutes, costPrice);
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const businessId = await getBusinessId(idToken);
    const serviceRef = db
      .collection('businesses')
      .doc(businessId)
      .collection('services')
      .doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists || serviceDoc.data()?.isDeleted === true) {
      return res.status(404).json({ error: 'Service not found' });
    }

    await serviceRef.update({
      name: name.trim(),
      category: category.trim(),
      durationMinutes,
      costPrice,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      success: true,
      serviceId,
      businessId,
      message: 'Service updated successfully',
    });
  } catch (error) {
    res.status(error.message === 'idToken is required' ? 400 : 500).json({
      success: false,
      error: error.message,
    });
  }
});

router.delete('/delete-service/:serviceId', async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { idToken } = req.body;

    if (!serviceId) {
      return res.status(400).json({ error: 'serviceId is required' });
    }

    const businessId = await getBusinessId(idToken);
    const businessRef = db.collection('businesses').doc(businessId);
    const serviceRef = businessRef.collection('services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists || serviceDoc.data()?.isDeleted === true) {
      return res.status(404).json({ error: 'Service not found' });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (transaction) => {
      transaction.update(serviceRef, {
        isActive: false,
        isDeleted: true,
        updatedAt: now,
      });
      transaction.update(businessRef, {
        'totals.totalServices': admin.firestore.FieldValue.increment(-1),
        updatedAt: now,
      });
    });

    res.json({
      success: true,
      serviceId,
      businessId,
      message: 'Service deleted successfully',
    });
  } catch (error) {
    res.status(error.message === 'idToken is required' ? 400 : 500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
