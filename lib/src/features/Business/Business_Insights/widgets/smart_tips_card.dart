import 'package:flutter/material.dart';

class SmartTipsCard extends StatefulWidget {
  const SmartTipsCard({super.key, required this.tips});

  /// Each entry: {icon: String, message: String}
  final List<Map<String, dynamic>> tips;

  @override
  State<SmartTipsCard> createState() => _SmartTipsCardState();
}

class _SmartTipsCardState extends State<SmartTipsCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _teal     = Color(0xFF5DDBD0);
  static const Color _iconGold = Color(0xFFF5C518);

  static const _iconMap = <String, IconData>{
    'bar_chart':        Icons.bar_chart,
    'layers':           Icons.layers,
    'trending_up':      Icons.trending_up,
    'trending_down':    Icons.trending_down,
    'lightbulb_outline':Icons.lightbulb_outline,
    'warning':          Icons.warning_amber_outlined,
    'warning_outlined': Icons.warning_amber_outlined,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = widget.tips;
    final pageCount = (tips.length / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Tips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (p) => setState(() => _currentPage = p),
            itemBuilder: (context, pageIndex) {
              final left  = pageIndex * 2;
              final right = left + 1;
              return Row(
                children: [
                  Expanded(child: _buildTipCard(tips[left])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: right < tips.length ? _buildTipCard(tips[right]) : const SizedBox(),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 16,
              height: 5,
              decoration: BoxDecoration(
                color: active ? _teal : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final iconKey  = tip['icon'] as String? ?? 'bar_chart';
    final iconData = _iconMap[iconKey] ?? Icons.bar_chart;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(iconData, color: _iconGold, size: 32)),
          const SizedBox(height: 14),
          Text(
            tip['message'] as String? ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
}
