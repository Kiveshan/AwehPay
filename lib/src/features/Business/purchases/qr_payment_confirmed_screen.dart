import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import 'purchases_screen.dart';
import 'widgets/summary_row.dart';

class QRPaymentConfirmedScreen extends StatelessWidget {
  const QRPaymentConfirmedScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  final List<PurchaseItem> items;
  final double totalAmount;

  double get _tax => totalAmount * 0.10;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchases',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9ED79A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Payment confirmed',
                      style: TextStyle(
                        color: Color(0xFF9ED79A),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Color(0xFF272A2F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.barcode,
                                    style: const TextStyle(
                                      color: Color(0xFF9B9B9B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.price,
                              style: const TextStyle(
                                color: Color(0xFF272A2F),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SummaryRow(
                          label: 'Subtotal',
                          value: 'R${totalAmount.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        const SizedBox(height: 12),
                        SummaryRow(
                          label: 'Tax (10%)',
                          value: 'R${_tax.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        const Divider(height: 24, color: Color(0xFFE0E0E0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Color(0xFF272A2F),
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Success',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'R${totalAmount.toInt()}',
                                  style: const TextStyle(
                                    color: Color(0xFF9ED79A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AdminPrimaryButton(
              label: 'Back to Home',
              icon: Icons.home_outlined,
              onPressed: () => context.go(AppRoutes.businessHome),
            ),
          ),
        ],
      ),
    );
  }
}

