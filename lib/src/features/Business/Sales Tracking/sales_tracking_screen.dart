library sales_tracking_screen;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_service.dart';
import 'sales_breakdown_screen.dart';

part 'sales_tracking_header.dart';
part 'sales_tracking_cards.dart';
part 'sales_tracking_trend.dart';
part 'sales_tracking_metrics.dart';

class SalesTrackingScreen extends StatefulWidget {
  const SalesTrackingScreen({super.key});

  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _primaryBlue = Color(0xFF3D7FB4);
  static const _accentYellow = Color(0xFFF1C75B);
  static const _softBlue = Color(0xFF5EA4D2);
  static const _cardBorderColor = Color(0xFFD6E1ED);
  static const _textSecondary = Color(0xFF5C6C80);

  @override
  State<SalesTrackingScreen> createState() => _SalesTrackingScreenState();
}

class _SalesTrackingScreenState extends State<SalesTrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _trend = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String _breakdownTitle(DateTime date) {
    if (_isToday(date)) return "Today's Sale Breakdown";
    return '${_formatDate(date)} Sale Breakdown';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      debugPrint('[SalesTrackingScreen] Fetching summary for date: $dateStr');
      final result = await _apiService.getDailySalesSummary(date: dateStr);
      debugPrint('[SalesTrackingScreen] API response: $result');

      if (!mounted) return;

      setState(() {
        _summary = result['summary'] as Map<String, dynamic>? ?? {};
        _metrics = result['metrics'] as Map<String, dynamic>? ?? {};
        _trend = result['trend'] as Map<String, dynamic>? ?? {};
      });
    } catch (e) {
      debugPrint('[SalesTrackingScreen] API error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDate(_selectedDate);
    final breakdownTitle = _breakdownTitle(_selectedDate);
    final salesTitle = _isToday(_selectedDate)
        ? "Today's Sales"
        : '$formatted Sales';
    final totalCount = (_summary['totalTransactions'] as num?)?.toInt() ?? 0;
    final breakdownSubtitle = _isToday(_selectedDate)
        ? '$totalCount sales today'
        : '$totalCount sales on $formatted';

    return Scaffold(
      backgroundColor: SalesTrackingScreen._backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              _DateSelector(date: formatted, onTap: _pickDate),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                _TodaySalesCard(
                  title: salesTitle,
                  summary: _summary,
                  trend: _trend,
                ),
                const SizedBox(height: 24),
                _SalesMetricsGrid(metrics: _metrics),
                const SizedBox(height: 24),
                _SalesBreakdownCard(
                  title: breakdownTitle,
                  subtitle: breakdownSubtitle,
                  onTap: () {
                    context.push(
                      AppRoutes.salesBreakdown,
                      extra: SalesBreakdownArgs(
                        date: _selectedDate,
                        title: breakdownTitle,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
