import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/business.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/admin_business_service.dart';
import 'widgets/admin_primary_button.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_text_field.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key, this.business});

  final Business? business;

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _service = AdminBusinessService();
  bool _isLoading = true;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _sarsController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _registrationController.dispose();
    _sarsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final business = widget.business;
    if (business == null) {
      setState(() => _isLoading = false);
      return;
    }

    _businessNameController.text = business.businessName;
    _registrationController.text = business.registrationNumber;
    _sarsController.text = business.sarsReferenceNumber;
    _addressController.text = business.address.formattedAddress;
    _emailController.text = business.email;
    _phoneController.text = business.phoneNumber;

    final owner = await _service.getUserById(business.ownerId);
    if (mounted) {
      setState(() {
        _fullNameController.text = owner?.fullName ?? '';
        _phoneController.text = owner?.phoneNumber ?? business.phoneNumber;
        _emailController.text = owner?.email ?? business.email;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;

    if (business == null) {
      return const AdminScaffold(
        title: 'Business Details',
        child: Center(child: Text('No business selected')),
      );
    }

    return AdminScaffold(
      title: 'Business Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8A28D)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Personal Details'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        label: 'Full Name',
                        isDense: true,
                        readOnly: true,
                        alignLabelAbove: true,
                        controller: _fullNameController,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AdminTextField(
                        label: 'Contact Number',
                        isDense: true,
                        readOnly: true,
                        alignLabelAbove: true,
                        controller: _phoneController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AdminTextField(
                  label: 'Email Address',
                  isDense: true,
                  readOnly: true,
                  alignLabelAbove: true,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Business Information'),
                const SizedBox(height: 16),
                AdminTextField(
                  label: 'Business Name',
                  isDense: true,
                  readOnly: true,
                  alignLabelAbove: true,
                  controller: _businessNameController,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        label: 'Registration Number',
                        isDense: true,
                        readOnly: true,
                        alignLabelAbove: true,
                        controller: _registrationController,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AdminTextField(
                        label: 'SARS Reference Number',
                        isDense: true,
                        readOnly: true,
                        alignLabelAbove: true,
                        controller: _sarsController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AdminTextField(
                  label: 'Physical Address',
                  isDense: true,
                  readOnly: true,
                  alignLabelAbove: true,
                  maxLines: 4,
                  controller: _addressController,
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AdminPrimaryButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push(
                      AppRoutes.businessBanking,
                      extra: business.businessId,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6C7078),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
