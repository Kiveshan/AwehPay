import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is Map<String, dynamic>) {
    final seconds = (value['_seconds'] as num?)?.toInt();
    final nanoseconds = (value['_nanoseconds'] as num?)?.toInt() ?? 0;
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
        isUtc: true,
      );
    }
  }
  return null;
}

class BusinessAddress {
  final String line1;
  final String line2;
  final String suburb;
  final String city;
  final String province;
  final String postalCode;
  final String country;

  BusinessAddress({
    required this.line1,
    required this.line2,
    required this.suburb,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
  });

  factory BusinessAddress.fromMap(Map<String, dynamic> map) {
    return BusinessAddress(
      line1: map['line1'] as String? ?? '',
      line2: map['line2'] as String? ?? '',
      suburb: map['suburb'] as String? ?? '',
      city: map['city'] as String? ?? '',
      province: map['province'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'line1': line1,
      'line2': line2,
      'suburb': suburb,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'country': country,
    };
  }

  String get formattedAddress {
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (suburb.isNotEmpty) suburb,
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

class BusinessVerification {
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  BusinessVerification({
    required this.isVerified,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  factory BusinessVerification.fromMap(Map<String, dynamic> map) {
    return BusinessVerification(
      isVerified: map['isVerified'] as bool? ?? false,
      verifiedAt: _parseTimestamp(map['verifiedAt']),
      verifiedBy: map['verifiedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isVerified': isVerified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
    };
  }
}

class BusinessSubscription {
  final String tierId;
  final String tierName;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? nextBillingDate;
  final double price;
  final String currency;
  final String billingPeriod;

  BusinessSubscription({
    required this.tierId,
    required this.tierName,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.nextBillingDate,
    required this.price,
    required this.currency,
    required this.billingPeriod,
  });

  factory BusinessSubscription.fromMap(Map<String, dynamic> map) {
    return BusinessSubscription(
      tierId: map['tierId'] as String? ?? '',
      tierName: map['tierName'] as String? ?? '',
      status: map['status'] as String? ?? '',
      startedAt: _parseTimestamp(map['startedAt']),
      expiresAt: _parseTimestamp(map['expiresAt']),
      nextBillingDate: _parseTimestamp(map['nextBillingDate']),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'ZAR',
      billingPeriod: map['billingPeriod'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tierId': tierId,
      'tierName': tierName,
      'status': status,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'nextBillingDate': nextBillingDate != null ? Timestamp.fromDate(nextBillingDate!) : null,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
    };
  }
}

class Business {
  final String businessId;
  final String ownerId;
  final String businessName;
  final String businessType;
  final String registrationNumber;
  final String sarsReferenceNumber;
  final String description;
  final String phoneNumber;
  final String email;
  final BusinessAddress address;
  final String status;
  final BusinessVerification verification;
  final BusinessSubscription subscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Business({
    required this.businessId,
    required this.ownerId,
    required this.businessName,
    required this.businessType,
    required this.registrationNumber,
    required this.sarsReferenceNumber,
    required this.description,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.status,
    required this.verification,
    required this.subscription,
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromMap(Map<String, dynamic> map, String docId) {
    return Business(
      businessId: map['businessId'] as String? ?? docId,
      ownerId: map['ownerId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      businessType: map['businessType'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      sarsReferenceNumber: map['sarsReferenceNumber'] as String? ?? '',
      description: map['description'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: BusinessAddress.fromMap(
        (map['address'] as Map<String, dynamic>?) ?? {},
      ),
      status: map['status'] as String? ?? '',
      verification: BusinessVerification.fromMap(
        (map['verification'] as Map<String, dynamic>?) ?? {},
      ),
      subscription: BusinessSubscription.fromMap(
        (map['subscription'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'ownerId': ownerId,
      'businessName': businessName,
      'businessType': businessType,
      'registrationNumber': registrationNumber,
      'sarsReferenceNumber': sarsReferenceNumber,
      'description': description,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address.toMap(),
      'status': status,
      'verification': verification.toMap(),
      'subscription': subscription.toMap(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
