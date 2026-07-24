const admin = require('firebase-admin');
const db = admin.firestore();

/**
 * Middleware to check subscription limits before allowing operations
 * @param {string} limitType - Type of limit to check ('products', 'services', 'cardPayments')
 * @param {number} currentCount - Current count of items (optional, if not provided will be queried)
 */
async function checkSubscriptionLimit(businessId, limitType, currentCount = null) {
  try {
    // Get business document to find subscription tier
    const businessDoc = await db.collection('businesses').doc(businessId).get();
    if (!businessDoc.exists) {
      return { allowed: false, error: 'Business not found' };
    }

    const businessData = businessDoc.data();
    const subscription = businessData.subscription || {};
    const tierId = subscription.tierId || 'basic';

    // Check if business is on an active 30-day trial
    const trialEndDate = subscription.trialEndDate;
    if (trialEndDate) {
      const now = new Date();
      const trialEnd = trialEndDate.toDate ? trialEndDate.toDate() : new Date(trialEndDate);
      
      // If trial is still active, allow all operations without limits
      if (now < trialEnd) {
        return { allowed: true, limit: null, current: currentCount, onTrial: true };
      }
    }

    // Get subscription tier limits
    const tierDoc = await db.collection('subscriptionTiers').doc(tierId).get();
    if (!tierDoc.exists) {
      // If tier not found, use basic tier defaults
      return { allowed: true, limit: null, current: currentCount };
    }

    const tierData = tierDoc.data();
    const limits = tierData.limits || {};

    let limit = null;
    let count = currentCount;

    switch (limitType) {
      case 'products':
        limit = limits.maxProducts;
        if (count === null) {
          const productsSnapshot = await db
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .get();
          count = productsSnapshot.size;
        }
        break;

      case 'services':
        limit = limits.maxServices;
        if (count === null) {
          const servicesSnapshot = await db
            .collection('businesses')
            .doc(businessId)
            .collection('services')
            .get();
          count = servicesSnapshot.size;
        }
        break;

      case 'cardPayments':
        limit = limits.maxCardPaymentsPerDay;
        if (count === null) {
          count = await getDailyCardPaymentCount(businessId);
        }
        break;

      default:
        return { allowed: true, limit: null, current: count };
    }

    // If no limit is set, allow operation
    if (limit === null || limit === undefined) {
      return { allowed: true, limit: null, current: count };
    }

    // Grandfather clause: if current count already exceeds limit, allow operation
    if (count > limit) {
      return { allowed: true, limit, current: count, grandfathered: true };
    }

    // Check if limit would be exceeded
    if (count >= limit) {
      return { 
        allowed: false, 
        limit, 
        current: count, 
        error: `Limit exceeded: ${count}/${limit} ${limitType} used`,
        tierName: tierData.name || 'Basic'
      };
    }

    return { allowed: true, limit, current: count };
  } catch (error) {
    console.error('Error checking subscription limit:', error);
    // On error, allow operation to avoid blocking legitimate use
    return { allowed: true, limit: null, current: currentCount };
  }
}

/**
 * Get daily card payment count for a business (SAST timezone)
 */
async function getDailyCardPaymentCount(businessId) {
  try {
    // Get current date in SAST (UTC+2)
    const now = new Date();
    const sastOffset = 2 * 60 * 60 * 1000; // 2 hours in milliseconds
    const sastNow = new Date(now.getTime() + sastOffset);
    
    // Start of day in SAST
    const sastStartOfDay = new Date(sastNow);
    sastStartOfDay.setHours(0, 0, 0, 0);
    
    // Convert back to UTC for Firestore query
    const utcStartOfDay = new Date(sastStartOfDay.getTime() - sastOffset);
    const utcEndOfDay = new Date(utcStartOfDay.getTime() + 24 * 60 * 60 * 1000);

    // Query transactions for card payments within current SAST day
    const transactionsSnapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('transactions')
      .where('paymentMethod', 'in', ['qr', 'card'])
      .where('saleDate', '>=', admin.firestore.Timestamp.fromDate(utcStartOfDay))
      .where('saleDate', '<', admin.firestore.Timestamp.fromDate(utcEndOfDay))
      .where('status', '==', 'completed')
      .get();

    return transactionsSnapshot.size;
  } catch (error) {
    console.error('Error getting daily card payment count:', error);
    return 0;
  }
}

/**
 * Express middleware factory for checking subscription limits
 */
function createLimitCheckMiddleware(limitType) {
  return async (req, res, next) => {
    try {
      const idToken = req.headers.authorization?.replace('Bearer ', '');
      if (!idToken) {
        return res.status(401).json({ error: 'Authorization token required' });
      }

      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const userDoc = await db.collection('users').doc(decodedToken.uid).get();
      
      if (!userDoc.exists) {
        return res.status(404).json({ error: 'User not found' });
      }

      const userData = userDoc.data();
      const businessId = userData?.businessId;

      if (!businessId) {
        return res.status(400).json({ error: 'No business linked to account' });
      }

      const result = await checkSubscriptionLimit(businessId, limitType);

      if (!result.allowed) {
        return res.status(403).json({
          success: false,
          error: result.error,
          limitType,
          limit: result.limit,
          current: result.current,
          tierName: result.tierName,
          requiresUpgrade: true
        });
      }

      // Attach limit info to request for use in handlers
      req.subscriptionLimits = result;
      next();
    } catch (error) {
      console.error('Limit check middleware error:', error);
      // On error, allow operation to avoid blocking legitimate use
      next();
    }
  };
}

module.exports = {
  checkSubscriptionLimit,
  getDailyCardPaymentCount,
  createLimitCheckMiddleware
};
