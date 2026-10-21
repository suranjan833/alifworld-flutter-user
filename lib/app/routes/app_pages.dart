// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../modules/top_brands/bindings/top_brands_binding.dart';
import '../modules/top_brands/views/top_brands_view.dart';
import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/order_success/bindings/order_success_binding.dart';
import '../modules/order_success/views/order_success_view.dart';
import '../modules/account/bindings/account_binding.dart';
import '../modules/account/views/account_view.dart';
import '../modules/bag/bindings/bag_binding.dart';
import '../modules/bag/views/bag_view.dart';
import '../modules/categories/bindings/category_products_binding.dart';
import '../modules/categories/views/category_products_view.dart';
import '../modules/manage_addresses/bindings/manage_addresses_binding.dart';
import '../modules/manage_addresses/views/manage_addresses_view.dart';
import '../modules/my_orders/bindings/my_orders_binding.dart';
import '../modules/my_orders/views/my_orders_view.dart';
import '../modules/my_orders/views/order_details_view.dart';
import '../modules/about_us/bindings/about_us_binding.dart';
import '../modules/about_us/views/about_us_view.dart';
import '../modules/privacy_policy/bindings/privacy_policy_binding.dart';
import '../modules/privacy_policy/views/privacy_policy_view.dart';
import '../modules/refund_policy/bindings/refund_policy_binding.dart';
import '../modules/refund_policy/views/refund_policy_view.dart';
import '../modules/shipping_policy/bindings/shipping_policy_binding.dart';
import '../modules/shipping_policy/views/shipping_policy_view.dart';
import '../modules/terms_and_conditions/bindings/terms_and_conditions_binding.dart';
import '../modules/terms_and_conditions/views/terms_and_conditions_view.dart';
import '../modules/my_profile/bindings/my_profile_binding.dart';
import '../modules/my_profile/views/my_profile_view.dart';
import '../modules/product_details/bindings/product_details_binding.dart';
import '../modules/product_details/views/product_details_view.dart';
import '../modules/seller_details/bindings/seller_details_binding.dart';
import '../modules/seller_details/views/seller_details_view.dart';
import '../modules/my_transactions/bindings/my_transactions_binding.dart';
import '../modules/my_transactions/views/my_transactions_view.dart';
import '../modules/my_wishlist/bindings/my_wishlist_binding.dart';
import '../modules/my_wishlist/views/my_wishlist_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/refer_and_earn/bindings/refer_and_earn_binding.dart';
import '../modules/refer_and_earn/views/refer_and_earn_view.dart';
import '../modules/shopping_list/bindings/shopping_list_binding.dart';
import '../modules/shopping_list/views/shopping_list_view.dart';
import '../modules/support/bindings/support_binding.dart';
import '../modules/support/views/support_view.dart';
import '../modules/wallet/bindings/wallet_binding.dart';
import '../modules/wallet/views/wallet_view.dart';
import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/discover/bindings/discover_binding.dart';
import '../modules/discover/views/discover_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/main_navigation/bindings/main_navigation_binding.dart';
import '../modules/main_navigation/views/main_navigation_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/signup/bindings/signup_binding.dart';
import '../modules/signup/views/signup_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.SIGNUP,
      page: () => const SignupView(),
      binding: SignupBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.MAIN_NAVIGATION,
      page: () => const MainNavigationView(),
      binding: MainNavigationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.CATEGORIES,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.DISCOVER,
      page: () => const DiscoverView(),
      binding: DiscoverBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.BAG,
      page: () => const BagView(),
      binding: BagBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.ACCOUNT,
      page: () => const AccountView(),
      binding: AccountBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.CATEGORY_PRODUCTS,
      page: () => const CategoryProductsView(),
      binding: CategoryProductsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.MY_PROFILE,
      page: () => const MyProfileView(),
      binding: MyProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.MY_ORDERS,
      page: () => const MyOrdersView(),
      binding: MyOrdersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.MANAGE_ADDRESSES,
      page: () => const ManageAddressesView(),
      binding: ManageAddressesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.MY_TRANSACTIONS,
      page: () => const MyTransactionsView(),
      binding: MyTransactionsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.MY_WISHLIST,
      page: () => const MyWishlistView(),
      binding: MyWishlistBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.WALLET,
      page: () => const WalletView(),
      binding: WalletBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.SHOPPING_LIST,
      page: () => const ShoppingListView(),
      binding: ShoppingListBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.REFER_AND_EARN,
      page: () => const ReferAndEarnView(),
      binding: ReferAndEarnBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.SUPPORT,
      page: () => const SupportView(),
      binding: SupportBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.PRODUCT_DETAILS,
      page: () => const ProductDetailsView(),
      binding: ProductDetailsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.SELLER_DETAILS,
      page: () => const SellerDetailsView(),
      binding: SellerDetailsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.ABOUT_US,
      page: () => const AboutUsView(),
      binding: AboutUsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.TERMS_AND_CONDITIONS,
      page: () => const TermsAndConditionsView(),
      binding: TermsAndConditionsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.PRIVACY_POLICY,
      page: () => const PrivacyPolicyView(),
      binding: PrivacyPolicyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.REFUND_POLICY,
      page: () => const RefundPolicyView(),
      binding: RefundPolicyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.SHIPPING_POLICY,
      page: () => const ShippingPolicyView(),
      binding: ShippingPolicyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.CHECKOUT,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.ORDER_SUCCESS,
      page: () => const OrderSuccessView(),
      binding: OrderSuccessBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.ORDER_DETAILS,
      page: () => const OrderDetailsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.TOP_BRANDS,
      page: () => const TopBrandsView(),
      binding: TopBrandsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
