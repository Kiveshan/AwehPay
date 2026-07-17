import 'dart:async';

import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/services/purchase_service.dart';
import 'core/theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AwePayApp extends StatefulWidget {
  const AwePayApp({super.key});

  @override
  State<AwePayApp> createState() => _AwePayAppState();
}

class _AwePayAppState extends State<AwePayApp> {
  StreamSubscription<PurchaseUiStatus>? _purchaseStatusSubscription;

  @override
  void initState() {
    super.initState();
    // Attached once at app bootstrap (not lazily on the paywall screen) so purchases
    // left unfinished by a killed app are still redelivered and processed on relaunch.
    PurchaseService.instance.init();
    _purchaseStatusSubscription =
        PurchaseService.instance.statusStream.listen(_showPurchaseStatus);
  }

  @override
  void dispose() {
    _purchaseStatusSubscription?.cancel();
    super.dispose();
  }

  void _showPurchaseStatus(PurchaseUiStatus status) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    String message;
    switch (status.type) {
      case PurchaseUiStatusType.pending:
        message = 'Processing your purchase...';
        break;
      case PurchaseUiStatusType.success:
        message = 'Subscription activated. Enjoy your new plan!';
        break;
      case PurchaseUiStatusType.canceled:
        return; // No-op, matches Play Billing UX conventions.
      case PurchaseUiStatusType.error:
        message = status.message ?? 'Something went wrong with your purchase.';
        break;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AwePay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
