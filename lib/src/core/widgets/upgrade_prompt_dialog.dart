import 'package:flutter/material.dart';

import '../../app.dart';
import '../models/subscription_tier.dart';
import '../services/purchase_service.dart';
import '../services/subscription_tier_service.dart';

class UpgradePromptDialog extends StatelessWidget {
  final String limitType;
  final int limit;
  final int current;
  final String tierName;

  const UpgradePromptDialog({
    super.key,
    required this.limitType,
    required this.limit,
    required this.current,
    required this.tierName,
  });

  @override
  Widget build(BuildContext context) {
    String limitText;
    String upgradeBenefit;
    IconData limitIcon;

    switch (limitType) {
      case 'products':
        limitText = 'products';
        upgradeBenefit = 'Add unlimited products to your inventory';
        limitIcon = Icons.inventory_2_outlined;
        break;
      case 'services':
        limitText = 'services';
        upgradeBenefit = 'Offer unlimited services to your customers';
        limitIcon = Icons.room_service_outlined;
        break;
      case 'cardPayments':
        limitText = 'card payments per day';
        upgradeBenefit = 'Accept unlimited card payments daily';
        limitIcon = Icons.credit_card_outlined;
        break;
      default:
        limitText = limitType;
        upgradeBenefit = 'Unlock more features';
        limitIcon = Icons.lock_outline;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF8F9FF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFDFA890),
                    const Color(0xFFFEEAB8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDFA890).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                limitIcon,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Limit Reached',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF272A2F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Your $tierName tier limit',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Usage card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEEAB8).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDFA890).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          limitText[0].toUpperCase() + limitText.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$current / $limit',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF272A2F),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A28D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: const Color(0xFFE8A28D),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Benefits section
            const Text(
              'Upgrade to unlock:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272A2F),
              ),
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.check_circle_rounded, upgradeBenefit),
            _buildBenefitItem(Icons.check_circle_rounded, 'Remove all usage limitations'),
            _buildBenefitItem(Icons.check_circle_rounded, 'Access premium analytics'),
            _buildBenefitItem(Icons.check_circle_rounded, 'Priority customer support'),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToUpgrade(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFDFA890),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: const Color(0xFFDFA890).withValues(alpha: 0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFDFA890).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xFFDFA890),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF272A2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kicks off a real Google Play purchase for the recommended paid tier. Feedback for
  // the async result (pending/success/error) is shown globally via app.dart's listener
  // on PurchaseService.statusStream, since this dialog is already dismissed by the time
  // the purchase actually resolves.
  Future<void> _navigateToUpgrade(BuildContext context) async {
    final messenger = rootScaffoldMessengerKey.currentState;

    try {
      final tiers = await SubscriptionTierService().getActiveTiers();
      final playTiers = tiers
          .where((t) => t.playProductId != null && t.playProductId!.isNotEmpty)
          .toList();

      if (playTiers.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Upgrades are not available yet. Please check back soon.')),
        );
        return;
      }

      final SubscriptionTier targetTier = playTiers.firstWhere(
        (t) => t.isRecommended,
        orElse: () => playTiers.first,
      );

      if (!await PurchaseService.instance.isAvailable()) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Google Play Billing is unavailable on this device.')),
        );
        return;
      }

      final response =
          await PurchaseService.instance.queryProducts({targetTier.playProductId!});
      if (response.productDetails.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('This plan is not available for purchase right now.')),
        );
        return;
      }

      await PurchaseService.instance.buySubscription(response.productDetails.first);
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Could not start checkout: $e')));
    }
  }

  static Future<void> show(
    BuildContext context, {
    required String limitType,
    required int limit,
    required int current,
    required String tierName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpgradePromptDialog(
        limitType: limitType,
        limit: limit,
        current: current,
        tierName: tierName,
      ),
    );
  }
}
