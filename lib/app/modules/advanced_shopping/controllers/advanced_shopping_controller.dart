import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/redeem_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import '../../../routes/app_pages.dart';
import '../models/advanced_shopping_model.dart';

class AdvancedShoppingController extends GetxController {
  final selectedTab = 0.obs; // 0 = Packages, 1 = My Packages
  final holdingFilter = 'all'.obs; // 'all', 'active', 'completed', 'cancelled'

  final isLoadingPackages = false.obs;
  final isLoadingHoldings = false.obs;
  final isBuying = false.obs;
  final isCancelling = false.obs;

  final packages = <AdvancedShoppingPackageModel>[].obs;
  final holdings = <AdvancedShoppingHoldingModel>[].obs;
  final lockedBalanceMinor = 0.obs;

  double get lockedBalance => lockedBalanceMinor.value / 100.0;

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchPackages(),
      if (hasAuth) fetchHoldings(),
    ]);
  }

  /// 1. GET /api/v1/advanced-shopping/packages
  Future<void> fetchPackages() async {
    isLoadingPackages.value = true;
    try {
      final res = await dioGet('advanced-shopping/packages');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map && raw.containsKey('items')) {
          final list = (raw['items'] as List<dynamic>?)
                  ?.map((e) => AdvancedShoppingPackageModel.fromJson(
                      Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          packages.assignAll(list);
        }
      }
    } catch (e) {
      debugPrint('Error fetching advanced shopping packages: $e');
    } finally {
      isLoadingPackages.value = false;
    }
  }

  /// 2. GET /api/v1/advanced-shopping/holdings
  Future<void> fetchHoldings() async {
    if (!hasAuth) {
      holdings.clear();
      lockedBalanceMinor.value = 0;
      return;
    }

    isLoadingHoldings.value = true;
    try {
      final res = await dioGet('advanced-shopping/holdings');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          final parsed =
              AdvancedShoppingHoldingsResponseModel.fromJson(raw);
          lockedBalanceMinor.value = parsed.balanceMinor;
          holdings.assignAll(parsed.items);
        }
      }
    } catch (e) {
      debugPrint('Error fetching advanced shopping holdings: $e');
    } finally {
      isLoadingHoldings.value = false;
    }
  }

  List<AdvancedShoppingHoldingModel> get filteredHoldings {
    switch (holdingFilter.value) {
      case 'active':
        return holdings.where((h) => h.isActive).toList();
      case 'completed':
        return holdings.where((h) => h.isCompleted).toList();
      case 'cancelled':
        return holdings.where((h) => h.isCancelled).toList();
      default:
        return holdings;
    }
  }

  /// 3. POST /api/v1/advanced-shopping/packages/{packageId}/buy
  Future<bool> buyPackage(
    BuildContext context,
    AdvancedShoppingPackageModel pkg,
  ) async {
    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    if (pkg.isLimitReached) {
      showSnack(
        'Limit Reached',
        'You have reached the maximum active limit of ${pkg.maxPerUser} for this package.',
        bg: AppColor.red,
      );
      return false;
    }

    if (pkg.isSoldOut) {
      showSnack(
        'Package Sold Out',
        'This package has reached its maximum total purchase limit.',
        bg: AppColor.red,
      );
      return false;
    }

    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Confirm Purchase',
      subtitle:
          'Enter your 6-digit wallet PIN to buy ${pkg.title} for ৳${pkg.price.toStringAsFixed(2)} from your Main Wallet',
    );

    if (pin == null || pin.isEmpty) return false;

    isBuying.value = true;
    final idempotencyKey = generateUuidV4();

    try {
      final res = await dioPost(
        endUrl: 'advanced-shopping/packages/${pkg.id}/buy',
        data: {'walletPin': pin},
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final error = raw['error'] is Map ? raw['error'] : null;

      isBuying.value = false;

      if (statusCode == 200 || statusCode == 201) {
        showSnack(
          'Package Purchased!',
          'Successfully activated ${pkg.title}!',
          bg: AppColor.green,
        );
        await refreshAll();
        selectedTab.value = 1; // switch to My Holdings
        return true;
      } else {
        final code = error?['code']?.toString() ?? '';
        String msg = error?['message']?.toString() ??
            raw['message']?.toString() ??
            'Failed to purchase package';

        if (code == 'INSUFFICIENT_BALANCE') {
          msg = 'Insufficient Main Wallet balance to purchase this package.';
        } else if (code == 'PACKAGE_SOLD_OUT') {
          msg = 'This package has sold out.';
        } else if (code == 'PACKAGE_LIMIT_REACHED') {
          msg = 'You have already reached the purchase limit for this package.';
        }

        showSnack('Purchase Failed', msg, bg: AppColor.red);
        return false;
      }
    } catch (e) {
      isBuying.value = false;
      showSnack('Error', 'Failed to purchase package: $e', bg: AppColor.red);
      return false;
    }
  }

  /// 4. POST /api/v1/advanced-shopping/holdings/{holdingId}/cancel
  Future<bool> cancelHolding(
    BuildContext context,
    AdvancedShoppingHoldingModel holding,
  ) async {
    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    if (!holding.isActive) {
      showSnack(
        'Cannot Cancel',
        'Only active packages before maturity can be cancelled.',
        bg: AppColor.red,
      );
      return false;
    }

    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Confirm Cancellation',
      subtitle:
          'Enter your 6-digit wallet PIN to confirm package cancellation',
    );

    if (pin == null || pin.isEmpty) return false;

    isCancelling.value = true;
    final idempotencyKey = generateUuidV4();

    try {
      final res = await dioPost(
        endUrl: 'advanced-shopping/holdings/${holding.id}/cancel',
        data: {'walletPin': pin},
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final error = raw['error'] is Map ? raw['error'] : null;

      isCancelling.value = false;

      if (statusCode == 200 || statusCode == 201) {
        showSnack(
          'Holding Cancelled',
          'Net principal has been refunded to your ${holding.releaseWalletTitle}.',
          bg: AppColor.green,
        );
        await refreshAll();
        return true;
      } else {
        final msg = error?['message']?.toString() ??
            raw['message']?.toString() ??
            'Cancellation failed';
        showSnack('Cancellation Failed', msg, bg: AppColor.red);
        return false;
      }
    } catch (e) {
      isCancelling.value = false;
      showSnack('Error', 'Failed to cancel package: $e', bg: AppColor.red);
      return false;
    }
  }
}
