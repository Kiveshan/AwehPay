import 'package:flutter/material.dart';

class IncomeExpensesChart extends StatelessWidget {
  const IncomeExpensesChart({super.key, required this.chartData});

  /// Each entry: {day: String, income: num, expense: num}
  final List<Map<String, dynamic>> chartData;

  static const Color _incomeColor  = Color(0xFF00C4A7);
  static const Color _expenseColor = Color(0xFFF5DF8E);
  static const Color _teal         = Color(0xFF5DDBD0);

  @override
  Widget build(BuildContext context) {
    final maxVal = chartData.fold<double>(1, (m, d) {
      final inc = (d['income'] as num).toDouble();
      final exp = (d['expense'] as num).toDouble();
      return [m, inc, exp].reduce((a, b) => a > b ? a : b);
    });

    // Compute nice Y-axis max (round up to nearest 10/100/1000)
    double yMax = maxVal;
    if (yMax < 10)        yMax = 10;
    else if (yMax < 100)  yMax = (yMax / 10).ceil() * 10;
    else if (yMax < 1000) yMax = (yMax / 100).ceil() * 100;
    else                  yMax = (yMax / 1000).ceil() * 1000;

    final yLabels = [
      yMax.toInt().toString(),
      (yMax * 0.75).toInt().toString(),
      (yMax * 0.5).toInt().toString(),
      (yMax * 0.25).toInt().toString(),
      '0',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot('Income', _incomeColor),
              const SizedBox(width: 16),
              _legendDot('Expenses', _expenseColor),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels.map((l) => Text(
                    l,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[400]),
                  )).toList(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartData.map((d) {
                            final inc = (d['income'] as num).toDouble();
                            final exp = (d['expense'] as num).toDouble();
                            return _barPair(inc / yMax, exp / yMax);
                          }).toList(),
                        ),
                      ),
                      Container(height: 1, color: Colors.grey[200]),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: chartData.map((d) => Text(
                          d['day'] as String,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _barPair(double incRatio, double expRatio) {
    const maxH  = 130.0;
    const width = 14.0;
    const rad   = 5.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: (maxH * incRatio).clamp(2.0, maxH),
          decoration: BoxDecoration(
            color: _incomeColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(rad)),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: width,
          height: (maxH * expRatio).clamp(2.0, maxH),
          decoration: BoxDecoration(
            color: _expenseColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(rad)),
          ),
        ),
      ],
    );
  }
}
