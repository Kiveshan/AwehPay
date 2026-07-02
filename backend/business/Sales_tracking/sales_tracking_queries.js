const express = require('express');
const {
  getBusinessId,
  startOfDay,
  endOfDay,
  formatDateKey,
  db,
} = require('./sales_tracking_backend');

const router = express.Router();

// ── 2. Daily sales summary + metrics ─────────────────────────────

router.post('/daily-summary', async (req, res) => {
  try {
    const { idToken, date } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const { businessId } = await getBusinessId(idToken);
    const businessRef = db.collection('businesses').doc(businessId);

    const selected = date ? new Date(date + 'T00:00:00Z') : new Date();
    selected.setUTCHours(12, 0, 0, 0);

    const dayStart = startOfDay(selected);
    const dayEnd = endOfDay(selected);

    // Previous day for trend
    const prevDay = new Date(selected);
    prevDay.setUTCDate(prevDay.getUTCDate() - 1);
    const prevDayStart = startOfDay(prevDay);
    const prevDayEnd = endOfDay(prevDay);

    // Query: today, yesterday, all-time completed transactions, and products in parallel
    const [todaySnap, yesterdaySnap, productsSnap, allTxSnap] = await Promise.all([
      businessRef.collection('transactions')
        .where('saleDate', '>=', dayStart)
        .where('saleDate', '<=', dayEnd)
        .get(),
      businessRef.collection('transactions')
        .where('saleDate', '>=', prevDayStart)
        .where('saleDate', '<=', prevDayEnd)
        .get(),
      businessRef.collection('products').where('isDeleted', '==', false).get(),
      businessRef.collection('transactions')
        .where('status', '==', 'completed')
        .get(),
    ]);

    // Today's completed transactions
    const todayCompleted = todaySnap.docs.filter(d => d.data().status === 'completed');
    const todayRefunded = todaySnap.docs.filter(d => d.data().status === 'refunded');

    const txAmt = (doc) => doc.data().amountTotal ?? doc.data().totalAmount ?? 0;

    const todayTotal = todayCompleted.reduce((s, d) => s + txAmt(d), 0)
      - todayRefunded.reduce((s, d) => s + txAmt(d), 0);
    const todayCount = todayCompleted.length - todayRefunded.length;

    const todayCash = todayCompleted
      .filter(d => d.data().paymentMethod === 'cash')
      .reduce((s, d) => s + txAmt(d), 0);
    const todayDigital = todayCompleted
      .filter(d => d.data().paymentMethod !== 'cash')
      .reduce((s, d) => s + txAmt(d), 0);
    const todayCashCount = todayCompleted.filter(d => d.data().paymentMethod === 'cash').length;
    const todayDigitalCount = todayCompleted.filter(d => d.data().paymentMethod !== 'cash').length;

    // Yesterday for trend
    const yesterdayCompleted = yesterdaySnap.docs.filter(d => d.data().status === 'completed');
    const yesterdayRefunded = yesterdaySnap.docs.filter(d => d.data().status === 'refunded');
    const yesterdayTotal = yesterdayCompleted.reduce((s, d) => s + txAmt(d), 0)
      - yesterdayRefunded.reduce((s, d) => s + txAmt(d), 0);

    const trend = yesterdayTotal > 0
      ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100
      : (todayTotal > 0 ? 100 : 0);

    // Build product lookup: productId -> { costPrice, stockQuantity }
    const productLookup = {};
    for (const doc of productsSnap.docs) {
      const data = doc.data();
      const pid = data.productId || doc.id;
      productLookup[pid] = {
        costPrice: data.costPrice || 0,
        stockQuantity: data.stockQuantity || 0,
      };
    }

    // Metrics

    // Busiest hour — across all historical completed transactions
    const hourCounts = {};
    for (const doc of allTxSnap.docs) {
      const saleTs = doc.data().saleDate;
      if (saleTs) {
        const hr = saleTs.toDate().getHours();
        hourCounts[hr] = (hourCounts[hr] || 0) + 1;
      }
    }
    let busiestHour = null;
    let busiestHourCount = 0;
    for (const [hr, count] of Object.entries(hourCounts)) {
      if (count > busiestHourCount) {
        busiestHourCount = count;
        busiestHour = Number(hr);
      }
    }
    const busiestHourStr = busiestHour !== null
      ? `${String(busiestHour).padStart(2, '0')}:00 - ${String((busiestHour + 1) % 24).padStart(2, '0')}:00`
      : 'N/A';

    // Best / slowest seller — ranked by total profit: (sellingPrice - costPrice) × quantity
    // Also accumulates quantity for display
    const productStats = {};
    for (const doc of todayCompleted) {
      const items = doc.data().items || [];
      for (const item of items) {
        if (item && typeof item === 'object' && !Array.isArray(item)) {
          const name = item.name || 'Unknown';
          const qty = Number(item.quantity) || 0;
          const sellingPrice = Number(item.unitPrice) || 0;
          const costPrice = productLookup[item.itemId]?.costPrice || 0;
          const profit = (sellingPrice - costPrice) * qty;
          if (!productStats[name]) productStats[name] = { quantity: 0, profit: 0, itemId: item.itemId };
          productStats[name].quantity += qty;
          productStats[name].profit += profit;
        }
      }
    }
    // Sort: most quantity first; if tied on quantity, most profit first
    const sortedProducts = Object.entries(productStats).sort(
      (a, b) => b[1].quantity - a[1].quantity || b[1].profit - a[1].profit
    );
    const bestSeller = sortedProducts.length > 0 ? sortedProducts[0][0] : 'N/A';
    const bestSellerQty = sortedProducts.length > 0 ? sortedProducts[0][1].quantity : 0;
    const bestSellerProfit = sortedProducts.length > 0 ? sortedProducts[0][1].profit : 0;

    // Slowest seller: fewest units sold; if tied on quantity, highest profit among the tied group
    let slowestSeller = 'N/A';
    if (sortedProducts.length > 1) {
      const minQty = sortedProducts[sortedProducts.length - 1][1].quantity;
      const tied = sortedProducts.filter(([, s]) => s.quantity === minQty);
      tied.sort((a, b) => b[1].profit - a[1].profit);
      slowestSeller = tied[0][0];
    }
    const slowestStock = productLookup[productStats[slowestSeller]?.itemId]?.stockQuantity ?? 0;

    // Top sale = single transaction that generated the highest profit today
    let topSale = 0;
    let topSaleProfit = 0;
    for (const doc of todayCompleted) {
      const items = doc.data().items || [];
      let txProfit = 0;
      for (const item of items) {
        if (item && typeof item === 'object' && !Array.isArray(item)) {
          const qty = Number(item.quantity) || 0;
          const sellingPrice = Number(item.unitPrice) || 0;
          const costPrice = productLookup[item.itemId]?.costPrice || 0;
          txProfit += (sellingPrice - costPrice) * qty;
        }
      }
      if (txProfit > topSaleProfit) {
        topSaleProfit = txProfit;
        topSale = txAmt(doc);
      }
    }

    res.json({
      success: true,
      date: formatDateKey(selected),
      summary: {
        totalSales: todayTotal,
        totalTransactions: todayCount,
        cashSales: todayCash,
        digitalSales: todayDigital,
        cashCount: todayCashCount,
        digitalCount: todayDigitalCount,
      },
      trend: {
        percentage: Number(trend.toFixed(1)),
        direction: trend >= 0 ? 'up' : 'down',
      },
      metrics: {
        topSale: topSale,
        busiestHour: busiestHourStr,
        bestSeller: bestSeller,
        bestSellerUnits: bestSellerQty,
        bestSellerProfit: bestSellerProfit,
        slowestSeller: slowestSeller,
        slowestSellerStock: slowestStock,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ── 3. List transactions for a date ────────────────────────────

router.post('/transactions', async (req, res) => {
  try {
    const { idToken, date } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const { businessId } = await getBusinessId(idToken);
    const businessRef = db.collection('businesses').doc(businessId);

    const selected = date ? new Date(date + 'T00:00:00Z') : new Date();
    selected.setUTCHours(12, 0, 0, 0);

    const dayStart = startOfDay(selected);
    const dayEnd = endOfDay(selected);

    const snap = await businessRef.collection('transactions')
      .where('saleDate', '>=', dayStart)
      .where('saleDate', '<=', dayEnd)
      .get();

    const transactions = snap.docs
      .filter(doc => ['completed', 'refunded'].includes(doc.data().status))
      .sort((a, b) => {
        const aTs = a.data().saleDate?.toDate ? a.data().saleDate.toDate() : new Date(a.data().saleDate);
        const bTs = b.data().saleDate?.toDate ? b.data().saleDate.toDate() : new Date(b.data().saleDate);
        return bTs.getTime() - aTs.getTime();
      })
      .map((doc) => {
        const data = doc.data();
        const saleTs = data.saleDate?.toDate ? data.saleDate.toDate() : new Date(data.saleDate);
        return {
          transactionId: data.transactionId || doc.id,
          time: {
            hour: saleTs.getHours(),
            minute: saleTs.getMinutes(),
          },
          summary: (data.items || []).map(i => i.name).join(', '),
          total: data.amountTotal ?? data.totalAmount ?? 0,
          paymentMethod: data.paymentMethod || 'cash',
          status: data.status || 'completed',
          items: (data.items || []).map((item) => ({
            name: item.name || 'Unknown',
            quantity: Number(item.quantity) || 0,
            price: Number(item.unitPrice) || Number(item.totalPrice) || 0,
          })),
        };
      });

    res.json({
      success: true,
      date: formatDateKey(selected),
      transactions,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
