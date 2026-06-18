import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_tier.dart';

class SubscriptionTierService {
  SubscriptionTierService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
}
