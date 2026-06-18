import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import 'cash_payment_screen.dart';
import 'qr_code_screen.dart';
import 'widgets/purple_button.dart';

class PurchaseItem {
  final String name;
  final String price;
  final String barcode;
  final String itemId;
  final String type; // 'product' or 'service'

  PurchaseItem({
    required this.name,
    required this.price,
    this.barcode = '',
    this.itemId = '',
    this.type = 'product',
  });
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final List<PurchaseItem> _items = [];
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<PurchaseItem> _catalog = [];
  List<PurchaseItem> _filteredCatalog = [];
  bool _showDropdown = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final results = await _apiService.getProductsAndServices();
      final catalog = results.map((item) {
        final price = (item['price'] as num).toDouble();
        return PurchaseItem(
          name: item['name'] as String,
          price: 'R${price % 1 == 0 ? price.toInt() : price.toStringAsFixed(2)}',
          barcode: item['barcode'] as String? ?? '',
          itemId: item['id'] as String? ?? '',
          type: item['type'] as String? ?? 'product',
        );
      }).toList();
      setState(() {
        _catalog = catalog;
        _filteredCatalog = catalog;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCatalog = query.isEmpty
          ? _catalog
          : _catalog.where((item) => item.name.toLowerCase().contains(query)).toList();
    });
  }

  void _addItem(PurchaseItem item) {
    setState(() {
      _items.add(item);
      _searchController.clear();
      _showDropdown = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) {
      final priceValue = double.tryParse(item.price.replaceAll('R', '').replaceAll(',', '')) ?? 0.0;
      return sum + priceValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchases',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Service / Product',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onTap: () => setState(() => _showDropdown = true),
                    decoration: InputDecoration(
                      hintText: 'Search product or service...',
                      hintStyle: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 16),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF272A2F), size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _showDropdown = !_showDropdown),
                        child: Icon(
                          _showDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF272A2F),
                          size: 24,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_showDropdown)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : _loadError != null
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Color(0xFFE55353), size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('Failed to load catalog',
                                          style: TextStyle(color: Color(0xFFE55353), fontSize: 13)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _isLoading = true);
                                        _loadCatalog();
                                      },
                                      child: const Text('Retry',
                                          style: TextStyle(
                                              color: Color(0xFF6C5CE7),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredCatalog.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No products found',
                                        style: TextStyle(color: Color(0xFF9B9B9B))),
                                  )
                                : Column(
                                    children: _filteredCatalog.map((item) {
                                      return InkWell(
                                        onTap: () => _addItem(item),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.add_circle_outline,
                                                  color: Color(0xFF6C5CE7), size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.name,
                                                        style: const TextStyle(
                                                            color: Color(0xFF272A2F),
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w500)),
                                                    if (item.barcode.isNotEmpty)
                                                      Text(item.barcode,
                                                          style: const TextStyle(
                                                              color: Color(0xFF9B9B9B),
                                                              fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                              Text(item.price,
                                                  style: const TextStyle(
                                                      color: Color(0xFF6C5CE7),
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No items added',
                    style: TextStyle(color: Color(0xFF6C7078), fontSize: 16),
                  ),
                ),
              )
            else
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Padding(
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
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _removeItem(index),
                        child: const Icon(
                          Icons.delete,
                          color: Color(0xFFE55353),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            const Text(
              'Amount to be paid:',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R${_totalAmount.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PurpleButton(
              label: 'Generate QR Code',
              icon: Icons.qr_code_2,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QRCodeScreen(
                    items: _items,
                    totalAmount: _totalAmount,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PurpleButton(
              label: 'Cash Payment',
              icon: Icons.payments_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CashPaymentScreen(
                    items: _items,
                    totalAmount: _totalAmount,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

