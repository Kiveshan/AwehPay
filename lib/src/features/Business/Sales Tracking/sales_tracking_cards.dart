part of 'sales_tracking_screen.dart';

class _TodaySalesCard extends StatelessWidget {
  const _TodaySalesCard({
    required this.title,
    required this.summary,
    required this.trend,
  });

  final String title;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> trend;

  @override
  Widget build(BuildContext context) {
    final totalSales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
    final cashCount = (summary['cashCount'] as num?)?.toInt() ?? 0;
    final digitalCount = (summary['digitalCount'] as num?)?.toInt() ?? 0;
    final totalCount = (summary['totalTransactions'] as num?)?.toInt() ?? 0;
    final cashSales = (summary['cashSales'] as num?)?.toDouble() ?? 0.0;
    final digitalSales = (summary['digitalSales'] as num?)?.toDouble() ?? 0.0;
    final trendPct = (trend['percentage'] as num?)?.toDouble() ?? 0.0;
    final trendDirection = (trend['direction'] as String?) ?? 'up';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SalesTrackingScreen._primaryBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _TrendChip(percentage: trendPct, direction: trendDirection),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'R ${totalSales.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalCount sales',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SalesTrackingScreen._softBlue.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$cashCount  Cash',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'R${cashSales.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$digitalCount  Digital',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'R${digitalSales.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (totalSales > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: cashSales / totalSales,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(SalesTrackingScreen._accentYellow),
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
