import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProcessingInvoiceOverlay extends StatefulWidget {
  const ProcessingInvoiceOverlay({super.key});

  @override
  State<ProcessingInvoiceOverlay> createState() =>
      _ProcessingInvoiceOverlayState();
}

class _ProcessingInvoiceOverlayState extends State<ProcessingInvoiceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _DotCirclePainter(progress: _controller.value),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Processing Invoice',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DotCirclePainter extends CustomPainter {
  const _DotCirclePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const dotCount = 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const dotRadius = 4.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final offset = Offset(
        center.dx + radius * math.cos(angle - math.pi / 2),
        center.dy + radius * math.sin(angle - math.pi / 2),
      );
      final distFromActive = ((i / dotCount) - progress + 1) % 1;
      final opacity = (1 - distFromActive).clamp(0.15, 1.0);
      canvas.drawCircle(
        offset,
        dotRadius,
        Paint()
          ..color =
              const Color(0xFFB8A9E8).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_DotCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
