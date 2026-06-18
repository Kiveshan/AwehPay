import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import 'widgets/admin_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await _apiService.getAdminAnalyticsSummary();
      if (mounted) {
        setState(() {
          _summary = response['summary'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Analytics',
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 120,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatCard(
                            label: 'Total Businesses',
                            value: _summary['totalBusinesses']?.toString() ?? '0',
                            icon: Icons.business_rounded,
                            color: const Color(0xFFF4C4B7),
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Total Users',
                            value: _summary['totalUsers']?.toString() ?? '0',
                            icon: Icons.people_rounded,
                            color: const Color(0xFFA9A5F4),
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Subscription Plans',
                            value: _summary['totalSubscriptionTiers']?.toString() ?? '0',
                            icon: Icons.volunteer_activism_rounded,
                            color: const Color(0xFF4F8DB7),
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Active Businesses',
                            value: _summary['activeBusinesses']?.toString() ?? '0',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF2196F3),
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Inactive Businesses',
                            value: _summary['inactiveBusinesses']?.toString() ?? '0',
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFE57373),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Businesses per Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF272A2F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildTierSubscriberRows(),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTierSubscriberRows() {
    final tiers = _summary['tierSubscribers'] as List<dynamic>? ?? [];
    if (tiers.isEmpty) {
      return [
        const Text(
          'No data available',
          style: TextStyle(color: Color(0xFF6C7078)),
        ),
      ];
    }

    return tiers.map((tier) {
      final name = tier['tierName']?.toString() ?? 'Unknown';
      final count = tier['subscriberCount']?.toString() ?? '0';
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272A2F),
                ),
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7B61FF),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C7078),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF272A2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
