part of 'sales_tracking_screen.dart';

class _SalesMetricsGrid extends StatelessWidget {
  const _SalesMetricsGrid({required this.metrics});

  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final topSale = (metrics['topSale'] as num?)?.toDouble() ?? 0.0;
    final busiestHour = _shiftHourRange((metrics['busiestHour'] as String?) ?? '--:00 - --:00', 2);
    final bestSeller = (metrics['bestSeller'] as String?) ?? 'N/A';
    final bestSellerQty = (metrics['bestSellerUnits'] as num?)?.toInt() ?? 0;
    final slowestSeller = (metrics['slowestSeller'] as String?) ?? 'N/A';
    final slowestStock = (metrics['slowestSellerStock'] as num?)?.toInt() ?? 0;

    final tiles = [
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
        detail: bestSellerQty > 0 ? '$bestSellerQty ${bestSellerQty == 1 ? 'unit' : 'units'} sold today' : '',
      ),
      _MetricTile(
        icon: Icons.sentiment_neutral,
        iconColor: const Color(0xFFF6B332),
        label: 'Slowest Seller',
        value: slowestSeller,
        detail: slowestStock > 0 ? '$slowestStock ${slowestStock == 1 ? 'unit' : 'units'} still in stock' : '',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screens: all 4 in one IntrinsicHeight row
        if (constraints.maxWidth >= 600) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 16),
                Expanded(child: tiles[1]),
                const SizedBox(width: 16),
                Expanded(child: tiles[2]),
                const SizedBox(width: 16),
                Expanded(child: tiles[3]),
              ],
            ),
          );
        }

        // Narrow screens: 2×2 grid using IntrinsicHeight per row so each
        // pair always matches the height of the taller card in that row
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 16),
                  Expanded(child: tiles[1]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 16),
                  Expanded(child: tiles[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


// Shifts a "HH:00 - HH:00" string by [hours] hours
String _shiftHourRange(String value, int hours) {
  final parts = value.split(' - ');
  if (parts.length != 2) return value;
  final startHour = int.tryParse(parts[0].split(':')[0]);
  final endHour = int.tryParse(parts[1].split(':')[0]);
  if (startHour == null || endHour == null) return value;
  final s = ((startHour + hours) % 24).toString().padLeft(2, '0');
  final e = ((endHour + hours) % 24).toString().padLeft(2, '0');
  return '$s:00 - $e:00';
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
