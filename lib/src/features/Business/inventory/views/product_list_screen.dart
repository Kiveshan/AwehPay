import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.lowStockOnly = false});

  final bool lowStockOnly;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  String _selectedCategory = '';
  List<_ProductItem> _allProducts = [];
  bool _isLoading = true;

  List<String> get _categories {
    final source = widget.lowStockOnly
        ? _allProducts.where((p) => p.isLowStock)
        : _allProducts.cast<_ProductItem>();
    final cats = source.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<_ProductItem> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    return _allProducts.where((product) {
      final matchesCategory =
          _selectedCategory.isEmpty || product.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);
      final matchesLowStock = !widget.lowStockOnly || product.isLowStock;
      return matchesCategory && matchesSearch && matchesLowStock;
    }).toList();
  }

  double get _totalInventoryValue {
    return _filteredProducts.fold(
      0,
      (sum, p) => sum + p.sellingPrice * p.stockQuantity,
    );
  }

  double get _grandTotalInventoryValue {
    return _allProducts.fold(
      0,
      (sum, p) => sum + p.sellingPrice * p.stockQuantity,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _apiService.fetchProductList();
      final raw = response['products'];

      if (!mounted) return;

      if (raw is List) {
        final items = raw
            .whereType<Map<String, dynamic>>()
            .map(_ProductItem.fromMap)
            .toList();

        setState(() {
          _allProducts = items;
          if (_allProducts.isNotEmpty) {
            final source = widget.lowStockOnly
                ? items.where((p) => p.isLowStock)
                : items.cast<_ProductItem>();
            final cats = source.map((p) => p.category).toSet().toList()
              ..sort();
            if (cats.isNotEmpty) _selectedCategory = cats.first;
          }
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts;
    final categories = _categories;
    final total = _totalInventoryValue;
    final grandTotal = _grandTotalInventoryValue;
    final selectedIndex = categories.indexOf(_selectedCategory);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: widget.lowStockOnly ? 'Low Stock List' : 'Product List',
              ),
              const SizedBox(height: 28),
              _SearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),
              const Text(
                'Categories',
                style: TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _CategoryTabs(
                categories: categories,
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
                  count: categories.length,
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(
                                color: Color(0xFF6C7078),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(right: 8),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _ProductCard(
                                product: product,
                                onTap: () async {
                                  await context.push(
                                    AppRoutes.productDetails,
                                    extra: product.toDetailsExtra(),
                                  );
                                  if (mounted) _loadProducts();
                                },
                                onReplenishTap: () async {
                                  await context.push(
                                    AppRoutes.productDetails,
                                    extra: <String, Object>{
                                      'productId': product.productId,
                                      'name': product.name,
                                      'category': product.category,
                                      'barcode': product.barcode,
                                      'costPrice':
                                          'R ${product.costPrice.toStringAsFixed(2)}',
                                      'sellingPrice':
                                          'R${product.sellingPrice.toStringAsFixed(2)}',
                                      'quantity': '${product.stockQuantity}',
                                      'isLowStock': product.isLowStock,
                                      'rawCostPrice': product.costPrice,
                                      'rawSellingPrice': product.sellingPrice,
                                      'rawStockQuantity': product.stockQuantity,
                                      'rawLowStockThreshold':
                                          product.lowStockThreshold,
                                    },
                                  );
                                  if (mounted) _loadProducts();
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedCategory.isEmpty ? 'Category' : _selectedCategory} Inventory Value:\nR${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF272A2F),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    'Total Inventory Value:\nR${grandTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
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

class _Header extends StatelessWidget {
  const _Header({this.title = 'Product List'});

  final String title;

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
        Text(
          title,
          style: const TextStyle(
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF272A2F),
                ),
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
                    style:
                        const TextStyle(color: Color(0xFF272A2F), fontSize: 13),
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
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2F4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.filter_list_rounded,
            color: Color(0xFF6C7078),
            size: 20,
          ),
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
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryTab(
              label: categories[i],
              selected: selectedCategory == categories[i],
              onTap: () => onCategorySelected(categories[i]),
            ),
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
  final bool selected;
  final VoidCallback onTap;

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
    this.count = 4,
    this.selectedIndex = 0,
  });

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _IndicatorDot(selected: i == selectedIndex),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onReplenishTap,
  });

  final _ProductItem product;
  final VoidCallback onTap;
  final VoidCallback onReplenishTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
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
                    product.name,
                    style: const TextStyle(
                      color: Color(0xFF272A2F),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (product.barcode.isNotEmpty)
                    Text(
                      product.barcode,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R${product.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF272A2F),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${product.stockQuantity} Units in Stock',
                  style: TextStyle(
                    color: product.isLowStock
                        ? const Color(0xFFE68888)
                        : const Color(0xFF7ED88A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total stock value: R${(product.sellingPrice * product.stockQuantity).toStringAsFixed(2)}',
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                ),
                if (product.isLowStock) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReplenishTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6,),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C9B7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Replenish Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductItem {
  const _ProductItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.category,
  });

  final String productId;
  final String name;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String category;

  bool get isLowStock => stockQuantity < lowStockThreshold;

  static _ProductItem fromMap(Map<String, dynamic> map) {
    return _ProductItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      barcode: (map['barcode'] as String?) ?? '',
      costPrice: ((map['costPrice'] as num?) ?? 0).toDouble(),
      sellingPrice: ((map['sellingPrice'] as num?) ?? 0).toDouble(),
      stockQuantity: ((map['stockQuantity'] as num?) ?? 0).toInt(),
      lowStockThreshold: ((map['lowStockThreshold'] as num?) ?? 0).toInt(),
      category: (map['category'] as String?) ?? '',
    );
  }

  Map<String, Object> toDetailsExtra() {
    return {
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'costPrice': 'R ${costPrice.toStringAsFixed(2)}',
      'sellingPrice': 'R${sellingPrice.toStringAsFixed(2)}',
      'quantity': '$stockQuantity',
      'category': category,
      'isLowStock': isLowStock,
      'rawCostPrice': costPrice,
      'rawSellingPrice': sellingPrice,
      'rawStockQuantity': stockQuantity,
      'rawLowStockThreshold': lowStockThreshold,
    };
  }
}
