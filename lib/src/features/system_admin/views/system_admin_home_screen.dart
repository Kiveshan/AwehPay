import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/logout_button.dart';

class SystemAdminHomeScreen extends StatefulWidget {
  const SystemAdminHomeScreen({super.key});

  @override
  State<SystemAdminHomeScreen> createState() => _SystemAdminHomeScreenState();
}

class _SystemAdminHomeScreenState extends State<SystemAdminHomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final response = await _apiService.getAdminAnalyticsSummary();
      if (mounted) {
        setState(() {
          _summary = response['summary'] as Map<String, dynamic>? ?? {};
        });
      }
    } catch (_) {
      // Silently fail; fallback subtitle will be shown
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBusinesses = _summary['totalBusinesses']?.toString() ?? '';
    final analyticsSubtitle = totalBusinesses.isNotEmpty
        ? '$totalBusinesses businesses'
        : 'updated a day ago';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AdminHeader(),
              const SizedBox(height: 54),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 16.0;
                  final cardWidth = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _AdminTile(
                        width: cardWidth,
                        height: 200,
                        color: const Color(0xFFF4C4B7),
                        icon: Icons.business_rounded,
                        title: 'Businesses on the platform',
                        onTap: () => context.push(AppRoutes.businessList),
                      ),
                      _AdminTile(
                        width: cardWidth,
                        height: 200,
                        color: const Color(0xFFA9A5F4),
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Subscription Plans',
                        onTap: () => context.push(AppRoutes.subscriptionTiers),
                      ),
                      _AdminTile(
                        width: cardWidth,
                        height: 200,
                        color: const Color(0xFF4F8DB7),
                        icon: Icons.trending_up_rounded,
                        title: 'Analytics',
                        subtitle: analyticsSubtitle,
                        onTap: () => context.push(AppRoutes.analytics),
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

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: 12),
            Text(
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

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.width,
    required this.height,
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final double width;
  final double height;
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
