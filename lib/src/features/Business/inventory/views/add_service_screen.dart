import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../inventory_timestamp.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  bool _isServiceAdded = false;
  bool _isSavingService = false;
  final _apiService = ApiService();
  final _serviceNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _durationController.dispose();
    _costPriceController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final horizontalPadding = isCompact ? 16.0 : 24.0;
            final topSpacing = isLandscape ? 20.0 : 48.0;
            final formMaxWidth =
                constraints.maxWidth > 700 ? 640.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(title: 'Add Service'),
                      SizedBox(height: topSpacing),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isCompact ? 12 : 14),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDFA890))),
                        child: Column(
                          children: [
                            if (_isServiceAdded) ...[
                              const _ServiceAddedStatus(),
                              const SizedBox(height: 24),
                            ],
                            _InputField(
                              label: 'Service Name',
                              controller: _serviceNameController,
                            ),
                            const SizedBox(height: 18),
                            _CategoryDropdown(
                              label: 'Service Category',
                              value: _selectedCategory,
                              hint: 'Select a category',
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                            if (_selectedCategory == 'Other') ...[
                              const SizedBox(height: 18),
                              _InputField(
                                label: 'Other Service Category',
                                controller: _otherCategoryController,
                              ),
                            ],
                            const SizedBox(height: 18),
                            _ServicePricingFields(
                              stackFields: isCompact,
                              durationController: _durationController,
                              costPriceController: _costPriceController,
                              onIncrement: () {
                                final value =
                                    int.tryParse(_durationController.text) ?? 0;
                                _durationController.text = '${value + 5}';
                              },
                              onDecrement: () {
                                final value =
                                    int.tryParse(_durationController.text) ?? 0;
                                if (value >= 5) {
                                  _durationController.text = '${value - 5}';
                                }
                              },
                            ),
                            if (!_isServiceAdded) ...[
                              const SizedBox(height: 24),
                              _PrimaryButton(
                                label: _isSavingService
                                    ? 'Adding...'
                                    : 'Add Service',
                                icon:
                                    _isSavingService ? null : Icons.add_rounded,
                                isLoading: _isSavingService,
                                onTap: _isSavingService ? null : _saveService,
                              ),
                            ],
                          ],
                        ),
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

  Future<void> _saveService() async {
    final name = _serviceNameController.text.trim();
    final category = _selectedCategory == 'Other'
        ? _otherCategoryController.text.trim()
        : (_selectedCategory ?? '');
    final durationMinutes = int.tryParse(_durationController.text.trim());
    final costPrice = _parseMoney(_costPriceController.text);

    if (name.isEmpty ||
        category.isEmpty ||
        durationMinutes == null ||
        costPrice == null) {
      _showError(
        'Please complete all service details before adding the service.',
      );
      return;
    }

    setState(() {
      _isSavingService = true;
    });

    try {
      await _apiService.addService(
        name: name,
        category: category,
        durationMinutes: durationMinutes,
        costPrice: costPrice,
      );

      if (!mounted) {
        return;
      }

      InventoryTimestamp.markChanged();
      setState(() {
        _isServiceAdded = true;
      });
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingService = false;
        });
      }
    }
  }

  double? _parseMoney(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

    if (cleanedValue.isEmpty) {
      return null;
    }

    return double.tryParse(cleanedValue);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ServiceAddedStatus extends StatelessWidget {
  const _ServiceAddedStatus();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFA8E6B0),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Service Added',
          style: TextStyle(
            color: Color(0xFFA8E6B0),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo.png',
            width: 48, height: 48, fit: BoxFit.contain),
        Text(
          title,
          style: const TextStyle(
              color: Color(0xFF272A2F),
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(
                color: const Color(0xFFFEEAB8),
                borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.spinnerColor,
    this.onIncrement,
    this.onDecrement,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Color? spinnerColor;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6C7078),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9CED6)),
              borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  style:
                      const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
                ),
              ),
              if (onIncrement != null || onDecrement != null) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                        onTap: onIncrement,
                        child: Icon(Icons.keyboard_arrow_up_rounded,
                            color: spinnerColor, size: 18)),
                    GestureDetector(
                        onTap: onDecrement,
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: spinnerColor, size: 18)),
                  ],
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServicePricingFields extends StatelessWidget {
  const _ServicePricingFields({
    required this.stackFields,
    required this.durationController,
    required this.costPriceController,
    required this.onIncrement,
    required this.onDecrement,
  });

  final bool stackFields;
  final TextEditingController durationController;
  final TextEditingController costPriceController;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final durationField = _InputField(
      label: 'Duration (min)',
      controller: durationController,
      keyboardType: TextInputType.number,
      spinnerColor: const Color(0xFFDFA890),
      onIncrement: onIncrement,
      onDecrement: onDecrement,
    );
    final costField = _InputField(
      label: 'Cost Price',
      controller: costPriceController,
      keyboardType: TextInputType.number,
    );

    if (stackFields) {
      return Column(
        children: [
          durationField,
          const SizedBox(height: 18),
          costField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: durationField),
        const SizedBox(width: 28),
        Expanded(child: costField),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.label,
    required this.value,
    this.hint,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String? hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6C7078),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9CED6)),
              borderRadius: BorderRadius.circular(6)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF272A2F)),
              style: const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
              hint: hint != null
                  ? Text(hint!,
                      style: const TextStyle(
                          color: Color(0xFF6C7078), fontSize: 13))
                  : null,
              items: const [
                DropdownMenuItem(value: 'Nail Care', child: Text('Nail Care')),
                DropdownMenuItem(value: 'Hair Care', child: Text('Hair Care')),
                DropdownMenuItem(value: 'Skin Care', child: Text('Skin Care')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 38,
        decoration: BoxDecoration(
            color: const Color(0xFFDFA890),
            borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ] else if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
            ],
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
