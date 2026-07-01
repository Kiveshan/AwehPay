import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryMenuHeader extends StatelessWidget {
  const InventoryMenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const Text(
          'Inventory Menu',
          style: TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        GestureDetector(
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
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class InventoryTypeDropdown extends StatelessWidget {
  const InventoryTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          style: const TextStyle(
            color: Color(0xFF6C7078),
            fontSize: 16,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Product',
              child: Text('Product'),
            ),
            DropdownMenuItem(
              value: 'Service',
              child: Text('Service'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class InventoryActionButtons extends StatelessWidget {
  const InventoryActionButtons({
    super.key,
    required this.stackButtons,
    required this.actionHeight,
    required this.selectedType,
    required this.listSubtitle,
    required this.onAddTap,
    required this.onListTap,
  });

  final bool stackButtons;
  final double actionHeight;
  final String selectedType;
  final String listSubtitle;
  final VoidCallback onAddTap;
  final VoidCallback onListTap;

  @override
  Widget build(BuildContext context) {
    final addButton = _InventoryActionButton(
      icon: Icons.add_rounded,
      label:
          selectedType == 'Product' ? 'Add Products to Stock' : 'Add Services',
      height: actionHeight,
      onTap: onAddTap,
    );
    final listButton = _InventoryActionButton(
      icon: Icons.list_rounded,
      label: selectedType == 'Product' ? 'Product List' : 'Service List',
      subtitle: listSubtitle,
      height: actionHeight,
      onTap: onListTap,
    );

    if (stackButtons) {
      return Column(
        children: [
          addButton,
          const SizedBox(height: 16),
          listButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: addButton),
        const SizedBox(width: 16),
        Expanded(child: listButton),
      ],
    );
  }
}

class _InventoryActionButton extends StatelessWidget {
  const _InventoryActionButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.height,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF5C9B7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: height < 140 ? 36 : 48,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LowStockWarningBar extends StatelessWidget {
  const LowStockWarningBar({
    super.key,
    required this.onTap,
    this.count,
  });

  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE68888),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                count == null
                    ? 'Low Stock Warnings'
                    : '$count Low Stock Warning${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (count == null)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
