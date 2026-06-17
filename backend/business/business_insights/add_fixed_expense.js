const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

async function getBusinessId(uid) {
  let userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    const q = await db.collection('users').where('uid', '==', uid).limit(1).get();
    if (q.empty) return null;
    userDoc = q.docs[0];
  }
  return userDoc.data()?.businessId ?? null;
}

// Adds a fixed expense
router.post('/add-fixed-expense', async (req, res) => {
  try {
    const { idToken, name, frequency, amount, description } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!name || !frequency || typeof amount !== 'number') {
      return res.status(400).json({ error: 'name, frequency, and a numeric amount are required' });
    }

    if (!['monthly', 'weekly'].includes(frequency)) {
      return res.status(400).json({ error: 'frequency must be "monthly" or "weekly"' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const businessId = await getBusinessId(decodedToken.uid);
    if (!businessId) return res.status(400).json({ error: 'No business is linked to this account' });

    const now = admin.firestore.FieldValue.serverTimestamp();
    const expenseRef = db.collection('businesses').doc(businessId).collection('expenses').doc();

    await expenseRef.set({
      expenseId: expenseRef.id,
      businessId,
      createdBy: decodedToken.uid,
      name: name.trim(),
      category: name.trim().toLowerCase(),
      description: description?.trim() ?? '',
      amount,
      currency: 'ZAR',
      frequency,
      isRecurring: true,
      type: 'fixed',
      expenseDate: now,
      createdAt: now,
      updatedAt: now,
    });

    res.status(201).json({
      success: true,
      expenseId: expenseRef.id,
      businessId,
      message: 'Fixed expense added successfully',
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Deletes an expenses
router.delete('/delete-fixed-expense', async (req, res) => {
  try {
    const { idToken, expenseId } = req.body;

    if (!idToken || !expenseId) {
      return res.status(400).json({ error: 'idToken and expenseId are required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const businessId = await getBusinessId(decodedToken.uid);
    if (!businessId) return res.status(400).json({ error: 'No business is linked to this account' });

    const expenseRef = db.collection('businesses').doc(businessId).collection('expenses').doc(expenseId);
    const expenseDoc = await expenseRef.get();

    if (!expenseDoc.exists) {
      return res.status(404).json({ error: 'Expense not found' });
    }

    await expenseRef.delete();

    res.status(200).json({ success: true, message: 'Fixed expense deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Receives expenses of type fixed for a business
router.get('/fixed-expenses', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');

    if (!idToken) {
      return res.status(400).json({ error: 'Authorization header with Bearer token is required' });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const businessId = await getBusinessId(decodedToken.uid);
    if (!businessId) return res.status(400).json({ error: 'No business is linked to this account' });

    const snapshot = await db
      .collection('businesses').doc(businessId)
      .collection('expenses')
      .where('type', '==', 'fixed')
      .get();

    const expenses = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        expenseId: data.expenseId,
        name: data.name,
        frequency: data.frequency,
        amount: data.amount,
        currency: data.currency,
        description: data.description,
      };
    });

    res.status(200).json({ success: true, expenses });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;