import 'package:flutter/material.dart';

class SalesInsightsCard extends StatelessWidget {
  const SalesInsightsCard({
    super.key,
    required this.topProduct,
    required this.slowestSeller,
    required this.bestDay,
  });

  /// {name: String, unitsSold: num} or null
  final Map<String, dynamic>? topProduct;
  final Map<String, dynamic>? slowestSeller;

  /// {day: String, avgRevenue: num} or null
  final Map<String, dynamic>? bestDay;

  static const Color _teal = Color(0xFF5DDBD0);

  String _fmtRevenue(double v) {
    final intPart = v.toInt();
    final s = intPart.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return 'R$buf avg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 16),
          if (topProduct != null) ...[
            _buildRow(
              bgColor: const Color(0xFFEAF5EA),
              iconColor: const Color(0xFF2E7D4F),
              icon: Icons.emoji_events_outlined,
              label: 'TOP PRODUCT',
              value: topProduct!['name'] as String,
              trailing: '${topProduct!['unitsSold']} sold',
            ),
            const SizedBox(height: 10),
          ],
          if (slowestSeller != null) ...[
            _buildRow(
              bgColor: const Color(0xFFFDECEC),
              iconColor: const Color(0xFFD93025),
              icon: Icons.trending_down,
              label: 'SLOWEST SELLER',
              value: slowestSeller!['name'] as String,
              trailing: '${slowestSeller!['unitsSold']} sold',
            ),
            const SizedBox(height: 10),
          ],
          if (bestDay != null)
            _buildRow(
              bgColor: const Color(0xFFFFF8DC),
              iconColor: const Color(0xFF8B6A00),
              icon: Icons.calendar_today_outlined,
              label: 'BEST DAY',
              value: bestDay!['day'] as String,
              trailing: _fmtRevenue((bestDay!['avgRevenue'] as num).toDouble()),
            ),
          if (topProduct == null && slowestSeller == null && bestDay == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No sales data for this period', style: TextStyle(color: Colors.black45)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required String label,
    required String value,
    required String trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.6)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
          Text(trailing, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }
}
