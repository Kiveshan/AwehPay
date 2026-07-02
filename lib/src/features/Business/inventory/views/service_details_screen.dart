import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/api_service.dart';
import '../inventory_timestamp.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({
    super.key,
    this.service,
  });

  final Map<String, Object>? service;

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _apiService = ApiService();
  late final TextEditingController _serviceNameController;
  late final TextEditingController _durationController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _otherCategoryController;
  late String _selectedCategory;
  bool _isSavingService = false;
  bool _isDeletingService = false;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(
        text: widget.service?['name'] as String? ?? 'Gel nails with tips');
    _durationController = TextEditingController(
        text: widget.service?['duration'] as String? ?? '45');
    _costPriceController = TextEditingController(
        text: widget.service?['costPrice'] as String? ?? 'R 200.00');
    final category = widget.service?['category'] as String? ?? 'Nail Care';
    _selectedCategory = _isDefaultCategory(category) ? category : 'Other';
    _otherCategoryController = TextEditingController(
      text: _isDefaultCategory(category) ? '' : category,
    );
  }

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
            final isCompact = constraints.maxWidth < 340;
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
                      const _Header(title: 'Service List'),
                      SizedBox(height: topSpacing),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isCompact ? 12 : 14),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDFA890))),
                        child: Column(
                          children: [
                            _InputField(
                                label: 'Service Name',
                                controller: _serviceNameController),
                            const SizedBox(height: 18),
                            _CategoryDropdown(
                              label: 'Service Category',
                              value: _selectedCategory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
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
                            ),
                            const SizedBox(height: 24),
                            _ServiceActionButtons(
                              stackButtons: isCompact,
                              isSavingService: _isSavingService,
                              isDeletingService: _isDeletingService,
                              onUpdateService: _updateService,
                              onDeleteService: _deleteService,
                            ),
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

  Future<void> _updateService() async {
    final serviceId = widget.service?['serviceId'] as String?;
    final name = _serviceNameController.text.trim();
    final category = _selectedCategory == 'Other'
        ? _otherCategoryController.text.trim()
        : _selectedCategory;
    final durationMinutes = int.tryParse(_durationController.text.trim());
    final costPrice = _parseMoney(_costPriceController.text);

    if (serviceId == null || serviceId.isEmpty) {
      _showError('Service ID is missing.');
      return;
    }

    if (name.isEmpty ||
        category.isEmpty ||
        durationMinutes == null ||
        costPrice == null) {
      _showError('Please complete all service details before updating.');
      return;
    }

    setState(() {
      _isSavingService = true;
    });

    try {
      await _apiService.updateService(
        serviceId: serviceId,
        name: name,
        category: category,
        durationMinutes: durationMinutes,
        costPrice: costPrice,
      );

      if (!mounted) {
        return;
      }

      InventoryTimestamp.markChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully')),
      );
      context.pop();
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

  Future<void> _deleteService() async {
    final serviceId = widget.service?['serviceId'] as String?;

    if (serviceId == null || serviceId.isEmpty) {
      _showError('Service ID is missing.');
      return;
    }

    setState(() {
      _isDeletingService = true;
    });

    try {
      await _apiService.deleteService(serviceId: serviceId);

      if (!mounted) {
        return;
      }

      InventoryTimestamp.markChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully')),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingService = false;
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

  bool _isDefaultCategory(String category) {
    return category == 'Nail Care' ||
        category == 'Hair Care' ||
        category == 'Skin Care';
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
  const _InputField(
      {required this.label, required this.controller, this.keyboardType});

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
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
  });

  final bool stackFields;
  final TextEditingController durationController;
  final TextEditingController costPriceController;

  @override
  Widget build(BuildContext context) {
    final durationField = _InputField(
      label: 'Duration (min)',
      controller: durationController,
      keyboardType: TextInputType.number,
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

class _ServiceActionButtons extends StatelessWidget {
  const _ServiceActionButtons({
    required this.stackButtons,
    required this.isSavingService,
    required this.isDeletingService,
    required this.onUpdateService,
    required this.onDeleteService,
  });

  final bool stackButtons;
  final bool isSavingService;
  final bool isDeletingService;
  final VoidCallback onUpdateService;
  final VoidCallback onDeleteService;

  @override
  Widget build(BuildContext context) {
    final updateButton = _ActionButton(
      label: 'Update Service',
      icon: Icons.sync_rounded,
      color: const Color(0xFFDFA890),
      onTap: isSavingService ? null : onUpdateService,
    );
    final deleteButton = _ActionButton(
      label: 'Delete Service',
      icon: Icons.delete_rounded,
      color: const Color(0xFFE68888),
      onTap: isDeletingService ? null : onDeleteService,
    );

    if (stackButtons) {
      return Column(
        children: [
          updateButton,
          const SizedBox(height: 12),
          deleteButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: updateButton),
        const SizedBox(width: 12),
        Expanded(child: deleteButton),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 38,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
