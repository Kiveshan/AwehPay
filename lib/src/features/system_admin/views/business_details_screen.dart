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
  bool _isDisabling = false;
  Business? _currentBusiness;

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

    _currentBusiness = business;
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

  void _toggleDisabled(bool value) {
    final business = _currentBusiness;
    if (business == null) return;

    setState(() => _isDisabling = true);

    _service.disableBusiness(business.businessId, !value).then((_) {
      if (mounted) {
        setState(() {
          _currentBusiness = Business(
            businessId: business.businessId,
            ownerId: business.ownerId,
            businessName: business.businessName,
            businessType: business.businessType,
            registrationNumber: business.registrationNumber,
            sarsReferenceNumber: business.sarsReferenceNumber,
            description: business.description,
            phoneNumber: business.phoneNumber,
            email: business.email,
            address: business.address,
            status: value ? 'active' : 'disabled',
            verification: business.verification,
            subscription: business.subscription,
            createdAt: business.createdAt,
            updatedAt: business.updatedAt,
          );
          _isDisabling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Business enabled successfully'
                  : 'Business disabled successfully',
            ),
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isDisabling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle business status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final currentBusiness = _currentBusiness ?? business;

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
                Row(
                  children: [
                    const _SectionTitle('Business Status'),
                    const Spacer(),
                    Switch(
                      value: currentBusiness?.status != 'disabled',
                      onChanged: _isDisabling ? null : _toggleDisabled,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentBusiness?.status == 'disabled' ? 'Business is disabled' : 'Business is active',
                  style: TextStyle(
                    color: currentBusiness?.status == 'disabled' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Subscription Status'),
                const SizedBox(height: 8),
                _buildSubscriptionStatus(currentBusiness),
                const SizedBox(height: 16),
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

Widget _buildSubscriptionStatus(Business? business) {
  if (business == null) return const SizedBox.shrink();

  final subscriptionStatus = business.subscription.status;
  final trialEndDate = business.subscription.trialEndDate;
  final subscriptionEndDate = business.subscription.expiresAt;

  Color statusColor;
  String statusText;

  switch (subscriptionStatus) {
    case 'active':
      statusColor = Colors.green;
      statusText = 'Active';
      break;
    case 'pending_payment':
      statusColor = Colors.orange;
      statusText = 'Pending Payment';
      break;
    case 'expired':
      statusColor = Colors.red;
      statusText = 'Expired';
      break;
    case 'cancelled':
      statusColor = Colors.red;
      statusText = 'Cancelled';
      break;
    case 'cancel_at_period_end':
      statusColor = Colors.orange;
      statusText = 'Cancelling (active until period end)';
      break;
    case 'payment_failed':
      statusColor = Colors.red;
      statusText = 'Payment Failed';
      break;
    default:
      statusColor = Colors.grey;
      statusText = 'Unknown';
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (trialEndDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Text(
                'Trial',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      if (trialEndDate != null) ...[
        const SizedBox(height: 4),
        Text(
          'Trial ends: ${_formatDate(trialEndDate)}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6C7078),
          ),
        ),
      ],
      if (subscriptionEndDate != null) ...[
        const SizedBox(height: 4),
        Text(
          'Subscription ends: ${_formatDate(subscriptionEndDate)}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6C7078),
          ),
        ),
      ],
    ],
  );
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
