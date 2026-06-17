import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_action_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Welcome back',
              style: textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your money with confidence.',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            const BalanceCard(),
            const SizedBox(height: 24),
            Text(
              'Quick actions',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.send_rounded,
                    label: 'Send',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.call_received_rounded,
                    label: 'Receive',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Pay',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
