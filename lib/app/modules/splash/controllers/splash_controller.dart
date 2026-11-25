import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/services/app_update_service.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../home/controllers/home_controller.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> logoScaleAnimation;
  late Animation<double> logoFadeAnimation;
  late Animation<Offset> logoSlideAnimation;
  late Animation<double> glowPulseAnimation;
  late Animation<Offset> taglineSlideAnimation;
  late Animation<double> taglineFadeAnimation;
  late Animation<double> bottomFadeAnimation;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _prewarmAppData();
    _startAnimationAndNavigate();
  }

  /// Pre-warms Home and Bag data during splash animation for instant 0ms load
  void _prewarmAppData() {
    try {
      if (!Get.isRegistered<BagController>()) {
        Get.put<BagController>(BagController(), permanent: true);
      }

      if (!Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.put<HomeController>(HomeController(), permanent: true);
        homeCtrl.loadHomeData();
      } else {
        Get.find<HomeController>().loadHomeData();
      }
    } catch (_) {}
  }

  void _initAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    glowPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    taglineSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeIn),
      ),
    );

    bottomFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _startAnimationAndNavigate() async {
    await animationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Mandatory App Update Check (Google Play)
    if (Get.isRegistered<AppUpdateService>()) {
      final isUpdateRequired = await AppUpdateService.to.checkForUpdate();
      if (isUpdateRequired) {
        // Halt navigation — mandatory update popup is displayed
        return;
      }
    }

    final token = getBox.read(USER_TOKEN);
    final hasToken = token != null && token.toString().trim().isNotEmpty;
    final loggedInVal = getBox.read(IS_USER_LOGGED_IN);
    final isLoggedIn =
        (loggedInVal == true || loggedInVal == 'true' || hasToken);

    // Deep link product check (cold start)
    final pendingProduct = getBox.read('pending_deep_link_product')?.toString();
    final pendingVariant = getBox.read('pending_deep_link_variant')?.toString();
    if (pendingProduct != null && pendingProduct.trim().isNotEmpty) {
      getBox.remove('pending_deep_link_product');
      getBox.remove('pending_deep_link_variant');
      Get.offAllNamed(Routes.MAIN_NAVIGATION);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(
          Routes.PRODUCT_DETAILS,
          arguments: {
            'slug': pendingProduct.trim(),
            if (pendingVariant != null && pendingVariant.isNotEmpty)
              'variantId': pendingVariant.trim(),
          },
        );
      });
      return;
    }

    if (isLoggedIn) {
      Get.offAllNamed(Routes.MAIN_NAVIGATION);
    } else {
      final pendingCode = getBox.read(PENDING_REFERRAL_CODE)?.toString();
      if (pendingCode != null && pendingCode.trim().isNotEmpty) {
        Get.offAllNamed(
          Routes.SIGNUP,
          arguments: {'referralCode': pendingCode.trim()},
        );
      } else {
        Get.offAllNamed(Routes.MAIN_NAVIGATION);
      }
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
