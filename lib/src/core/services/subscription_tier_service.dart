import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription_tier.dart';

class SubscriptionTierService {
  SubscriptionTierService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  SubscriptionTier? _cachedTier;
  String? _cachedBusinessId;

  Stream<List<SubscriptionTier>> getActiveTiersStream() {
    return _firestore
        .collection('subscriptionTiers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) {
            final tiers = snapshot.docs
                .map(
                  (doc) => SubscriptionTier.fromMap(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
            tiers.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            return tiers;
          },
        );
  }

  Future<List<SubscriptionTier>> getActiveTiers() async {
    final snapshot = await _firestore
        .collection('subscriptionTiers')
        .where('isActive', isEqualTo: true)
        .get();
    final tiers = snapshot.docs
        .map(
          (doc) => SubscriptionTier.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
    tiers.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return tiers;
  }

  Future<SubscriptionTier?> getBusinessTier(String businessId) async {
    // Check cache first
    if (_cachedBusinessId == businessId && _cachedTier != null) {
      return _cachedTier;
    }

    final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
    if (!businessDoc.exists) return null;

    final businessData = businessDoc.data();
    final subscription = businessData?['subscription'] as Map<String, dynamic>?;
    final tierId = subscription?['tierId'] as String? ?? 'basic';

    final tierDoc = await _firestore.collection('subscriptionTiers').doc(tierId).get();
    if (!tierDoc.exists) return null;

    final tierData = tierDoc.data();
    if (tierData == null) return null;

    final tier = SubscriptionTier.fromMap(tierData, tierDoc.id);
    
    // Cache the result
    _cachedBusinessId = businessId;
    _cachedTier = tier;
    
    return tier;
  }

  void clearCache() {
    _cachedBusinessId = null;
    _cachedTier = null;
  }

  Future<SubscriptionLimits> getBusinessLimits(String businessId) async {
    final tier = await getBusinessTier(businessId);
    return tier?.limits ?? SubscriptionLimits(
      barcodeScannerEnabled: false,
      lowStockAlertsEnabled: false,
      analyticsEnabled: false,
      cashSalesEnabled: true,
      cardPaymentsEnabled: true,
      expenseTrackingEnabled: false,
    );
  }

  Future<LimitCheckResult> checkLimit(String businessId, LimitType type) async {
    // Check if business is on an active trial
    final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
    if (businessDoc.exists) {
      final businessData = businessDoc.data();
      final subscription = businessData?['subscription'] as Map<String, dynamic>?;
      final trialEndDate = subscription?['trialEndDate'];
      
      if (trialEndDate != null) {
        final trialEnd = trialEndDate is Timestamp ? trialEndDate.toDate() : DateTime.parse(trialEndDate.toString());
        if (DateTime.now().isBefore(trialEnd)) {
          // Trial is active, no limits apply
          return LimitCheckResult(
            allowed: true,
            limit: null,
            current: await getCurrentCount(businessId, type),
            grandfathered: false,
            onTrial: true,
          );
        }
      }
    }

    final limits = await getBusinessLimits(businessId);
    final currentCount = await getCurrentCount(businessId, type);
    
    int? limit;
    switch (type) {
      case LimitType.products:
        limit = limits.maxProducts;
        break;
      case LimitType.services:
        limit = limits.maxServices;
        break;
      case LimitType.cardPayments:
        limit = limits.maxCardPaymentsPerDay;
        break;
    }

    if (limit == null) {
      return LimitCheckResult(
        allowed: true,
        limit: null,
        current: currentCount,
        grandfathered: false,
      );
    }

    // Grandfather clause: if current count already exceeds limit, allow operation
    if (currentCount > limit) {
      return LimitCheckResult(
        allowed: true,
        limit: limit,
        current: currentCount,
        grandfathered: true,
      );
    }

    final allowed = currentCount < limit;
    return LimitCheckResult(
      allowed: allowed,
      limit: limit,
      current: currentCount,
      grandfathered: false,
    );
  }

  Future<int> getCurrentCount(String businessId, LimitType type) async {
    switch (type) {
      case LimitType.products:
        final productsSnapshot = await _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .where('isDeleted', isEqualTo: false)
            .get();
        return productsSnapshot.size;
      case LimitType.services:
        final servicesSnapshot = await _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('services')
            .where('isDeleted', isEqualTo: false)
            .get();
        return servicesSnapshot.size;
      case LimitType.cardPayments:
        return await getDailyCardPaymentCount(businessId);
    }
  }

  Future<int> getDailyCardPaymentCount(String businessId) async {
    // Get current date in SAST (UTC+2)
    final now = DateTime.now().toUtc();
    final sastOffset = Duration(hours: 2);
    final sastNow = now.add(sastOffset);
    
    // Start of day in SAST
    final sastStartOfDay = DateTime(sastNow.year, sastNow.month, sastNow.day);
    
    // Convert back to UTC for Firestore query
    final utcStartOfDay = sastStartOfDay.subtract(sastOffset);
    final utcEndOfDay = utcStartOfDay.add(const Duration(days: 1));

    final transactionsSnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('transactions')
        .where('paymentMethod', whereIn: ['qr', 'card'])
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(utcStartOfDay))
        .where('saleDate', isLessThan: Timestamp.fromDate(utcEndOfDay))
        .where('status', isEqualTo: 'completed')
        .get();

    return transactionsSnapshot.size;
  }
}

enum LimitType { products, services, cardPayments }

class LimitCheckResult {
  final bool allowed;
  final int? limit;
  final int current;
  final bool grandfathered;
  final bool onTrial;

  LimitCheckResult({
    required this.allowed,
    this.limit,
    required this.current,
    required this.grandfathered,
    this.onTrial = false,
  });
}
