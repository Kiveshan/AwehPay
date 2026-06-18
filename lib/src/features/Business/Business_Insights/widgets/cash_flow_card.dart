import 'package:flutter/material.dart';

class CashFlowCard extends StatelessWidget {
  const CashFlowCard({
    super.key,
    required this.amount,
    required this.status,
    required this.trend,
  });

  final double amount;
  final String status;
  final String trend;

  static const Color _bgDark  = Color(0xFF0D4A3A);
  static const Color _bgLight = Color(0xFF1A5C49);

  String _fmt(double v) {
    final sign = v < 0 ? '-' : '';
    final abs  = v.abs();
    final intPart = abs.toInt();
    final dec     = ((abs - intPart) * 100).toInt().toString().padLeft(2, '0');
    final s = intPart.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${sign}R$buf.$dec';
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = status == 'Healthy';
    return Container(
      width: double.infinity,
      height: 160,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgDark, _bgLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePainter(isHealthy: isHealthy))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash Flow', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHealthy ? Icons.north_east : Icons.south_east,
                            size: 13,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_fmt(amount), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(trend, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.isHealthy});
  final bool isHealthy;

  @override
  void paint(Canvas canvas, Size size) {
    final waveColor = isHealthy ? const Color(0xFFD4B86A) : const Color(0xFFE68888);

    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.72);
    wavePath.cubicTo(size.width * 0.15, size.height * 0.78, size.width * 0.28, size.height * 0.62, size.width * 0.45, size.height * 0.58);
    wavePath.cubicTo(size.width * 0.60, size.height * 0.54, size.width * 0.72, size.height * 0.48, size.width * 0.85, size.height * 0.40);
    wavePath.cubicTo(size.width * 0.92, size.height * 0.36, size.width * 0.96, size.height * 0.34, size.width, size.height * 0.32);

    canvas.drawPath(wavePath, Paint()
      ..color = waveColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    final fillPath = Path()..addPath(wavePath, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2E7D5A).withValues(alpha: 0.70),
          const Color(0xFF1A5C49).withValues(alpha: 0.90),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.isHealthy != isHealthy;
}
