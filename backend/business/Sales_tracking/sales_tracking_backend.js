const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

// ── Helpers ─────────────────────────────────────────────────────

async function getBusinessId(idToken) {
  if (!idToken) {
    throw new Error('idToken is required');
  }

  const decodedToken = await auth.verifyIdToken(idToken);
  let userDoc = await db.collection('users').doc(decodedToken.uid).get();
  if (!userDoc.exists) {
    const q = await db.collection('users').where('uid', '==', decodedToken.uid).limit(1).get();
    if (q.empty) throw new Error('User profile not found');
    userDoc = q.docs[0];
  }
  const businessId = userDoc.data()?.businessId;
  if (!businessId) throw new Error('No business is linked to this account');

  return { businessId, uid: decodedToken.uid };
}

function ts(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

function startOfDay(d) {
  const x = new Date(d); x.setUTCHours(0, 0, 0, 0); return ts(x);
}

function endOfDay(d) {
  const x = new Date(d); x.setUTCHours(23, 59, 59, 999); return ts(x);
}

function formatDateKey(d) {
  const x = new Date(d);
  const y = x.getUTCFullYear();
  const m = String(x.getUTCMonth() + 1).padStart(2, '0');
  const day = String(x.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// ── 1. Record a sale ────────────────────────────────────────────

router.post('/record-sale', async (req, res) => {
  try {
    const {
      idToken,
      items,
      paymentMethod,
      subtotal,
      taxAmount = 0,
      discountAmount = 0,
      totalAmount,
      customerName = '',
      customerPhoneNumber = '',
      customerEmail = '',
      notes = '',
    } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'At least one item is required' });
    }

    if (!['cash', 'digital', 'qr', 'card', 'eft'].includes(paymentMethod)) {
      return res.status(400).json({ error: 'Invalid payment method' });
    }

    if (typeof subtotal !== 'number' || typeof totalAmount !== 'number') {
      return res.status(400).json({ error: 'Valid subtotal and totalAmount are required' });
    }

    const { businessId, uid } = await getBusinessId(idToken);
    const businessRef = db.collection('businesses').doc(businessId);
    const now = admin.firestore.FieldValue.serverTimestamp();
    const saleDate = new Date();

    const transactionRef = businessRef.collection('transactions').doc();
    const dateKey = formatDateKey(saleDate);
    const summaryRef = businessRef.collection('salesSummaries').doc(`daily_${dateKey}`);

    // Build transaction items with totalPrice
    const transactionItems = items.map((item) => ({
      itemId: item.itemId || '',
      itemType: item.itemType || 'product',
      name: item.name || 'Unknown',
      quantity: Number(item.quantity) || 1,
      unitPrice: Number(item.unitPrice) || 0,
      totalPrice: Number(item.totalPrice) || (Number(item.unitPrice) * Number(item.quantity)),
    }));

    await db.runTransaction(async (t) => {
      // 1. Read all product docs and the summary doc inside the transaction
      const stockUpdates = [];
      for (const item of transactionItems) {
        if (item.itemType === 'product' && item.itemId) {
          const productRef = businessRef.collection('products').doc(item.itemId);
          const productDoc = await t.get(productRef);
          if (productDoc.exists && productDoc.data().isDeleted !== true) {
            const currentStock = productDoc.data().stockQuantity || 0;
            const newQuantity = Math.max(0, currentStock - item.quantity);
            stockUpdates.push({
              productRef,
              productId: item.itemId,
              productName: productDoc.data().name || item.name,
              currentStock,
              newQuantity,
              quantity: item.quantity,
            });
          }
        }
      }

      const summaryDoc = await t.get(summaryRef);
      const existingSummary = summaryDoc.exists;

      // 2. Create transaction
      t.set(transactionRef, {
        transactionId: transactionRef.id,
        businessId,
        customerName: customerName.trim(),
        customerPhoneNumber: customerPhoneNumber.trim(),
        customerEmail: customerEmail.trim(),
        type: 'sale',
        status: 'completed',
        paymentMethod,
        currency: 'ZAR',
        subtotal,
        taxAmount,
        discountAmount,
        totalAmount,
        items: transactionItems,
        notes: notes.trim(),
        createdBy: uid,
        saleDate: ts(saleDate),
        createdAt: now,
        updatedAt: now,
        completedAt: now,
      });

      // 3. Update business totals
      const totalsUpdate = {
        'totals.totalSales': admin.firestore.FieldValue.increment(totalAmount),
        'totals.totalTransactions': admin.firestore.FieldValue.increment(1),
        updatedAt: now,
      };
      if (paymentMethod === 'cash') {
        totalsUpdate['totals.totalCashSales'] = admin.firestore.FieldValue.increment(totalAmount);
      } else {
        totalsUpdate['totals.totalDigitalSales'] = admin.firestore.FieldValue.increment(totalAmount);
      }
      t.update(businessRef, totalsUpdate);

      // 4. Update product stock and create stock movements
      for (const stock of stockUpdates) {
        t.update(stock.productRef, {
          stockQuantity: stock.newQuantity,
          updatedAt: now,
        });

        const movementRef = businessRef.collection('stockMovements').doc();
        t.set(movementRef, {
          movementId: movementRef.id,
          businessId,
          productId: stock.productId,
          productName: stock.productName,
          type: 'sale',
          quantity: stock.quantity,
          previousQuantity: stock.currentStock,
          newQuantity: stock.newQuantity,
          reason: `Sale transaction ${transactionRef.id}`,
          referenceType: 'transaction',
          referenceId: transactionRef.id,
          createdBy: uid,
          createdAt: now,
        });
      }

      // 5. Upsert daily sales summary
      const summaryData = {
        summaryId: `daily_${dateKey}`,
        businessId,
        periodType: 'daily',
        date: dateKey,
        year: saleDate.getFullYear(),
        month: saleDate.getMonth() + 1,
        day: saleDate.getDate(),
        periodStart: startOfDay(saleDate),
        periodEnd: endOfDay(saleDate),
        updatedAt: now,
      };

      if (!existingSummary) {
        summaryData.createdAt = now;
        summaryData.totalSales = totalAmount;
        summaryData.totalTransactions = 1;
        summaryData.totalCashSales = paymentMethod === 'cash' ? totalAmount : 0;
        summaryData.totalDigitalSales = paymentMethod !== 'cash' ? totalAmount : 0;
        summaryData.totalRefunds = 0;
        summaryData.totalExpenses = 0;
        summaryData.netRevenue = totalAmount;
        summaryData.totals = {
          grossSales: totalAmount,
          netSales: totalAmount,
          cashSales: paymentMethod === 'cash' ? totalAmount : 0,
          digitalSales: paymentMethod !== 'cash' ? totalAmount : 0,
          refunds: 0,
          expenses: 0,
          netProfit: totalAmount,
          transactionCount: 1,
          cashTransactionCount: paymentMethod === 'cash' ? 1 : 0,
          digitalTransactionCount: paymentMethod !== 'cash' ? 1 : 0,
          productsSoldCount: transactionItems.filter(i => i.itemType === 'product').reduce((s, i) => s + i.quantity, 0),
          servicesSoldCount: transactionItems.filter(i => i.itemType === 'service').reduce((s, i) => s + i.quantity, 0),
        };
        t.set(summaryRef, summaryData);
      } else {
        t.update(summaryRef, {
          totalSales: admin.firestore.FieldValue.increment(totalAmount),
          totalTransactions: admin.firestore.FieldValue.increment(1),
          totalCashSales: admin.firestore.FieldValue.increment(paymentMethod === 'cash' ? totalAmount : 0),
          totalDigitalSales: admin.firestore.FieldValue.increment(paymentMethod !== 'cash' ? totalAmount : 0),
          netRevenue: admin.firestore.FieldValue.increment(totalAmount),
          updatedAt: now,
          'totals.grossSales': admin.firestore.FieldValue.increment(totalAmount),
          'totals.netSales': admin.firestore.FieldValue.increment(totalAmount),
          'totals.cashSales': admin.firestore.FieldValue.increment(paymentMethod === 'cash' ? totalAmount : 0),
          'totals.digitalSales': admin.firestore.FieldValue.increment(paymentMethod !== 'cash' ? totalAmount : 0),
          'totals.netProfit': admin.firestore.FieldValue.increment(totalAmount),
          'totals.transactionCount': admin.firestore.FieldValue.increment(1),
          'totals.cashTransactionCount': admin.firestore.FieldValue.increment(paymentMethod === 'cash' ? 1 : 0),
          'totals.digitalTransactionCount': admin.firestore.FieldValue.increment(paymentMethod !== 'cash' ? 1 : 0),
          'totals.productsSoldCount': admin.firestore.FieldValue.increment(
            transactionItems.filter(i => i.itemType === 'product').reduce((s, i) => s + i.quantity, 0)
          ),
          'totals.servicesSoldCount': admin.firestore.FieldValue.increment(
            transactionItems.filter(i => i.itemType === 'service').reduce((s, i) => s + i.quantity, 0)
          ),
        });
      }
    });

    res.status(201).json({
      success: true,
      transactionId: transactionRef.id,
      businessId,
      message: 'Sale recorded successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
module.exports.getBusinessId = getBusinessId;
module.exports.ts = ts;
module.exports.startOfDay = startOfDay;
module.exports.endOfDay = endOfDay;
module.exports.formatDateKey = formatDateKey;
module.exports.db = db;
