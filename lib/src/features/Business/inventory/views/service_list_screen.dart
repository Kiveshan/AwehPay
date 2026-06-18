import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/router/app_routes.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  List<_ServiceItem> _services = [];
  bool _isLoadingServices = true;
  String? _errorMessage;
  String _selectedCategory = 'Nail Care';

  List<_ServiceItem> get _filteredServices {
    final query = _searchController.text.toLowerCase().trim();
    return _services.where((service) {
      final matchesCategory = service.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.code.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get _categories {
    final categories = <String>{'Nail Care', 'Hair Care', 'Skin Care'};

    for (final service in _services) {
      if (service.category.trim().isNotEmpty) {
        categories.add(service.category);
      }
    }

    return categories.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _filteredServices;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(title: 'Service List'),
              const SizedBox(height: 28),
              _SearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),
              const Text(
                'Categories',
                style: TextStyle(color: Color(0xFF272A2F), fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _CategoryTabs(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 18),
              Center(
                child: _PageIndicator(
                  itemCount: _categories.length,
                  selectedIndex: _categories.indexOf(_selectedCategory).clamp(0, _categories.length - 1),
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: _isLoadingServices
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFF6C7078), fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : filteredServices.isEmpty
                    ? const Center(
                        child: Text(
                          'No services found',
                          style: TextStyle(color: Color(0xFF6C7078), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(right: 8),
                        itemCount: filteredServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return _ServiceCard(
                            service: service,
                            onTap: () async {
                              await context.push(AppRoutes.serviceDetails, extra: service.toDetailsExtra());
                              if (mounted) {
                                _loadServices();
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _errorMessage = null;
    });

    try {
      final services = await _apiService.listServices();

      if (!mounted) {
        return;
      }

      setState(() {
        _services = services.map(_ServiceItem.fromMap).toList();
        if (_services.isNotEmpty &&
            !_services.any((service) => service.category == _selectedCategory)) {
          _selectedCategory = _services.first.category;
        }
        _isLoadingServices = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoadingServices = false;
        });
      }
    }
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
        Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.contain),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF272A2F), fontSize: 24, fontWeight: FontWeight.w800),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFFFEEAB8), borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF272A2F)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.filter_list_rounded, color: Color(0xFF6C7078), size: 20),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            _CategoryTab(
              label: category,
              selected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
            const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5C9B7) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6C7078),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < itemCount; i++) ...[
          _IndicatorDot(selected: i == selectedIndex),
          if (i < itemCount - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: selected ? 18 : 14,
      height: 4,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5C9B7) : const Color(0xFFD8DCE2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final _ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(color: Color(0xFF272A2F), fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.code,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.price,
                  style: const TextStyle(color: Color(0xFF272A2F), fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  service.duration,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.serviceId,
    required this.name,
    required this.code,
    required this.price,
    required this.duration,
    required this.category,
    required this.durationMinutes,
    required this.costPrice,
  });

  final String serviceId;
  final String name;
  final String code;
  final String price;
  final String duration;
  final String category;
  final int durationMinutes;
  final double costPrice;

  factory _ServiceItem.fromMap(Map<String, dynamic> service) {
    final serviceId = service['serviceId'] as String? ?? '';
    final name = service['name'] as String? ?? '';
    final category = service['category'] as String? ?? '';
    final durationMinutes = service['durationMinutes'] as int? ?? 0;
    final costPrice = (service['costPrice'] as num?)?.toDouble() ?? 0;

    return _ServiceItem(
      serviceId: serviceId,
      name: name,
      code: serviceId,
      price: 'R${costPrice.toStringAsFixed(2)}',
      duration: '$durationMinutes minutes',
      category: category,
      durationMinutes: durationMinutes,
      costPrice: costPrice,
    );
  }

  Map<String, Object> toDetailsExtra() {
    return {
      'serviceId': serviceId,
      'name': name,
      'category': category,
      'duration': '$durationMinutes',
      'costPrice': price,
      'costPriceValue': costPrice,
    };
  }
}
