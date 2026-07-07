const admin = require('firebase-admin');

async function resolveBusinessId({ auth, db, idToken }) {
  const decodedToken = await auth.verifyIdToken(idToken);
  const userDoc = await db.collection('users').doc(decodedToken.uid).get();
  const businessId = userDoc.data()?.businessId;

  if (!businessId) {
    throw new Error('No business is linked to this account');
  }

  return businessId;
}

// Like resolveBusinessId but also returns the uid.
async function resolveBusinessContext({ auth, db, idToken }) {
  const decodedToken = await auth.verifyIdToken(idToken);
  const uid = decodedToken.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const businessId = userDoc.data()?.businessId;

  if (!businessId) {
    throw new Error('No business is linked to this account');
  }

  return { businessId, uid };
}

function normalizeName(name) {
  return typeof name === 'string' ? name.trim().toLowerCase() : '';
}

function productResponse(doc) {
  return { productId: doc.id, ...doc.data() };
}

function serverTimestamp() {
  return admin.firestore.FieldValue.serverTimestamp();
}

module.exports = {
  resolveBusinessId,
  resolveBusinessContext,
  normalizeName,
  productResponse,
  serverTimestamp,
};
