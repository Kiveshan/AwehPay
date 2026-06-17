import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/business.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/admin_business_service.dart';
import 'widgets/admin_scaffold.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  final _service = AdminBusinessService();
  final _searchController = TextEditingController();
  String _query = '';
  Future<List<Business>>? _businessesFuture;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBusinesses() {
    setState(() {
      _businessesFuture = _service.getBusinesses();
    });
  }

  List<Business> _filterBusinesses(List<Business> businesses) {
    if (_query.trim().isEmpty) return businesses;
    final lower = _query.toLowerCase();
    return businesses.where((b) {
      return b.businessName.toLowerCase().contains(lower) ||
          b.registrationNumber.toLowerCase().contains(lower);
    }).toList();
  }

  double _totalSubscriptionValue(List<Business> businesses) {
    return businesses.fold(
      0.0,
      (sum, b) => sum + b.subscription.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Business List',
      child: FutureBuilder<List<Business>>(
        future: _businessesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final isForbidden = snapshot.error.toString().contains('Forbidden');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isForbidden ? Icons.lock_outline : Icons.error_outline,
                      size: 48,
                      color: isForbidden ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isForbidden
                          ? 'Access Denied'
                          : 'Something went wrong',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isForbidden
                          ? 'You do not have admin privileges.'
                          : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isForbidden) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final allBusinesses = snapshot.data ?? [];
          final filtered = _filterBusinesses(allBusinesses);
          final total = _totalSubscriptionValue(allBusinesses);

          return RefreshIndicator(
            onRefresh: () async => _loadBusinesses(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        hintText: 'Search',
                        leading: const Icon(Icons.search_rounded, size: 18),
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor:
                            WidgetStatePropertyAll(Colors.grey.shade100),
                        constraints: const BoxConstraints(minHeight: 42),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (filtered.isEmpty)
                  const Center(child: Text('No businesses found'))
                else
                  ...filtered.map(
                    (business) => _BusinessListTile(
                      business: business,
                      onTap: () => context.push(
                        AppRoutes.businessDetails,
                        extra: business,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Total Subscription Value:',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'R${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BusinessListTile extends StatelessWidget {
  const _BusinessListTile({
    required this.business,
    required this.onTap,
  });

  final Business business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          business.businessName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(business.registrationNumber),
        trailing: Text(
          'Subscription: ${business.subscription.tierName}',
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}
