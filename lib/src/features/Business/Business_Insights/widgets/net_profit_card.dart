import 'package:flutter/material.dart';

class NetProfitCard extends StatelessWidget {
  const NetProfitCard({
    super.key,
    required this.profit,
    required this.moneyIn,
    required this.moneyOut,
  });

  final double profit;
  final double moneyIn;
  final double moneyOut;

  static const Color _cardBg = Color(0xFF5DDBD0);

  String _fmt(double v) {
    final sign = v < 0 ? '-' : '';
    final abs  = v.abs();
    final int intPart = abs.toInt();
    final String dec  = ((abs - intPart) * 100).toInt().toString().padLeft(2, '0');
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Profit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(profit),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSubCard(label: 'Money In',  amount: _fmt(moneyIn))),
              const SizedBox(width: 12),
              Expanded(child: _buildSubCard(label: 'Money Out', amount: _fmt(moneyOut))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubCard({required String label, required String amount}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
