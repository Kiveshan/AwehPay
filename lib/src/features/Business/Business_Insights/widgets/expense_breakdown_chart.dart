import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExpenseBreakdownChart extends StatelessWidget {
  const ExpenseBreakdownChart({
    super.key,
    required this.total,
    required this.categories,
  });

  /// Total monthly expenses amount
  final double total;

  /// Each entry: {name: String, amount: num, fraction: num, colorHex: String}
  final List<Map<String, dynamic>> categories;

  static const Color _teal = Color(0xFF5DDBD0);

  static Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _fmtAmount(double v) {
    final intPart = v.toInt();
    final s = intPart.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return 'R$buf';
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _teal, width: 1.5),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where money goes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            SizedBox(height: 3),
            Text('By category this month', style: TextStyle(fontSize: 12, color: Colors.black45)),
            SizedBox(height: 20),
            Center(child: Text('No expense data for this period', style: TextStyle(color: Colors.black45))),
          ],
        ),
      );
    }

    final segments = categories.map((c) => _Segment(
      c['name'] as String,
      _fmtAmount((c['amount'] as num).toDouble()),
      _hexColor(c['colorHex'] as String),
      (c['fraction'] as num).toDouble(),
    )).toList();

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
          const Text('Where money goes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 3),
          const Text('By category this month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black45)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(size: const Size(130, 130), painter: _DonutPainter(segments)),
                    Text(
                      _fmtAmount(total),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segments.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(width: 11, height: 11, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
                        Text(
                          s.amount,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment {
  final String label;
  final String amount;
  final Color color;
  final double fraction;
  const _Segment(this.label, this.amount, this.color, this.fraction);
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  const _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    const strokeWidth = 22.0;
    final paintRadius = outerRadius - strokeWidth / 2;
    const gapAngle    = 0.03;

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.fraction * 2 * math.pi - gapAngle;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: paintRadius),
        startAngle, sweep, false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}
