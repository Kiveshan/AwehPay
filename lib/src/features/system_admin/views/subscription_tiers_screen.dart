import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_tier.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/subscription_tier_service.dart';

class SubscriptionTiersScreen extends StatefulWidget {
  const SubscriptionTiersScreen({super.key});

  @override
  State<SubscriptionTiersScreen> createState() =>
      _SubscriptionTiersScreenState();
}

class _SubscriptionTiersScreenState extends State<SubscriptionTiersScreen> {
  final SubscriptionTierService _tierService = SubscriptionTierService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF272A2F)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        backgroundColor: const Color(0xFF7B61FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<SubscriptionTier>>(
        stream: _tierService.getActiveTiersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final tiers = snapshot.data ?? [];
          if (tiers.isEmpty) {
            return const Center(child: Text('No subscription plans found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tiers.length,
            itemBuilder: (context, index) => _TierDetailCard(
              tier: tiers[index],
              onEdit: () => _openEditor(context, tier: tiers[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {SubscriptionTier? tier}) async {
    final result = await context.push<bool>(
      AppRoutes.editSubscriptionTier,
      extra: tier,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _TierDetailCard extends StatelessWidget {
  const _TierDetailCard({required this.tier, this.onEdit});

  final SubscriptionTier tier;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final priceText = tier.price == 0
        ? 'Free'
        : 'R${tier.price.toStringAsFixed(0)} / ${tier.billingPeriod}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tier.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF272A2F),
                    ),
                  ),
                ),
                if (tier.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: const Color(0xFF7B61FF),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              priceText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B61FF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tier.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6C7078),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272A2F),
              ),
            ),
            const SizedBox(height: 8),
            ...tier.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF7B61FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C7078),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tier.limits.hasRestrictions) ...[
              const SizedBox(height: 16),
              const Text(
                'Limits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF272A2F),
                ),
              ),
              const SizedBox(height: 8),
              _LimitRow(
                label: 'Max Products',
                value: tier.limits.maxProducts?.toString() ?? 'Unlimited',
              ),
              _LimitRow(
                label: 'Max Services',
                value: tier.limits.maxServices?.toString() ?? 'Unlimited',
              ),
              _LimitRow(
                label: 'Max Card Payments/Day',
                value: tier.limits.maxCardPaymentsPerDay?.toString() ?? 'Unlimited',
              ),
              _LimitRow(
                label: 'Barcode Scanner',
                value: tier.limits.barcodeScannerEnabled ? 'Enabled' : 'Disabled',
              ),
              _LimitRow(
                label: 'Low Stock Alerts',
                value: tier.limits.lowStockAlertsEnabled ? 'Enabled' : 'Disabled',
              ),
              _LimitRow(
                label: 'Analytics',
                value: tier.limits.analyticsEnabled ? 'Enabled' : 'Disabled',
              ),
              _LimitRow(
                label: 'Expense Tracking',
                value: tier.limits.expenseTrackingEnabled ? 'Enabled' : 'Disabled',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6C7078),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF272A2F),
            ),
          ),
        ],
      ),
    );
  }
}
