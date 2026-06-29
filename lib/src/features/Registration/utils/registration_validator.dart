class RegistrationValidator {
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return 'Full name may only contain letters, spaces, hyphens and apostrophes';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    if (!digitsOnly.startsWith('0')) {
      return 'Phone number must start with 0';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }
    return null;
  }

  static String? registrationNumber(String? value) {
    // Optional field - only validate if provided
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    // South African CIPC formats: YYYY/######/## or KYYYY/#######
    final cipcRegex = RegExp(
      r'^(\d{4}/\d{6}/\d{2}|K\d{4}/\d{7})$',
      caseSensitive: false,
    );
    if (!cipcRegex.hasMatch(trimmed)) {
      return 'Enter a valid CIPC registration number (e.g. 2010/123456/07 or K2010/1234567)';
    }
    return null;
  }

  static String? sarsReferenceNumber(String? value) {
    // Optional field - only validate if provided
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    // SARS income tax reference is typically 10 digits
    // VAT number is typically 10 digits starting with 4
    final sarsRegex = RegExp(r'^\d{10}$');
    if (!sarsRegex.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit SARS reference number';
    }
    return null;
  }

  static String? streetAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street address is required';
    }
    if (value.trim().length < 3) {
      return 'Street address must be at least 3 characters';
    }
    return null;
  }

  static String? city(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return 'City may only contain letters, spaces, hyphens and apostrophes';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    // South African postal codes are 4 digits
    if (digitsOnly.length != 4) {
      return 'Enter a valid 4-digit South African postal code';
    }
    return null;
  }

  static String? province(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Province is required';
    }
    final validProvinces = [
      'eastern cape',
      'free state',
      'gauteng',
      'kwazulu-natal',
      'kwazulu natal',
      'limpopo',
      'mpumalanga',
      'northern cape',
      'north west',
      'northwest',
      'western cape',
    ];
    if (!validProvinces.contains(value.trim().toLowerCase())) {
      return 'Enter a valid South African province';
    }
    return null;
  }

  static String? country(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    final validNames = [
      'south africa',
      'sa',
      'rsa',
      's.a.',
      'republic of south africa',
    ];
    if (!validNames.contains(value.trim().toLowerCase())) {
      return 'Country must be South Africa';
    }
    return null;
  }

  static String? accountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 13) {
      return 'Enter a valid South African account number (7-13 digits)';
    }
    return null;
  }

  static String? accountType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account type is required';
    }
    final validTypes = [
      'savings',
      'current',
      'cheque',
      'transmission',
      'business',
      'corporate',
    ];
    if (!validTypes.contains(value.trim().toLowerCase())) {
      return 'Enter a valid account type (e.g. Savings, Current, Cheque, Business)';
    }
    return null;
  }

  static String? branchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Branch name is required';
    }
    if (value.trim().length < 2) {
      return 'Branch name must be at least 2 characters';
    }
    return null;
  }

  static String? branchCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Branch code is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    // South African branch codes are typically 6 digits
    if (digitsOnly.length != 6) {
      return 'Enter a valid 6-digit branch code';
    }
    return null;
  }

  static String? bankSelected(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a bank';
    }
    return null;
  }
}
