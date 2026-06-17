const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// GET /purchases/catalog
// Returns all active products and services for the authenticated user's business.
router.get('/catalog', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');

    if (!idToken) {
      return res.status(401).json({ error: 'Authorization token is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const businessId = userDoc.data()?.businessId;

    if (!businessId) {
      return res.status(400).json({ error: 'No business linked to this account' });
    }

    const businessRef = db.collection('businesses').doc(businessId);

    const [productsSnap, servicesSnap] = await Promise.all([
      businessRef.collection('products')
        .where('isActive', '==', true)
        .where('isDeleted', '==', false)
        .get(),
      businessRef.collection('services')
        .where('isActive', '==', true)
        .where('isDeleted', '==', false)
        .get(),
    ]);

    const products = productsSnap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: d.productId ?? doc.id,
        name: d.name,
        price: typeof d.sellingPrice === 'number' ? d.sellingPrice : parseFloat(d.sellingPrice) || 0,
        barcode: d.barcode ?? '',
        category: d.category ?? '',
        type: 'product',
      };
    });

    const services = servicesSnap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: d.serviceId ?? doc.id,
        name: d.name,
        price: typeof d.price === 'number' ? d.price : parseFloat(d.price) || 0,
        barcode: '',
        category: d.category ?? '',
        type: 'service',
      };
    });

    res.json({
      success: true,
      businessId,
      items: [...products, ...services],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
