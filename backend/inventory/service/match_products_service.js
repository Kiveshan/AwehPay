const admin = require('firebase-admin');
const { normalizeName, productResponse } = require('./inventory_helpers');

const db = admin.firestore();

async function matchProductsForBusiness({ businessId, products }) {
  const productsRef = db
    .collection('businesses')
    .doc(businessId)
    .collection('products');

  const matchedProducts = [];

  for (const product of products) {
    const barcode =
      typeof product.barcode === 'string' ? product.barcode.trim() : '';
    const nameLower = normalizeName(product.name);
    let matchDoc = null;

    if (barcode) {
      const barcodeSnapshot = await productsRef
        .where('barcode', '==', barcode)
        .where('isDeleted', '==', false)
        .limit(1)
        .get();

      if (!barcodeSnapshot.empty) {
        matchDoc = barcodeSnapshot.docs[0];
      }
    }

    if (!matchDoc && nameLower) {
      const nameSnapshot = await productsRef
        .where('nameLower', '==', nameLower)
        .where('isDeleted', '==', false)
        .limit(1)
        .get();

      if (!nameSnapshot.empty) {
        matchDoc = nameSnapshot.docs[0];
      } else {
        const fallbackSnapshot = await productsRef
          .where('isDeleted', '==', false)
          .get();

        const scannedWords = nameLower.split(/\W+/).filter((w) => w.length >= 4);

        matchDoc =
          fallbackSnapshot.docs.find((doc) => {
            const dbName = normalizeName(doc.data()?.name);
            if (!dbName) return false;
            if (dbName === nameLower) return true;
            if (dbName.includes(nameLower) || nameLower.includes(dbName)) return true;
            const dbWords = dbName.split(/\W+/).filter((w) => w.length >= 4);
            const overlapCount = scannedWords.filter((w) => dbWords.includes(w)).length;
            return overlapCount >= 2;
          }) || null;
      }
    }

    const matchData = matchDoc ? productResponse(matchDoc) : null;
    matchedProducts.push({
      ...product,
      isExistingProduct: Boolean(matchDoc),
      matchedProductId: matchDoc?.id || null,
      existingProduct: matchData,
    });
  }

  return matchedProducts;
}

module.exports = { matchProductsForBusiness };
