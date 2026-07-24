import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show ReplacementMode;

import 'api_service.dart';

enum PurchaseUiStatusType { pending, success, error, canceled }

class PurchaseUiStatus {
  final PurchaseUiStatusType type;
  final String? message;
  final String? productId;

  const PurchaseUiStatus._(this.type, {this.message, this.productId});

  factory PurchaseUiStatus.pending() =>
      const PurchaseUiStatus._(PurchaseUiStatusType.pending);
  factory PurchaseUiStatus.success(String productId) =>
      PurchaseUiStatus._(PurchaseUiStatusType.success, productId: productId);
  factory PurchaseUiStatus.error(String message) =>
      PurchaseUiStatus._(PurchaseUiStatusType.error, message: message);
  factory PurchaseUiStatus.canceled() =>
      const PurchaseUiStatus._(PurchaseUiStatusType.canceled);
}

/// Wraps Google Play Billing (via `in_app_purchase`) for AwehBiz subscription purchases.
///
/// Entitlement is never granted from client-local purchase state: every `purchased`/
/// `restored` event is sent to the backend's `/purchases/verify-google-play` endpoint,
/// which re-checks the purchase with the Play Developer API before writing
/// `businesses/{id}.subscription`. Only that server write actually unlocks a tier.
class PurchaseService {
  PurchaseService._internal();
  static final PurchaseService instance = PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiService _apiService = ApiService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _statusController = StreamController<PurchaseUiStatus>.broadcast();

  Stream<PurchaseUiStatus> get statusStream => _statusController.stream;

  /// Attaches the purchase-update listener. Must be called once at app bootstrap
  /// (not lazily on the paywall screen), so purchases left unfinished by a killed
  /// app are still redelivered and processed on the next launch.
  void init() {
    if (_subscription != null) return;
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _statusController.add(PurchaseUiStatus.error('Purchase stream error: $error'));
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) {
    return _iap.queryProductDetails(productIds);
  }

  Future<void> buySubscription(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Buys [newProduct] as a replacement for the business's existing active subscription
  /// to [currentProductId] (a tier upgrade or downgrade). Uses Play Billing's subscription
  /// replace mechanism (`ChangeSubscriptionParam`) so the customer is prorated/switched to
  /// the new plan rather than ending up with two parallel subscriptions or a rejected
  /// purchase — a plain `buySubscription` call must never be used when the business already
  /// has an active Play subscription to a different product.
  ///
  /// Falls back to a plain purchase if the old purchase record can't be found (e.g. the
  /// business's "current" tier was never actually Play-billed, such as being on a trial).
  Future<void> buySubscriptionChange({
    required ProductDetails newProduct,
    required String currentProductId,
  }) async {
    final oldPurchase = await _fetchCurrentPurchase(currentProductId);
    if (oldPurchase == null) {
      return buySubscription(newProduct);
    }

    await _iap.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: newProduct,
        changeSubscriptionParam: ChangeSubscriptionParam(
          oldPurchaseDetails: oldPurchase,
          // withTimeProration is Play's own default and (unlike chargeProratedPrice)
          // works for both upgrades and downgrades, so it's the safe generic choice here.
          replacementMode: ReplacementMode.withTimeProration,
        ),
      ),
    );
  }

  /// Fetches the currently active Play purchase details for [currentProductId] by
  /// triggering a restore and capturing the matching purchase from the stream.
  /// `ChangeSubscriptionParam` requires the actual purchase object being replaced, and
  /// this plugin only exposes past purchases via the purchaseStream, not a direct query.
  Future<GooglePlayPurchaseDetails?> _fetchCurrentPurchase(String currentProductId) async {
    final completer = Completer<GooglePlayPurchaseDetails?>();
    late final StreamSubscription<List<PurchaseDetails>> probe;
    probe = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID == currentProductId && purchase is GooglePlayPurchaseDetails) {
          if (!completer.isCompleted) completer.complete(purchase);
        }
      }
    });

    await restorePurchases();
    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    await probe.cancel();
    return result;
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _statusController.add(PurchaseUiStatus.pending());
          break;

        case PurchaseStatus.error:
          _statusController.add(
            PurchaseUiStatus.error(purchase.error?.message ?? 'Purchase failed'),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _statusController.add(PurchaseUiStatus.canceled());
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      await _apiService.verifyGooglePlayPurchase(
        purchaseToken: purchase.verificationData.serverVerificationData,
        productId: purchase.productID,
      );
      _statusController.add(PurchaseUiStatus.success(purchase.productID));
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } catch (e) {
      // Deliberately do NOT complete the purchase here: leaving it unfinished means
      // Play redelivers it via purchaseStream on next launch/restore, so a transient
      // backend/network failure gets retried instead of silently losing the purchase.
      _statusController.add(PurchaseUiStatus.error('Could not verify purchase: $e'));
    }
  }
}
