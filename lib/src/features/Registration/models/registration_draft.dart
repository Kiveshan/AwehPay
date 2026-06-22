import '../../../core/models/subscription_tier.dart';

class RegistrationDraft {
  String fullName = '';
  String phoneNumber = '';
  String email = '';
  String password = '';
  String businessName = '';
  String registrationNumber = '';
  String sarsReferenceNumber = '';
  String streetAddress = '';
  String city = '';
  String postalCode = '';
  String province = '';
  String country = '';
  String bankName = '';
  String bankCode = '';
  String accountNumber = '';
  String accountType = '';
  String branchName = '';
  String branchCode = '';
  SubscriptionTier? selectedTier;
}

final registrationDraft = RegistrationDraft();
