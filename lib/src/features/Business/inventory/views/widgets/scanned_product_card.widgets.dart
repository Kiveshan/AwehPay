part of 'scanned_product_card.dart';

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VatCheckbox extends StatelessWidget {
  const _VatCheckbox({required this.vatNotifier});

  final ValueNotifier<bool> vatNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: vatNotifier,
      builder: (context, vatEnabled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VAT',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Checkbox(
                  value: vatEnabled,
                  onChanged: (v) => vatNotifier.value = v ?? false,
                  activeColor: const Color(0xFFDFA890),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  vatEnabled ? 'VAT Included' : 'No VAT',
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9CED6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefixText != null) ...[
                const SizedBox(width: 10),
                Text(
                  prefixText!,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
