import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import 'package:awe_pay/src/features/Registration/utils/registration_validator.dart';
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
  String? _selectedProvince;
  String? _errorMessage;
  String? _businessNameError;
  String? _registrationNumberError;
  String? _sarsReferenceNumberError;
  String? _streetAddressError;
  String? _cityError;
  String? _postalCodeError;
  String? _provinceError;
  String? _countryError;

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _sarsReferenceNumberController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final businessName = _businessNameController.text.trim();
    final registrationNumber = _registrationNumberController.text.trim();
    final sarsReferenceNumber = _sarsReferenceNumberController.text.trim();
    final streetAddress = _streetAddressController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final province = _selectedProvince ?? '';
    final country = 'South Africa';

    setState(() {
      _businessNameError = RegistrationValidator.businessName(businessName);
      _registrationNumberError = registrationNumber.isEmpty
          ? null
          : RegistrationValidator.registrationNumber(registrationNumber);
      _sarsReferenceNumberError = sarsReferenceNumber.isEmpty
          ? null
          : RegistrationValidator.sarsReferenceNumber(sarsReferenceNumber);
      _streetAddressError =
          RegistrationValidator.streetAddress(streetAddress);
      _cityError = RegistrationValidator.city(city);
      _postalCodeError = RegistrationValidator.postalCode(postalCode);
      _provinceError = province.isEmpty ? 'Please select a province' : null;
      _countryError = null;
      _errorMessage = null;
    });

    if (_businessNameError != null ||
        _streetAddressError != null ||
        _cityError != null ||
        _postalCodeError != null ||
        _provinceError != null ||
        _countryError != null) {
      return;
    }

    registrationDraft.businessName = businessName;
    registrationDraft.registrationNumber = registrationNumber;
    registrationDraft.sarsReferenceNumber = sarsReferenceNumber;
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
                errorText: _businessNameError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Registration Number',
                hintText: 'Enter your business registration number',
                controller: _registrationNumberController,
                suffixIcon: Icon(Icons.tag_outlined, size: 18),
                errorText: _registrationNumberError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'SARS Reference Number',
                hintText: 'Enter your SARS reference number',
                controller: _sarsReferenceNumberController,
                keyboardType: TextInputType.number,
                suffixIcon: Icon(Icons.grid_view_outlined, size: 18),
                errorText: _sarsReferenceNumberError,
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
                errorText: _streetAddressError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'City',
                hintText: 'Enter city',
                controller: _cityController,
                suffixIcon: Icon(Icons.location_city_outlined, size: 18),
                errorText: _cityError,
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Postal Code',
                hintText: 'Enter postal code',
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                suffixIcon:
                    const Icon(Icons.markunread_mailbox_outlined, size: 18),
                errorText: _postalCodeError,
              ),
              const SizedBox(height: 18),
              const Text(
                'Province',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedProvince,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select province',
                  suffixIcon: const Icon(Icons.map_outlined, size: 18),
                  border: const OutlineInputBorder(),
                  errorText: _provinceError,
                ),
                items: const [
                  DropdownMenuItem(value: 'Eastern Cape', child: Text('Eastern Cape')),
                  DropdownMenuItem(value: 'Free State', child: Text('Free State')),
                  DropdownMenuItem(value: 'Gauteng', child: Text('Gauteng')),
                  DropdownMenuItem(value: 'KwaZulu-Natal', child: Text('KwaZulu-Natal')),
                  DropdownMenuItem(value: 'Limpopo', child: Text('Limpopo')),
                  DropdownMenuItem(value: 'Mpumalanga', child: Text('Mpumalanga')),
                  DropdownMenuItem(value: 'Northern Cape', child: Text('Northern Cape')),
                  DropdownMenuItem(value: 'North West', child: Text('North West')),
                  DropdownMenuItem(value: 'Western Cape', child: Text('Western Cape')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                    _provinceError = null;
                  });
                },
              ),
              const SizedBox(height: 18),
              AdminTextField(
                label: 'Country',
                hintText: 'South Africa',
                controller: null,
                readOnly: true,
                suffixIcon: const Icon(Icons.public_outlined, size: 18),
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
