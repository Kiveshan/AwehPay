import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_tier.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/services/subscription_tier_service.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';

/// Shown instead of the business home screen when /verify-token reports the
/// business's subscription is blocked (expired trial, expired subscription,
/// cancelled, or payment failed). The user is already Firebase-authenticated at
/// this point — they just can't proceed into the app until they resolve this,
/// so this screen is the only place they can actually pay to unblock themselves.
class SubscriptionExpiredScreen extends StatefulWidget {
  const SubscriptionExpiredScreen({super.key, this.message});

  final String? message;

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState
    extends State<SubscriptionExpiredScreen> {
  List<SubscriptionTier> _playTiers = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  StreamSubscription<PurchaseUiStatus>? _purchaseStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadTiers();
    _purchaseStatusSubscription =
        PurchaseService.instance.statusStream.listen(_onPurchaseStatus);
  }

  @override
  void dispose() {
    _purchaseStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTiers() async {
    try {
      final tiers = await SubscriptionTierService().getActiveTiers();
      setState(() {
        _playTiers = tiers
            .where((t) => t.playProductId != null && t.playProductId!.isNotEmpty)
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price));
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans';
        _isLoading = false;
      });
    }
  }

  void _onPurchaseStatus(PurchaseUiStatus status) {
    if (!mounted) return;
    switch (status.type) {
      case PurchaseUiStatusType.success:
        // Subscription is active again — proceed into the app.
        context.go(AppRoutes.businessHome);
        break;
      case PurchaseUiStatusType.error:
        setState(() {
          _isPurchasing = false;
          _errorMessage = status.message;
        });
        break;
      case PurchaseUiStatusType.canceled:
        setState(() => _isPurchasing = false);
        break;
      case PurchaseUiStatusType.pending:
        break;
    }
  }

  Future<void> _subscribe(SubscriptionTier tier) async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      if (!await PurchaseService.instance.isAvailable()) {
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'Google Play Billing is unavailable on this device.';
        });
        return;
      }

      final response =
          await PurchaseService.instance.queryProducts({tier.playProductId!});
      if (response.productDetails.isEmpty) {
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'This plan is not available for purchase right now.';
        });
        return;
      }

      // No existing active Play subscription to replace — the account is blocked,
      // so this is always a fresh purchase, never an upgrade/downgrade replace.
      await PurchaseService.instance.buySubscription(response.productDetails.first);
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Could not start checkout: $e';
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRoutes.adminSignIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.lock_clock_outlined, size: 56, color: Color(0xFFDFA890)),
                  const SizedBox(height: 20),
                  const Text(
                    'Subscription Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF272A2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message ??
                        'Your trial or subscription has ended. Choose a plan to continue using AwehBiz.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6C7078)),
                  ),
                  const SizedBox(height: 28),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_playTiers.isEmpty)
                    const Text(
                      'No subscription plans are available right now. Please try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    ..._playTiers.map(
                      (tier) => _PlanCard(
                        tier: tier,
                        isLoading: _isPurchasing,
                        onSubscribe: () => _subscribe(tier),
                      ),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isPurchasing ? null : _logout,
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.isLoading,
    required this.onSubscribe,
  });

  final SubscriptionTier tier;
  final bool isLoading;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tier.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'R${tier.price.toStringAsFixed(0)} / ${tier.billingPeriod}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6C7078)),
          ),
          const SizedBox(height: 12),
          AdminPrimaryButton(
            label: isLoading ? 'Processing...' : 'Subscribe',
            onPressed: isLoading ? null : onSubscribe,
          ),
        ],
      ),
    );
  }
}
