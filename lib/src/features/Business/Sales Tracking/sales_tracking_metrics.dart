part of 'sales_tracking_screen.dart';

class _SalesMetricsGrid extends StatelessWidget {
  const _SalesMetricsGrid({required this.metrics});

  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final topSale = (metrics['topSale'] as num?)?.toDouble() ?? 0.0;
    final busiestHour = (metrics['busiestHour'] as String?) ?? '--:00 - --:00';
    final bestSeller = (metrics['bestSeller'] as String?) ?? 'N/A';
    final bestSellerQty = (metrics['bestSellerUnits'] as num?)?.toInt() ?? 0;
    final slowestSeller = (metrics['slowestSeller'] as String?) ?? 'N/A';
    final slowestStock = (metrics['slowestSellerStock'] as num?)?.toInt() ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxis = constraints.maxWidth >= 600 ? 4 : 2;
        final itemWidth = (constraints.maxWidth - (crossAxis - 1) * 16) / crossAxis;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricTile(
              icon: Icons.emoji_events_outlined,
              iconColor: const Color(0xFFF6B332),
              label: 'Top Sale',
              value: topSale > 0 ? 'R${topSale.toStringAsFixed(0)}' : 'R0',
              detail: '',
            ),
            _MetricTile(
              icon: Icons.local_fire_department_outlined,
              iconColor: const Color(0xFFF6B332),
              label: 'Busiest Hour',
              value: busiestHour,
              detail: '',
            ),
            _MetricTile(
              icon: Icons.star_outline,
              iconColor: const Color(0xFFF6B332),
              label: 'Best Seller',
              value: bestSeller,
              detail: bestSellerQty > 0 ? '$bestSellerQty units sold today' : '',
            ),
            _MetricTile(
              icon: Icons.sentiment_neutral,
              iconColor: const Color(0xFFF6B332),
              label: 'Slowest Seller',
              value: slowestSeller,
              detail: slowestStock > 0 ? '$slowestStock units still in stock' : '',
            ),
          ].map((tile) {
            return SizedBox(
              width: itemWidth,
              child: tile,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SalesBreakdownCard extends StatelessWidget {
  const _SalesBreakdownCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF125D95)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BreakdownHeader(title: title),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: SalesTrackingScreen._textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/SalesBreakdown.svg',
          width: 25,
          height: 25,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
