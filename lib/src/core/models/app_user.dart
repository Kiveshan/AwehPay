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

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? businessId;
  final String? profileImageUrl;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.businessId,
    this.profileImageUrl,
    required this.isActive,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      uid: map['uid'] as String? ?? docId,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      role: map['role'] as String? ?? '',
      businessId: map['businessId'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      isActive: map['isActive'] as bool? ?? false,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'businessId': businessId,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }
}
