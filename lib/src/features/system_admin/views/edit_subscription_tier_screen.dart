import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_tier.dart';
import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';

class EditSubscriptionTierScreen extends StatefulWidget {
  const EditSubscriptionTierScreen({super.key, this.tier});

  final SubscriptionTier? tier;

  @override
  State<EditSubscriptionTierScreen> createState() =>
      _EditSubscriptionTierScreenState();
}

class _EditSubscriptionTierScreenState
    extends State<EditSubscriptionTierScreen> {
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'ZAR');
  final _billingPeriodController = TextEditingController(text: 'monthly');
  final _setupFeeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();
  final _featuresController = TextEditingController();

  final _maxProductsController = TextEditingController();
  final _maxServicesController = TextEditingController();
  final _maxCardPaymentsController = TextEditingController();

  bool _isActive = true;
  bool _isRecommended = false;
  bool _barcodeScanner = false;
  bool _lowStockAlerts = false;
  bool _analytics = false;
  bool _cashSales = true;
  bool _cardPayments = true;
  bool _expenseTracking = false;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.tier != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadTierValues();
    }
  }

  void _loadTierValues() {
    final tier = widget.tier!;
    _nameController.text = tier.name;
    _codeController.text = tier.code;
    _priceController.text = tier.price.toString();
    _currencyController.text = tier.currency;
    _billingPeriodController.text = tier.billingPeriod;
    _setupFeeController.text = tier.setupFee.toString();
    _descriptionController.text = tier.description;
    _displayOrderController.text = tier.displayOrder.toString();
    _featuresController.text = tier.features.join('\n');

    _maxProductsController.text = tier.limits.maxProducts?.toString() ?? '';
    _maxServicesController.text = tier.limits.maxServices?.toString() ?? '';
    _maxCardPaymentsController.text =
        tier.limits.maxCardPaymentsPerDay?.toString() ?? '';

    _isActive = tier.isActive;
    _isRecommended = tier.isRecommended;
    _barcodeScanner = tier.limits.barcodeScannerEnabled;
    _lowStockAlerts = tier.limits.lowStockAlertsEnabled;
    _analytics = tier.limits.analyticsEnabled;
    _cashSales = tier.limits.cashSalesEnabled;
    _cardPayments = tier.limits.cardPaymentsEnabled;
    _expenseTracking = tier.limits.expenseTrackingEnabled;
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final setupFee = double.tryParse(_setupFeeController.text.trim()) ?? 0;
    final displayOrder = int.tryParse(_displayOrderController.text.trim()) ?? 0;

    if (name.isEmpty || code.isEmpty) {
      setState(() => _errorMessage = 'Name and code are required');
      return;
    }

    final features = _featuresController.text
        .split('\n')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    final limits = <String, dynamic>{
      'maxProducts': int.tryParse(_maxProductsController.text.trim()),
      'maxServices': int.tryParse(_maxServicesController.text.trim()),
      'maxCardPaymentsPerDay':
          int.tryParse(_maxCardPaymentsController.text.trim()),
      'barcodeScannerEnabled': _barcodeScanner,
      'lowStockAlertsEnabled': _lowStockAlerts,
      'analyticsEnabled': _analytics,
      'cashSalesEnabled': _cashSales,
      'cardPaymentsEnabled': _cardPayments,
      'expenseTrackingEnabled': _expenseTracking,
    };

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await _apiService.updateSubscriptionTier(
          tierId: widget.tier!.tierId,
          name: name,
          code: code,
          price: price,
          currency: _currencyController.text.trim(),
          billingPeriod: _billingPeriodController.text.trim(),
          setupFee: setupFee,
          description: _descriptionController.text.trim(),
          displayOrder: displayOrder,
          isActive: _isActive,
          isRecommended: _isRecommended,
          features: features,
          limits: limits,
        );
      } else {
        await _apiService.createSubscriptionTier(
          name: name,
          code: code,
          price: price,
          currency: _currencyController.text.trim(),
          billingPeriod: _billingPeriodController.text.trim(),
          setupFee: setupFee,
          description: _descriptionController.text.trim(),
          displayOrder: displayOrder,
          isActive: _isActive,
          isRecommended: _isRecommended,
          features: features,
          limits: limits,
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _billingPeriodController.dispose();
    _setupFeeController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _featuresController.dispose();
    _maxProductsController.dispose();
    _maxServicesController.dispose();
    _maxCardPaymentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _isEditing ? 'Edit Plan' : 'New Plan',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Plan Details'),
              AdminTextField(
                label: 'Name',
                hintText: 'e.g. Basic, Plus, Premium',
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Code',
                hintText: 'e.g. basic, plus, premium',
                controller: _codeController,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Price',
                hintText: 'e.g. 0 for free',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Currency',
                controller: _currencyController,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Billing Period',
                hintText: 'e.g. monthly, yearly, free',
                controller: _billingPeriodController,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Setup Fee',
                controller: _setupFeeController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Description',
                controller: _descriptionController,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Display Order',
                hintText: '0, 1, 2...',
                controller: _displayOrderController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Features (one per line)'),
              AdminTextField(
                label: 'Features',
                hintText: 'Cash Sales\nUp to 50 Products\n...',
                controller: _featuresController,
                maxLines: 6,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Limits'),
              AdminTextField(
                label: 'Max Products (leave blank for unlimited)',
                controller: _maxProductsController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Max Services (leave blank for unlimited)',
                controller: _maxServicesController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Max Card Payments/Day (leave blank for unlimited)',
                controller: _maxCardPaymentsController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildToggle('Active', _isActive, (v) => setState(() => _isActive = v)),
              _buildToggle('Recommended', _isRecommended, (v) => setState(() => _isRecommended = v)),
              _buildToggle('Barcode Scanner', _barcodeScanner, (v) => setState(() => _barcodeScanner = v)),
              _buildToggle('Low Stock Alerts', _lowStockAlerts, (v) => setState(() => _lowStockAlerts = v)),
              _buildToggle('Analytics', _analytics, (v) => setState(() => _analytics = v)),
              _buildToggle('Cash Sales', _cashSales, (v) => setState(() => _cashSales = v)),
              _buildToggle('Card Payments', _cardPayments, (v) => setState(() => _cardPayments = v)),
              _buildToggle('Expense Tracking', _expenseTracking, (v) => setState(() => _expenseTracking = v)),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              AdminPrimaryButton(
                label: _isLoading ? 'Saving...' : 'Save',
                icon: Icons.save,
                onPressed: _isLoading ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF272A2F),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C7078),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF7B61FF),
        ),
      ],
    );
  }
}
