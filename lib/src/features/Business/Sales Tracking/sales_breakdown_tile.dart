part of 'sales_breakdown_screen.dart';

enum PaymentMethod { cash, digital }

extension on PaymentMethod {
  String get label => this == PaymentMethod.cash ? 'Cash' : 'Digital';

  Color get badgeColor => this == PaymentMethod.cash
      ? _SalesBreakdownScreenState._cashGreen
      : _SalesBreakdownScreenState._accentYellow;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.expanded,
    required this.onTap,
  });

  final _Transaction transaction;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = transaction.time.format(context);
    final summary = transaction.summary;
    final amount = 'R${transaction.total.toStringAsFixed(2)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: _SalesBreakdownScreenState._cardShadow,
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PaymentBadge(method: transaction.method),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _SalesBreakdownScreenState._labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.method.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _SalesBreakdownScreenState._labelColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _ReceiptDetails(transaction: transaction),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
