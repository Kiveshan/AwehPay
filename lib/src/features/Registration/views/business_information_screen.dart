import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import '../../system_admin/views/widgets/admin_primary_button.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import '../../system_admin/views/widgets/admin_text_field.dart';

class BusinessInformationScreen extends StatefulWidget {
  const BusinessInformationScreen({super.key});

  @override
  State<BusinessInformationScreen> createState() =>
      _BusinessInformationScreenState();
}

class _BusinessInformationScreenState extends State<BusinessInformationScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _sarsReferenceNumberController =
      TextEditingController();
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _sarsReferenceNumberController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final businessName = _businessNameController.text.trim();
    final streetAddress = _streetAddressController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final province = _provinceController.text.trim();
    final country = _countryController.text.trim();

    if (businessName.isEmpty ||
        streetAddress.isEmpty ||
        city.isEmpty ||
        postalCode.isEmpty ||
        province.isEmpty ||
        country.isEmpty) {
      setState(() {
        _errorMessage = 'Complete all required business details';
      });
      return;
    }

    registrationDraft.businessName = businessName;
    registrationDraft.registrationNumber =
        _registrationNumberController.text.trim();
    registrationDraft.sarsReferenceNumber =
        _sarsReferenceNumberController.text.trim();
    registrationDraft.streetAddress = streetAddress;
    registrationDraft.city = city;
    registrationDraft.postalCode = postalCode;
    registrationDraft.province = province;
    registrationDraft.country = country;
    context.push(AppRoutes.subscriptionSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Business Information',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminTextField(
                label: 'Business Name',
                hintText: 'Enter your businesses name',
                controller: _businessNameController,
                suffixIcon: Icon(Icons.business_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Registration Number',
                hintText: 'Enter your business registration number',
                controller: _registrationNumberController,
                suffixIcon: Icon(Icons.tag_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'SARS Reference Number',
                hintText: 'Enter your email address',
                controller: _sarsReferenceNumberController,
                keyboardType: TextInputType.emailAddress,
                suffixIcon: Icon(Icons.grid_view_outlined, size: 18),
              ),
              const SizedBox(height: 24),
              const Text(
                'Physical Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              AdminTextField(
                label: 'Street Address',
                hintText: 'Enter street address',
                controller: _streetAddressController,
                suffixIcon: Icon(Icons.home_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'City',
                hintText: 'Enter city',
                controller: _cityController,
                suffixIcon: Icon(Icons.location_city_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Postal Code',
                hintText: 'Enter postal code',
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                suffixIcon:
                    const Icon(Icons.markunread_mailbox_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Province',
                hintText: 'Enter province',
                controller: _provinceController,
                suffixIcon: Icon(Icons.map_outlined, size: 18),
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Country',
                hintText: 'Enter country',
                controller: _countryController,
                suffixIcon: Icon(Icons.public_outlined, size: 18),
              ),
              const SizedBox(height: 28),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              AdminPrimaryButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: _handleNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
