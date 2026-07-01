import 'dart:async';

import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../inventory_timestamp.dart';
import 'widgets/inventory_menu_widgets.dart';

class InventoryMenuScreen extends StatefulWidget {
  const InventoryMenuScreen({super.key});

  @override
  State<InventoryMenuScreen> createState() => _InventoryMenuScreenState();
}

class _InventoryMenuScreenState extends State<InventoryMenuScreen> {
  String _selectedType = 'Product';
  final _apiService = ApiService();
  int? _lowStockCount;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _loadLowStockCount();
    // Rebuild every 30 s so the relative-time label stays current.
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatAge() {
    // Only reflect real inventory changes (a product added or removed), never
    // a plain page load / refresh.
    final ts = InventoryTimestamp.lastChangedAt;
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'updated just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'updated $m min${m == 1 ? '' : 's'} ago';
    }
    final h = diff.inHours;
    return 'updated $h hr${h == 1 ? '' : 's'} ago';
  }

  Future<void> _loadLowStockCount() async {
    try {
      final response = await _apiService.fetchProductList();
      final raw = response['products'];
      if (raw is List) {
        final count = raw.whereType<Map<String, dynamic>>().where((p) {
          final qty = ((p['stockQuantity'] as num?) ?? 0).toInt();
          final threshold = ((p['lowStockThreshold'] as num?) ?? 0).toInt();
          return qty <= threshold;
        }).length;
        if (mounted) setState(() {
          _lowStockCount = count;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _lowStockCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 340;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final horizontalPadding = isCompact ? 16.0 : 24.0;
            final sectionSpacing = isLandscape ? 18.0 : 32.0;
            final actionSpacing = isLandscape ? 18.0 : 50.0;
            final actionHeight = isLandscape ? 118.0 : 160.0;
            final contentMaxWidth =
                constraints.maxWidth > 900 ? 760.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InventoryMenuHeader(),
                      SizedBox(height: sectionSpacing),
                      InventoryTypeDropdown(
                        selectedType: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                      InventoryActionButtons(
                        stackButtons: isCompact,
                        actionHeight: actionHeight,
                        selectedType: _selectedType,
                        listSubtitle: _formatAge(),
                        onAddTap: () async {
                          await context.push(
                            _selectedType == 'Product'
                                ? AppRoutes.addProduct
                                : AppRoutes.addService,
                          );
                          if (mounted) _loadLowStockCount();
                        },
                        onListTap: () async {
                          await context.push(
                            _selectedType == 'Product'
                                ? AppRoutes.productList
                                : AppRoutes.serviceList,
                          );
                          if (mounted) _loadLowStockCount();
                        },
                      ),
                      SizedBox(height: actionSpacing),
                      if (_selectedType == 'Product' &&
                          _lowStockCount != null &&
                          _lowStockCount! > 0)
                        LowStockWarningBar(
                          count: _lowStockCount,
                          onTap: () async {
                            await context.push(AppRoutes.lowStockList);
                            if (mounted) _loadLowStockCount();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
