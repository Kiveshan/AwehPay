import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import 'purchases_screen.dart';
import 'widgets/payment_success_header.dart';
import 'widgets/payment_summary_box.dart';

class PaymentConfirmedScreen extends StatelessWidget {
  const PaymentConfirmedScreen({
    super.key,
    required this.items,
    required this.totalAmount,
    required this.collectedAmount,
  });

  final List<PurchaseItem> items;
  final double totalAmount;
  final double collectedAmount;

  double get _changeDue => collectedAmount - totalAmount;
  double get _tax => totalAmount * 0.15;
  double get _total => totalAmount;

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
                  const PaymentSuccessHeader(),
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
                  const SizedBox(height: 12),
                  PaymentSummaryBox(
                    changeDue: _changeDue,
                    subtotal: totalAmount,
                    tax: _tax,
                    total: _total,
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

