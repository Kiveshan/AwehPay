library sales_breakdown_screen;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';

part 'sales_breakdown_header.dart';
part 'sales_breakdown_tile.dart';
part 'sales_breakdown_details.dart';

class SalesBreakdownArgs {
  const SalesBreakdownArgs({required this.date, required this.title});

  final DateTime date;
  final String title;
}

class SalesBreakdownScreen extends StatefulWidget {
  const SalesBreakdownScreen({super.key, required this.args});

  final SalesBreakdownArgs args;

  @override
  State<SalesBreakdownScreen> createState() => _SalesBreakdownScreenState();
}

class _SalesBreakdownScreenState extends State<SalesBreakdownScreen> {
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _cardBorder = Color(0xFFD6E1ED);
  static const _cardShadow = Color(0x143D7FB4);
  static const _labelColor = Color(0xFF5C6C80);
  static const _accentYellow = Color(0xFFF1C75B);
  static const _cashGreen = Color(0xFF3FB27F);

  final _apiService = ApiService();
  List<_Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr =
          '${widget.args.date.year}-${widget.args.date.month.toString().padLeft(2, '0')}-${widget.args.date.day.toString().padLeft(2, '0')}';
      debugPrint('[SalesBreakdownScreen] Fetching transactions for date: $dateStr');
      final result = await _apiService.getTransactions(date: dateStr);
      debugPrint('[SalesBreakdownScreen] API response: $result');

      if (!mounted) return;

      final rawTx = result['transactions'] as List<dynamic>? ?? [];
      final txs = rawTx.map((raw) {
        final timeMap = raw['time'] as Map<String, dynamic>? ?? {};
        final rawItems = raw['items'] as List<dynamic>? ?? [];
        final items = rawItems.map((i) {
          return _TransactionLine(
            name: i['name'] as String? ?? 'Unknown',
            quantity: (i['quantity'] as num?)?.toInt() ?? 0,
            price: (i['price'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        return _Transaction(
          time: TimeOfDay(
            hour: (timeMap['hour'] as num?)?.toInt() ?? 0,
            minute: (timeMap['minute'] as num?)?.toInt() ?? 0,
          ),
          summary: raw['summary'] as String? ?? '',
          total: (raw['total'] as num?)?.toDouble() ?? 0.0,
          method: (raw['paymentMethod'] as String?) == 'cash'
              ? PaymentMethod.cash
              : PaymentMethod.digital,
          items: items,
        );
      }).toList();

      txs.sort((a, b) => _timeToMinutes(b.time).compareTo(_timeToMinutes(a.time)));

      setState(() => _transactions = txs);
    } catch (e) {
      debugPrint('[SalesBreakdownScreen] API error: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              Text(
                widget.args.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
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
              else if (_transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No transactions for this date.',
                      style: TextStyle(
                        fontSize: 16,
                        color: _labelColor,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final expanded = _expandedIndex == index;
                    return _TransactionTile(
                      transaction: transaction,
                      expanded: expanded,
                      onTap: () {
                        setState(() {
                          _expandedIndex = expanded ? null : index;
                        });
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _transactions.length,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;
}
