import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/logout_button.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  Future<String> _fetchBusinessName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Business';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final businessId = userDoc.data()?['businessId'] as String?;
    if (businessId == null || businessId.isEmpty) return 'Business';

    final businessDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .get();

    return businessDoc.data()?['businessName'] as String? ?? 'Business';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: _fetchBusinessName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Business';
                  return _BusinessHeader(businessName: name);
                },
              ),
              const SizedBox(height: 100),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 16.0;
                  final cardWidth = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _BusinessTile(
                        width: cardWidth,
                        color: const Color(0xFFF4C4B7),
                        iconWidget: SvgPicture.asset('assets/images/StockCartIcon.svg'),
                        title: 'Inventory Management',
                        iconSize: 65,
                        onTap: () => context.push(AppRoutes.inventoryMenu),
                      ),
                      _BusinessTile(
                        width: cardWidth,
                        color: const Color(0xFFA9A5F4),
                        iconWidget: SvgPicture.asset('assets/images/MoneyIcon.svg'),
                        title: 'Purchases',
                        iconSize: 65,
                        onTap: () => context.push(AppRoutes.purchases),
                      ),
                      _BusinessTile(
                        width: cardWidth,
                        color: const Color(0xFF4F8DB7),
                        iconWidget: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 58),
                        title: 'Sales Tracking',
                        subtitle: 'updated',
                        iconSize: 58,
                        iconContainerSize: 58,
                        onTap: () => context.go(AppRoutes.salesTracking),
                      ),
                      _BusinessTile(
                        width: cardWidth,
                        color: const Color(0xFF8DE2DA),
                        iconWidget: SvgPicture.asset('assets/images/GraphIcon.svg'),
                        title: 'Business Insights',
                        subtitle: 'updated 5 min ago',
                        iconSize: 65,
                        onTap: () => context.push(AppRoutes.businessInsights),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.businessName});

  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              style: const TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Home',
              style: TextStyle(
                color: Color(0xFF6C7078),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
        const Spacer(),
        const LogoutButton(),
      ],
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.width,
    required this.color,
    required this.iconWidget,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconSize = 36,
    this.iconContainerSize,
  }) : iconAlignment = Alignment.topRight;

  final double width;
  final Color color;
  final Widget iconWidget;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final double iconSize;
  final double? iconContainerSize;
  final Alignment iconAlignment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 1.05,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Align(
              alignment: iconAlignment,
              child: SizedBox(
                width: iconContainerSize ?? iconSize,
                height: iconContainerSize ?? iconSize,
                child: iconWidget,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
