import 'package:awe_pay/src/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import 'widgets/product_card.dart';
import 'widgets/product_item.dart';
import 'widgets/product_list_widgets.dart';

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
  List<ProductItem> _allProducts = [];
  bool _isLoading = true;

  List<String> get _categories {
    final source = widget.lowStockOnly
        ? _allProducts.where((p) => p.isLowStock)
        : _allProducts.cast<ProductItem>();
    final cats = source.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<ProductItem> get _filteredProducts {
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
            .map(ProductItem.fromMap)
            .toList();

        setState(() {
          _allProducts = items;
          if (_allProducts.isNotEmpty) {
            final source = widget.lowStockOnly
                ? items.where((p) => p.isLowStock)
                : items.cast<ProductItem>();
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
              ProductListHeader(
                title: widget.lowStockOnly ? 'Low Stock List' : 'Product List',
              ),
              const SizedBox(height: 28),
              ProductSearchBar(
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
              CategoryTabs(
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
                child: PageIndicator(
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
                              return ProductCard(
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
