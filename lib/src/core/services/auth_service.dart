import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:awe_pay/src/features/Registration/models/registration_draft.dart';
import 'api_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    ApiService? apiService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _apiService = apiService ?? ApiService();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final ApiService _apiService;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _apiService.verifyCurrentUserToken();

    return credential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
    }

    final user = credential.user;

    if (user != null) {
      await _apiService.saveUserProfile(
        uid: user.uid,
        name: displayName?.trim() ?? '',
        email: user.email ?? email,
      );
    }

    return credential;
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> registerBusinessOwner(RegistrationDraft draft) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: draft.email.trim(),
      password: draft.password,
    );

    final user = credential.user!;
    final uid = user.uid;
    final businessRef = _firestore.collection('businesses').doc();
    final bankRef = businessRef.collection('bankAccounts').doc();
    final now = FieldValue.serverTimestamp();
    final selectedTier = draft.selectedTier;

    final subscriptionMap = selectedTier != null
        ? {
            'tierId': selectedTier.tierId,
            'tierName': selectedTier.name,
            'status': selectedTier.price == 0 ? 'active' : 'pending_payment',
            'startedAt': now,
            'expiresAt': null,
            'nextBillingDate': selectedTier.price == 0
                ? null
                : Timestamp.fromDate(
                    DateTime.now().add(const Duration(days: 30)),
                  ),
            'price': selectedTier.price,
            'currency': selectedTier.currency,
            'billingPeriod': selectedTier.billingPeriod,
          }
        : {
            'tierId': 'basic',
            'tierName': 'Basic',
            'status': 'active',
            'startedAt': now,
            'expiresAt': null,
            'nextBillingDate': null,
            'price': 0,
            'currency': 'ZAR',
            'billingPeriod': 'free',
          };

    await user.updateDisplayName(draft.fullName.trim());

    final batch = _firestore.batch();

    batch.set(_firestore.collection('users').doc(uid), {
      'uid': uid,
      'fullName': draft.fullName.trim(),
      'email': draft.email.trim(),
      'phoneNumber': draft.phoneNumber.trim(),
      'role': 'business_owner',
      'businessId': businessRef.id,
      'profileImageUrl': null,
      'isActive': true,
      'isEmailVerified': user.emailVerified,
      'isPhoneVerified': false,
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    });

    batch.set(businessRef, {
      'businessId': businessRef.id,
      'ownerId': uid,
      'businessName': draft.businessName.trim(),
      'businessType': 'business',
      'registrationNumber': draft.registrationNumber.trim(),
      'sarsReferenceNumber': draft.sarsReferenceNumber.trim(),
      'description': '',
      'phoneNumber': draft.phoneNumber.trim(),
      'email': draft.email.trim(),
      'address': {
        'line1': draft.streetAddress.trim(),
        'line2': '',
        'suburb': '',
        'city': draft.city.trim(),
        'province': draft.province.trim(),
        'postalCode': draft.postalCode.trim(),
        'country': draft.country.trim(),
      },
      'status': 'pending_verification',
      'verification': {
        'isVerified': false,
        'verifiedAt': null,
        'verifiedBy': null,
        'rejectionReason': null,
      },
      'paymentProfile': {
        'acceptsCash': true,
        'acceptsQr': true,
        'acceptsDigital': true,
        'defaultCurrency': 'ZAR',
      },
      'totals': {
        'balance': 0,
        'totalSales': 0,
        'totalCashSales': 0,
        'totalDigitalSales': 0,
        'totalExpenses': 0,
        'totalProducts': 0,
        'totalServices': 0,
      },
      'subscription': subscriptionMap,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(bankRef, {
      'bankAccountId': bankRef.id,
      'businessId': businessRef.id,
      'accountHolderName': draft.businessName.trim(),
      'bankName': draft.bankName.trim(),
      'accountNumberLast4': _lastFour(draft.accountNumber),
      'accountNumberEncrypted': '',
      'branchName': draft.branchName.trim(),
      'branchCode': draft.branchCode.trim(),
      'accountType': draft.accountType.trim(),
      'verificationStatus': 'pending',
      'isPrimary': true,
      'createdAt': now,
      'updatedAt': now,
      'verifiedAt': null,
      'verifiedBy': null,
    });

    await batch.commit();
  }

  String _lastFour(String value) {
    final digits = value.replaceAll(RegExp(r'\s+'), '');

    if (digits.length <= 4) {
      return digits;
    }

    return digits.substring(digits.length - 4);
  }
}
