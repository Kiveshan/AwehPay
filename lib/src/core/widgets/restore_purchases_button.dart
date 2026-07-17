import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// Re-triggers Play Billing's purchase restoration flow — needed for reinstalls or
/// signing in on a new device, since entitlement itself lives in Firestore but the
/// local Play Billing client has no record of past purchases until this runs.
/// Result feedback (success/error) is shown globally via app.dart's listener on
/// PurchaseService.statusStream.
class RestorePurchasesButton extends StatelessWidget {
  const RestorePurchasesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.restore, color: Color(0xFF272A2F)),
      tooltip: 'Restore Purchases',
      onPressed: () => PurchaseService.instance.restorePurchases(),
    );
  }
}
