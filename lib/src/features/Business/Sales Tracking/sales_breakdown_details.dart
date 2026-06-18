part of 'sales_breakdown_screen.dart';

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: method.badgeColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: method == PaymentMethod.cash
          ? SvgPicture.asset(
              'assets/images/Note.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(method.badgeColor, BlendMode.srcIn),
            )
          : Icon(
              Icons.smartphone,
              color: method.badgeColor,
              size: 20,
            ),
    );
  }
}

class _ReceiptDetails extends StatelessWidget {
  const _ReceiptDetails({required this.transaction});

  final _Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        ...transaction.items.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${line.quantity} x ${line.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  'R${line.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        const _DottedDivider(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              'R${transaction.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Payment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            Text(
              transaction.method.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();

        return Row(
          children: List.generate(dashCount, (index) {
            return Container(
              width: dashWidth,
              height: 1,
              margin: EdgeInsets.only(right: index == dashCount - 1 ? 0 : dashSpace),
              color: _SalesBreakdownScreenState._cardBorder.withOpacity(0.9),
            );
          }),
        );
      },
    );
  }
}

class _Transaction {
  const _Transaction({
    required this.time,
    required this.summary,
    required this.total,
    required this.method,
    required this.items,
  });

  final TimeOfDay time;
  final String summary;
  final double total;
  final PaymentMethod method;
  final List<_TransactionLine> items;
}

class _TransactionLine {
  const _TransactionLine({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;
}
