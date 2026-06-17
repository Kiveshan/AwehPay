const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

const DAY_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const DAY_FULL  = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const COLORS    = ['#6C63FF', '#FF4D8D', '#00C4A7', '#9B59B6', '#FF9A3C', '#3D7FB4', '#F1C75B', '#E68888'];

function ts(date) { return admin.firestore.Timestamp.fromDate(date); }

function startOfDay(d) {
  const x = new Date(d); x.setHours(0, 0, 0, 0); return ts(x);
}
function endOfDay(d) {
  const x = new Date(d); x.setHours(23, 59, 59, 999); return ts(x);
}
function startOfMonth(d) {
  const x = new Date(d); x.setDate(1); x.setHours(0, 0, 0, 0); return ts(x);
}
function capitalize(str) {
  if (!str) return 'Other';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

router.get('/analytics', async (req, res) => {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '');
    if (!idToken) return res.status(400).json({ error: 'Authorization token required' });

    const { date } = req.query;
    const selected = date ? new Date(date) : new Date();
    selected.setHours(12, 0, 0, 0);

    const decodedToken = await auth.verifyIdToken(idToken);
    let userDoc = await db.collection('users').doc(decodedToken.uid).get();
    if (!userDoc.exists) {
      const q = await db.collection('users').where('uid', '==', decodedToken.uid).limit(1).get();
      if (q.empty) return res.status(404).json({ error: 'User profile not found. Please complete registration.' });
      userDoc = q.docs[0];
    }
    const businessId = userDoc.data()?.businessId;
    if (!businessId) return res.status(400).json({ error: 'No business linked to this account' });

    const biz = db.collection('businesses').doc(businessId);

    const dayStart   = startOfDay(selected);
    const dayEnd     = endOfDay(selected);
    const monthStart = startOfMonth(selected);

    const weekStartDate = new Date(selected);
    weekStartDate.setDate(weekStartDate.getDate() - 6);
    weekStartDate.setHours(0, 0, 0, 0);
    const weekStart = ts(weekStartDate);

    // Queries in parallel
    const [dayTx, dayExp, weekTx, weekExp, monthTx, monthExp] = await Promise.all([
      biz.collection('transactions').where('saleDate', '>=', dayStart).where('saleDate', '<=', dayEnd).get(),
      biz.collection('expenses').where('expenseDate', '>=', dayStart).where('expenseDate', '<=', dayEnd).get(),
      biz.collection('transactions').where('saleDate', '>=', weekStart).where('saleDate', '<=', dayEnd).get(),
      biz.collection('expenses').where('expenseDate', '>=', weekStart).where('expenseDate', '<=', dayEnd).get(),
      biz.collection('transactions').where('saleDate', '>=', monthStart).where('saleDate', '<=', dayEnd).get(),
      biz.collection('expenses').where('expenseDate', '>=', monthStart).where('expenseDate', '<=', dayEnd).get(),
    ]);

    const completedDayTx   = dayTx.docs.filter(d => d.data().status === 'completed');
    const completedWeekTx  = weekTx.docs.filter(d => d.data().status === 'completed');
    const completedMonthTx = monthTx.docs.filter(d => d.data().status === 'completed');

    const refundedDayTx   = dayTx.docs.filter(d => d.data().status === 'refunded');
    const refundedWeekTx  = weekTx.docs.filter(d => d.data().status === 'refunded');
    const refundedMonthTx = monthTx.docs.filter(d => d.data().status === 'refunded');

    const txTotal = (doc) => doc.data().amountTotal ?? doc.data().totalAmount ?? 0;

    // Handles refunds: sales minus refunds
    const netIncome = (sales, refunds) =>
      sales.reduce((s, d) => s + txTotal(d), 0) - refunds.reduce((s, d) => s + txTotal(d), 0);

    // ── 1. Net Profit (selected day) ─────────────────────────────────
    const moneyIn  = netIncome(completedDayTx, refundedDayTx);
    const moneyOut = dayExp.docs.reduce((s, d) => s + (d.data().amount || 0), 0);

    // ── 2. Last 7 days chart ─────────────────────────────────────────
    const chart = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(selected);
      d.setDate(d.getDate() - i);
      chart.push({ day: DAY_SHORT[d.getDay()], dateStr: d.toDateString(), income: 0, expense: 0 });
    }
    for (const doc of completedWeekTx) {
      const idx = chart.findIndex(c => c.dateStr === doc.data().saleDate.toDate().toDateString());
      if (idx !== -1) chart[idx].income += txTotal(doc);
    }
    for (const doc of refundedWeekTx) {
      const idx = chart.findIndex(c => c.dateStr === doc.data().saleDate.toDate().toDateString());
      if (idx !== -1) chart[idx].income -= txTotal(doc);
    }
    for (const doc of weekExp.docs) {
      const idx = chart.findIndex(c => c.dateStr === doc.data().expenseDate.toDate().toDateString());
      if (idx !== -1) chart[idx].expense += (doc.data().amount || 0);
    }

    // ── 3. Expense breakdown (month-to-date) ─────────────────────────
    const catMap = {};
    for (const doc of monthExp.docs) {
      const data = doc.data();
      const cat = capitalize(data.category || data.name);
      catMap[cat] = (catMap[cat] || 0) + (data.amount || 0);
    }
    const totalMonthExp = Object.values(catMap).reduce((s, v) => s + v, 0);
    const categories = Object.entries(catMap)
      .map(([name, amount], i) => ({
        name, amount,
        fraction: totalMonthExp > 0 ? amount / totalMonthExp : 0,
        colorHex: COLORS[i % COLORS.length],
      }))
      .sort((a, b) => b.amount - a.amount);

    // ── 4. Sales insights (month-to-date) ────────────────────────────
    const productSales = {};
    const dayRevenue   = {};

    const salesMonthTx = [...completedMonthTx, ...refundedMonthTx];
    for (const doc of salesMonthTx) {
      const data  = doc.data();
      const isRefund = data.status === 'refunded';
      const items = Array.isArray(data.items) ? data.items : [];
      if (!isRefund) {
        for (const item of items) {
          const name = (item && typeof item === 'object' && !Array.isArray(item))
            ? (item.name || 'Unknown') : 'Unknown';
          const qty = (item && typeof item === 'object' && !Array.isArray(item))
            ? (parseInt(item.quantity) || 1) : 1;
          productSales[name] = (productSales[name] || 0) + qty;
        }
      }
      const txDate = data.saleDate ?? data.completedAt ?? data.createdAt;
      if (!txDate) continue;
      const dayName = DAY_FULL[txDate.toDate().getDay()];
      if (!dayRevenue[dayName]) dayRevenue[dayName] = { total: 0, count: 0 };
      dayRevenue[dayName].total += isRefund ? -txTotal(doc) : txTotal(doc);
      if (!isRefund) dayRevenue[dayName].count++;
    }

    const sorted        = Object.entries(productSales).sort((a, b) => b[1] - a[1]);
    const topProduct    = sorted.length > 0 ? { name: sorted[0][0], unitsSold: sorted[0][1] } : null;
    const slowestSeller = sorted.length > 1 ? { name: sorted[sorted.length - 1][0], unitsSold: sorted[sorted.length - 1][1] } : null;
    const bestDay       = Object.entries(dayRevenue)
      .map(([day, v]) => ({ day, avgRevenue: v.count > 0 ? v.total / v.count : 0 }))
      .sort((a, b) => b.avgRevenue - a.avgRevenue)[0] || null;

    // ── 5. Cash flow (last 7 days) ────────────────────────────────────
    const weekIncome   = netIncome(completedWeekTx, refundedWeekTx);
    const weekExpenses = weekExp.docs.reduce((s, d) => s + (d.data().amount || 0), 0);
    const cashFlowAmt  = weekIncome - weekExpenses;
    const healthy      = cashFlowAmt >= 0;

    // ── 6. Smart tips ─────────────────────────────────────────────────
    const tips = [];
    if (topProduct)    tips.push({ icon: 'lightbulb_outline', message: `${topProduct.name} is your top seller — keep it stocked` });
    if (bestDay)       tips.push({ icon: 'trending_up',       message: `${bestDay.day} brings the most revenue — stay prepared` });
    tips.push(healthy
      ? { icon: 'bar_chart', message: 'Cash flow is healthy this week — great work!' }
      : { icon: 'warning',   message: 'Cash flow is negative this week — review your expenses' });
    if (slowestSeller) tips.push({ icon: 'layers', message: `${slowestSeller.name} is your slowest seller — consider adjusting stock` });
    if (tips.length < 2) tips.push({ icon: 'bar_chart', message: 'Record more sales to unlock personalised tips' });

    res.status(200).json({
      success: true,
      netProfit:           { profit: moneyIn - moneyOut, moneyIn, moneyOut },
      incomeExpensesChart: chart.map(({ day, income, expense }) => ({ day, income, expense })),
      expenseBreakdown:    { total: totalMonthExp, categories },
      salesInsights:       { topProduct, slowestSeller, bestDay },
      cashFlow:            { amount: cashFlowAmt, status: healthy ? 'Healthy' : 'Negative', trend: healthy ? 'Positive trend this week' : 'Negative trend this week' },
      smartTips:           tips,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
