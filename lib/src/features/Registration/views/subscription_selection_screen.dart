import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_tier.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/subscription_tier_service.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';

class SubscriptionSelectionScreen extends StatefulWidget {
  const SubscriptionSelectionScreen({super.key});

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {
  final SubscriptionTierService _tierService = SubscriptionTierService();
  List<SubscriptionTier> _tiers = [];
  SubscriptionTier? _selectedTier;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    try {
      final tiers = await _tierService.getActiveTiers();
      setState(() {
        _tiers = tiers;
        _isLoading = false;
        _selectedTier = tiers.cast<SubscriptionTier?>().firstWhere(
              (t) => t?.isRecommended == true,
              orElse: () => tiers.isNotEmpty ? tiers.first : null,
            );
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load subscription tiers';
        _isLoading = false;
      });
    }
  }

  void _handleNext() {
    if (_selectedTier == null) {
      setState(() {
        _errorMessage = 'Please select a subscription tier';
      });
      return;
    }
    registrationDraft.selectedTier = _selectedTier;
    context.push(AppRoutes.paymentInformation);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Choose a Plan',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select the plan that works best for your business.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C7078),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null && _tiers.isEmpty)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                )
              else
                ..._tiers.map(
                  (tier) => _TierCard(
                    tier: tier,
                    isSelected: _selectedTier?.tierId == tier.tierId,
                    onTap: () => setState(() => _selectedTier = tier),
                  ),
                ),
              const SizedBox(height: 28),
              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (!_isLoading)
                AdminPrimaryButton(
                  label: 'Next',
                  icon: Icons.arrow_forward,
                  onPressed: _handleNext,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceText = tier.price == 0
        ? 'Free'
        : 'R${tier.price.toStringAsFixed(0)} / ${tier.billingPeriod}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA9A5F4)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: const Color(0xFF7B61FF), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tier.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF272A2F),
                      ),
                    ),
                  ),
                  if (tier.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withAlpha(51)
                            : const Color(0xFF7B61FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                priceText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF6C7078),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tier.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white70
                      : const Color(0xFF6C7078),
                ),
              ),
              const SizedBox(height: 8),
              ...tier.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF7B61FF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : const Color(0xFF6C7078),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (tier.limits.hasRestrictions) ...[
                const SizedBox(height: 10),
                Text(
                  'Limits',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF272A2F),
                  ),
                ),
                const SizedBox(height: 4),
                _LimitRow(
                  label: 'Max Products',
                  value: tier.limits.maxProducts?.toString() ?? 'Unlimited',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Max Services',
                  value: tier.limits.maxServices?.toString() ?? 'Unlimited',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Max Card Payments/Day',
                  value: tier.limits.maxCardPaymentsPerDay?.toString() ?? 'Unlimited',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Barcode Scanner',
                  value: tier.limits.barcodeScannerEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Low Stock Alerts',
                  value: tier.limits.lowStockAlertsEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Analytics',
                  value: tier.limits.analyticsEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Cash Sales',
                  value: tier.limits.cashSalesEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Card Payments',
                  value: tier.limits.cardPaymentsEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
                _LimitRow(
                  label: 'Expense Tracking',
                  value: tier.limits.expenseTrackingEnabled ? 'Enabled' : 'Disabled',
                  isSelected: isSelected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.value,
    required this.isSelected,
  });

  final String label;
  final String value;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : const Color(0xFF6C7078),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF272A2F),
            ),
          ),
        ],
      ),
    );
  }
}
