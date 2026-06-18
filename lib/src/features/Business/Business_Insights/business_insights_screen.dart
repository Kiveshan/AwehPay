import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'fixed_expenses_screen.dart';
import 'widgets/net_profit_card.dart';
import 'widgets/income_expenses_chart.dart';
import 'widgets/expense_breakdown_chart.dart';
import 'widgets/sales_insights_card.dart';
import 'widgets/cash_flow_card.dart';
import 'widgets/smart_tips_card.dart';

class BusinessInsightsScreen extends StatefulWidget {
  const BusinessInsightsScreen({super.key});

  @override
  State<BusinessInsightsScreen> createState() => _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState extends State<BusinessInsightsScreen> {
  DateTime _selectedDate = DateTime.now();
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  String _toDateParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _fetchAnalytics() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getAnalytics(_toDateParam(_selectedDate));
      setState(() { _analytics = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
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
      _fetchAnalytics();
    }
  }

  // ── Helpers to extract typed data from the response ──────────────

  double _d(Map<String, dynamic>? m, String key) =>
      m == null ? 0.0 : (m[key] as num? ?? 0).toDouble();

  List<Map<String, dynamic>> _list(dynamic v) =>
      v == null ? [] : List<Map<String, dynamic>>.from(v as List);

  @override
  Widget build(BuildContext context) {
    final netProfit        = _analytics?['netProfit']           as Map<String, dynamic>?;
    final chartData        = _list(_analytics?['incomeExpensesChart']);
    final expBreakdown     = _analytics?['expenseBreakdown']    as Map<String, dynamic>?;
    final salesInsights    = _analytics?['salesInsights']       as Map<String, dynamic>?;
    final cashFlow         = _analytics?['cashFlow']            as Map<String, dynamic>?;
    final tips             = _list(_analytics?['smartTips']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAnalytics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildAddFixedExpensesButton(context),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),

                if (_loading) ...[
                  const SizedBox(height: 60),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_error != null) ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.black38),
                        const SizedBox(height: 12),
                        Text('Could not load analytics', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _fetchAnalytics, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ] else ...[
                  NetProfitCard(
                    profit:   _d(netProfit, 'profit'),
                    moneyIn:  _d(netProfit, 'moneyIn'),
                    moneyOut: _d(netProfit, 'moneyOut'),
                  ),
                  const SizedBox(height: 20),
                  IncomeExpensesChart(chartData: chartData),
                  const SizedBox(height: 20),
                  ExpenseBreakdownChart(
                    total:      _d(expBreakdown, 'total'),
                    categories: _list(expBreakdown?['categories']),
                  ),
                  const SizedBox(height: 20),
                  SalesInsightsCard(
                    topProduct:    salesInsights?['topProduct']    as Map<String, dynamic>?,
                    slowestSeller: salesInsights?['slowestSeller'] as Map<String, dynamic>?,
                    bestDay:       salesInsights?['bestDay']       as Map<String, dynamic>?,
                  ),
                  const SizedBox(height: 20),
                  CashFlowCard(
                    amount: _d(cashFlow, 'amount'),
                    status: cashFlow?['status'] as String? ?? 'Healthy',
                    trend:  cashFlow?['trend']  as String? ?? '',
                  ),
                  const SizedBox(height: 20),
                  SmartTipsCard(tips: tips.isNotEmpty ? tips : _defaultTips),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _defaultTips = [
    {'icon': 'bar_chart',         'message': 'Record your first sale to unlock insights'},
    {'icon': 'lightbulb_outline', 'message': 'Add fixed expenses to track your monthly costs'},
  ];

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.contain),
        const Text(
          'Business Insights',
          style: TextStyle(color: Color(0xFF272A2F), fontSize: 24, fontWeight: FontWeight.w800),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 58, height: 34,
            decoration: BoxDecoration(color: const Color(0xFFFEEAB8), borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFixedExpensesButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FixedExpensesScreen()));
        _fetchAnalytics(); // refresh after returning from expense management
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Add Fixed Expenses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5DDBD0), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, size: 24, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
