import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/logout_button.dart';

typedef _HomeData = ({
  String businessName,
  DateTime? insightsUpdatedAt,
  String? tierName,
});

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  late final Future<_HomeData> _homeData = _fetchHomeData();

  Future<_HomeData> _fetchHomeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return (
        businessName: 'Business',
        insightsUpdatedAt: null,
        tierName: null,
      );

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final businessId = userDoc.data()?['businessId'] as String?;
    if (businessId == null || businessId.isEmpty) {
      return (
        businessName: 'Business',
        insightsUpdatedAt: null,
        tierName: null,
      );
    }

    final results = await Future.wait([
      FirebaseFirestore.instance.collection('businesses').doc(businessId).get(),
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('salesSummaries')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get(),
    ]);

    final businessDoc = results[0] as DocumentSnapshot;
    final summariesSnap = results[1] as QuerySnapshot;

    final businessData = businessDoc.data() is Map
        ? businessDoc.data() as Map<String, dynamic>
        : null;

    final name = businessData?['businessName'] as String? ?? 'Business';

    final subscriptionMap = businessData?['subscription'] as Map<String, dynamic>?;
    final tierName = subscriptionMap?['tierName'] as String?;

    DateTime? insightsUpdatedAt;
    if (summariesSnap.docs.isNotEmpty) {
      final ts = summariesSnap.docs.first.data() is Map
          ? (summariesSnap.docs.first.data()
              as Map<String, dynamic>)['updatedAt']
          : null;
      if (ts is Timestamp) insightsUpdatedAt = ts.toDate();
    }

    return (
      businessName: name,
      insightsUpdatedAt: insightsUpdatedAt,
      tierName: tierName,
    );
  }

  bool _isCardLocked({required String cardId, required String? tierName}) {
    final tier = (tierName ?? 'Basic').trim().toLowerCase();
    switch (cardId) {
      case 'sales_tracking':
        return tier == 'basic';
      case 'business_insights':
        return tier == 'basic' || tier == 'plus';
      default:
        return false;
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return 'updated ${diff.inMinutes} min ago';
    final pad = (int n) => n.toString().padLeft(2, '0');
    final timeStr = '${pad(dt.hour)}:${pad(dt.minute)}';
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    if (dtDay == today) return 'updated today at $timeStr';
    if (today.difference(dtDay).inDays == 1) return 'updated yesterday';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return 'updated ${dt.day} ${months[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final horizontalPadding = isCompact ? 16.0 : 24.0;
            final headerSpacing = isLandscape ? 24.0 : 100.0;
            final contentMaxWidth =
                constraints.maxWidth > 900 ? 820.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<_HomeData>(
                        future: _homeData,
                        builder: (context, snapshot) {
                          final name =
                              snapshot.data?.businessName ?? 'Business';
                          return _BusinessHeader(businessName: name);
                        },
                      ),
                      SizedBox(height: headerSpacing),
                      FutureBuilder<_HomeData>(
                        future: _homeData,
                        builder: (context, snapshot) {
                          final insightsSubtitle = _formatRelativeTime(
                              snapshot.data?.insightsUpdatedAt);
                          final tierName = snapshot.data?.tierName;
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 16.0;
                              final columnCount =
                                  isLandscape && constraints.maxWidth >= 640
                                      ? 4
                                      : 2;
                              final cardWidth = (constraints.maxWidth -
                                      (spacing * (columnCount - 1))) /
                                  columnCount;
                              final cardHeight =
                                  isLandscape ? 118.0 : cardWidth * 1.05;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  _BusinessTile(
                                    width: cardWidth,
                                    height: cardHeight,
                                    color: const Color(0xFFF4C4B7),
                                    iconWidget: SvgPicture.asset(
                                        'assets/images/StockCartIcon.svg'),
                                    title: 'Inventory Management',
                                    iconSize: isLandscape ? 42 : 65,
                                    onTap: () =>
                                        context.push(AppRoutes.inventoryMenu),
                                  ),
                                  _BusinessTile(
                                    width: cardWidth,
                                    height: cardHeight,
                                    color: const Color(0xFFA9A5F4),
                                    iconWidget: SvgPicture.asset(
                                        'assets/images/MoneyIcon.svg'),
                                    title: 'Purchases',
                                    iconSize: isLandscape ? 42 : 65,
                                    onTap: () =>
                                        context.push(AppRoutes.purchases),
                                  ),
                                  _BusinessTile(
                                    width: cardWidth,
                                    height: cardHeight,
                                    color: const Color(0xFF4F8DB7),
                                    iconWidget: Icon(
                                      Icons.trending_up_rounded,
                                      color: Colors.white,
                                      size: isLandscape ? 38 : 58,
                                    ),
                                    title: 'Sales Tracking',
                                    subtitle: 'updated',
                                    iconSize: isLandscape ? 38 : 58,
                                    iconContainerSize: isLandscape ? 38 : 58,
                                    isLocked: _isCardLocked(
                                      cardId: 'sales_tracking',
                                      tierName: tierName,
                                    ),
                                    onTap: () =>
                                        context.go(AppRoutes.salesTracking),
                                  ),
                                  _BusinessTile(
                                    width: cardWidth,
                                    height: cardHeight,
                                    color: const Color(0xFF8DE2DA),
                                    iconWidget: SvgPicture.asset(
                                        'assets/images/GraphIcon.svg'),
                                    title: 'Business Insights',
                                    subtitle: insightsSubtitle.isEmpty
                                        ? null
                                        : insightsSubtitle,
                                    iconSize: isLandscape ? 42 : 65,
                                    isLocked: _isCardLocked(
                                      cardId: 'business_insights',
                                      tierName: tierName,
                                    ),
                                    onTap: () => context
                                        .push(AppRoutes.businessInsights),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        ),
        const SizedBox(width: 12),
        const LogoutButton(),
      ],
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.width,
    required this.height,
    required this.color,
    required this.iconWidget,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconSize = 36,
    this.iconContainerSize,
    this.isLocked = false,
  }) : iconAlignment = Alignment.topRight;

  final double width;
  final double height;
  final Color color;
  final Widget iconWidget;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final double iconSize;
  final double? iconContainerSize;
  final Alignment iconAlignment;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final iconColor = isLocked ? Colors.white70 : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isLocked ? null : onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: iconAlignment,
                  child: SizedBox(
                    width: iconContainerSize ?? iconSize,
                    height: iconContainerSize ?? iconSize,
                    child: isLocked
                        ? Icon(
                            Icons.lock_outline,
                            color: iconColor,
                            size: iconContainerSize ?? iconSize,
                          )
                        : iconWidget,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLocked ? Colors.white54 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
