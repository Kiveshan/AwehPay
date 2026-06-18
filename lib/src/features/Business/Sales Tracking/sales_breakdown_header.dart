part of 'sales_breakdown_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Sales Tracking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.pop(),
          child: Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEEAB8),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}
