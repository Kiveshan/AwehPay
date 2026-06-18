import 'package:go_router/go_router.dart';

import '../../core/models/business.dart';
import '../../core/models/subscription_tier.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/Launch/views/launch_screen.dart';
import '../../features/Launch/views/sign_in_screen.dart';
import '../../features/Business/views/business_home_screen.dart';
import '../../features/Business/Business_Insights/business_insights_screen.dart';
import '../../features/Business/Sales%20Tracking/sales_breakdown_screen.dart';
import '../../features/Business/Sales%20Tracking/sales_tracking_screen.dart';
import '../../features/registration/views/account_created_screen.dart';
import '../../features/registration/views/business_information_screen.dart';
import '../../features/registration/views/payment_information_screen.dart';
import '../../features/registration/views/registration_sign_up_screen.dart';
import '../../features/registration/views/subscription_selection_screen.dart';
import '../../features/system_admin/views/business_banking_screen.dart';
import '../../features/system_admin/views/business_details_screen.dart';
import '../../features/system_admin/views/business_list_screen.dart';
import '../../features/system_admin/views/edit_subscription_tier_screen.dart';
import '../../features/system_admin/views/subscription_tiers_screen.dart';
import '../../features/system_admin/views/analytics_screen.dart';
import '../../features/system_admin/views/system_admin_home_screen.dart';
import '../../features/Business/Inventory/views/inventory_menu_screen.dart';
import '../../features/Business/Inventory/views/add_product_screen.dart';
import '../../features/Business/Inventory/views/barcode_scanner_screen.dart';
import '../../features/Business/Inventory/views/review_scanned_products_screen.dart';
import '../../features/Business/Inventory/views/add_service_screen.dart';
import '../../features/Business/Inventory/views/product_details_screen.dart';
import '../../features/Business/Inventory/views/product_list_screen.dart';
import '../../features/Business/Inventory/views/service_details_screen.dart';
import '../../features/Business/Inventory/views/service_list_screen.dart';
import '../../features/Business/purchases/purchases_screen.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.launch,
  routes: [
    GoRoute(
      path: AppRoutes.launch,
      builder: (context, state) => const LaunchScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminSignIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const RegistrationSignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessInformation,
      builder: (context, state) => const BusinessInformationScreen(),
    ),
    GoRoute(
      path: AppRoutes.subscriptionSelection,
      builder: (context, state) => const SubscriptionSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentInformation,
      builder: (context, state) => const PaymentInformationScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountCreated,
      builder: (context, state) => const AccountCreatedScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHome,
      builder: (context, state) => const SystemAdminHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessHome,
      builder: (context, state) => const BusinessHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.purchases,
      builder: (context, state) => const PurchasesScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessInsights,
      builder: (context, state) => const BusinessInsightsScreen(),
    ),
    GoRoute(
      path: AppRoutes.salesTracking,
      builder: (context, state) => const SalesTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.salesBreakdown,
      builder: (context, state) {
        final args = state.extra as SalesBreakdownArgs?;
        if (args == null) {
          return const SalesTrackingScreen();
        }
        return SalesBreakdownScreen(args: args);
      },
    ),
    GoRoute(
      path: AppRoutes.businessList,
      builder: (context, state) => const BusinessListScreen(),
    ),
    GoRoute(
      path: AppRoutes.subscriptionTiers,
      builder: (context, state) => const SubscriptionTiersScreen(),
    ),
    GoRoute(
      path: AppRoutes.editSubscriptionTier,
      builder: (context, state) {
        final tier = state.extra is SubscriptionTier ? state.extra as SubscriptionTier : null;
        return EditSubscriptionTierScreen(tier: tier);
      },
    ),
    GoRoute(
      path: AppRoutes.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessDetails,
      builder: (context, state) => BusinessDetailsScreen(
        business: state.extra is Business ? state.extra! as Business : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.businessBanking,
      builder: (context, state) => BusinessBankingScreen(
        businessId: state.extra is String ? state.extra! as String : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.inventoryMenu,
      builder: (context, state) => const InventoryMenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.addProduct,
      builder: (context, state) {
        final extra = state.extra is Map<String, dynamic>
            ? state.extra! as Map<String, dynamic>
            : <String, dynamic>{};
        return AddProductScreen(
          isReplenishStock: state.uri.queryParameters['mode'] == 'replenish',
          lockedProductId: extra['productId'] as String?,
          lockedProductName: extra['productName'] as String?,
          lockedCategory: extra['category'] as String?,
          prefillBarcode: extra['barcode'] as String?,
          prefillCostPrice: (extra['costPrice'] as num?)?.toDouble(),
          prefillSellingPrice: (extra['sellingPrice'] as num?)?.toDouble(),
          prefillStockQuantity: (extra['stockQuantity'] as num?)?.toInt(),
          prefillLowStockThreshold:
              (extra['lowStockThreshold'] as num?)?.toInt(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.barcodeScanner,
      builder: (context, state) => const BarcodeScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.reviewScannedProducts,
      builder: (context, state) {
        final args = state.extra is ReviewScannedProductsArgs
            ? state.extra! as ReviewScannedProductsArgs
            : const ReviewScannedProductsArgs(products: [], rawOcrText: '');
        return ReviewScannedProductsScreen(args: args);
      },
    ),
    GoRoute(
      path: AppRoutes.productList,
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: AppRoutes.lowStockList,
      builder: (context, state) =>
          const ProductListScreen(lowStockOnly: true),
    ),
    GoRoute(
      path: AppRoutes.productDetails,
      builder: (context, state) => ProductDetailsScreen(
        product: state.extra is Map<String, Object>
            ? state.extra! as Map<String, Object>
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.addService,
      builder: (context, state) => const AddServiceScreen(),
    ),
    GoRoute(
      path: AppRoutes.serviceList,
      builder: (context, state) => const ServiceListScreen(),
    ),
    GoRoute(
      path: AppRoutes.serviceDetails,
      builder: (context, state) => ServiceDetailsScreen(
        service: state.extra is Map<String, Object>
            ? state.extra! as Map<String, Object>
            : null,
      ),
    ),
  ],
);
