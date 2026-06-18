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

    // Query: today and yesterday transactions in parallel
    const [todaySnap, yesterdaySnap, productsSnap] = await Promise.all([
      businessRef.collection('transactions')
        .where('saleDate', '>=', dayStart)
        .where('saleDate', '<=', dayEnd)
        .get(),
      businessRef.collection('transactions')
        .where('saleDate', '>=', prevDayStart)
        .where('saleDate', '<=', prevDayEnd)
        .get(),
      businessRef.collection('products').where('isDeleted', '==', false).get(),
    ]);

    // Today's completed transactions
    const todayCompleted = todaySnap.docs.filter(d => d.data().status === 'completed');
    const todayRefunded = todaySnap.docs.filter(d => d.data().status === 'refunded');

    const todayTotal = todayCompleted.reduce((s, d) => s + (d.data().totalAmount || 0), 0)
      - todayRefunded.reduce((s, d) => s + (d.data().totalAmount || 0), 0);
    const todayCount = todayCompleted.length - todayRefunded.length;

    const todayCash = todayCompleted
      .filter(d => d.data().paymentMethod === 'cash')
      .reduce((s, d) => s + (d.data().totalAmount || 0), 0);
    const todayDigital = todayCompleted
      .filter(d => d.data().paymentMethod !== 'cash')
      .reduce((s, d) => s + (d.data().totalAmount || 0), 0);
    const todayCashCount = todayCompleted.filter(d => d.data().paymentMethod === 'cash').length;
    const todayDigitalCount = todayCompleted.filter(d => d.data().paymentMethod !== 'cash').length;

    // Yesterday for trend
    const yesterdayCompleted = yesterdaySnap.docs.filter(d => d.data().status === 'completed');
    const yesterdayRefunded = yesterdaySnap.docs.filter(d => d.data().status === 'refunded');
    const yesterdayTotal = yesterdayCompleted.reduce((s, d) => s + (d.data().totalAmount || 0), 0)
      - yesterdayRefunded.reduce((s, d) => s + (d.data().totalAmount || 0), 0);

    const trend = yesterdayTotal > 0
      ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100
      : (todayTotal > 0 ? 100 : 0);

    // Metrics
    // Top sale = highest single transaction amount today
    let topSale = 0;
    for (const doc of todayCompleted) {
      const amt = doc.data().totalAmount || 0;
      if (amt > topSale) topSale = amt;
    }

    // Busiest hour
    const hourCounts = {};
    for (const doc of todayCompleted) {
      const saleTs = doc.data().saleDate;
      if (saleTs) {
        const hr = saleTs.toDate().getHours();
        hourCounts[hr] = (hourCounts[hr] || 0) + 1;
      }
    }
    let busiestHour = 0;
    let busiestHourCount = 0;
    for (const [hr, count] of Object.entries(hourCounts)) {
      if (count > busiestHourCount) {
        busiestHourCount = count;
        busiestHour = Number(hr);
      }
    }
    const busiestHourStr = `${String(busiestHour).padStart(2, '0')}:00 - ${String((busiestHour + 1) % 24).padStart(2, '0')}:00`;

    // Best / slowest seller (from todayCompleted items)
    const productSales = {};
    for (const doc of todayCompleted) {
      const items = doc.data().items || [];
      for (const item of items) {
        if (item && typeof item === 'object' && !Array.isArray(item)) {
          const name = item.name || 'Unknown';
          const qty = Number(item.quantity) || 0;
          productSales[name] = (productSales[name] || 0) + qty;
        }
      }
    }
    const sortedProducts = Object.entries(productSales).sort((a, b) => b[1] - a[1]);
    const bestSeller = sortedProducts.length > 0 ? sortedProducts[0][0] : 'N/A';
    const slowestSeller = sortedProducts.length > 1 ? sortedProducts[sortedProducts.length - 1][0] : 'N/A';
    const bestSellerQty = sortedProducts.length > 0 ? sortedProducts[0][1] : 0;

    // Stock data for slowest seller context
    const productMap = {};
    for (const doc of productsSnap.docs) {
      const data = doc.data();
      productMap[data.name] = data.stockQuantity || 0;
    }
    const slowestStock = productMap[slowestSeller] ?? 0;

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
          total: data.totalAmount || 0,
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
