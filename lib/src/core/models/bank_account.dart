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

class BankAccount {
  final String bankAccountId;
  final String businessId;
  final String accountHolderName;
  final String bankName;
  final String accountNumberLast4;
  final String accountNumberEncrypted;
  final String branchName;
  final String branchCode;
  final String accountType;
  final String verificationStatus;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  BankAccount({
    required this.bankAccountId,
    required this.businessId,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumberLast4,
    required this.accountNumberEncrypted,
    required this.branchName,
    required this.branchCode,
    required this.accountType,
    required this.verificationStatus,
    required this.isPrimary,
    this.createdAt,
    this.updatedAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map, String docId) {
    return BankAccount(
      bankAccountId: map['bankAccountId'] as String? ?? docId,
      businessId: map['businessId'] as String? ?? '',
      accountHolderName: map['accountHolderName'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      accountNumberLast4: map['accountNumberLast4'] as String? ?? '',
      accountNumberEncrypted: map['accountNumberEncrypted'] as String? ?? '',
      branchName: map['branchName'] as String? ?? '',
      branchCode: map['branchCode'] as String? ?? '',
      accountType: map['accountType'] as String? ?? '',
      verificationStatus: map['verificationStatus'] as String? ?? '',
      isPrimary: map['isPrimary'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      verifiedAt: _parseTimestamp(map['verifiedAt']),
      verifiedBy: map['verifiedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankAccountId': bankAccountId,
      'businessId': businessId,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountNumberLast4': accountNumberLast4,
      'accountNumberEncrypted': accountNumberEncrypted,
      'branchName': branchName,
      'branchCode': branchCode,
      'accountType': accountType,
      'verificationStatus': verificationStatus,
      'isPrimary': isPrimary,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }
}
