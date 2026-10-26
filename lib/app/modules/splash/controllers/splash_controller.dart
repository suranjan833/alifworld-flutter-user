import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../routes/app_pages.dart';

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
    _startAnimationAndNavigate();
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
    final token = getBox.read(USER_TOKEN);
    final hasToken = token != null && token.toString().trim().isNotEmpty;
    final loggedInVal = getBox.read(IS_USER_LOGGED_IN);
    final isLoggedIn =
        (loggedInVal == true || loggedInVal == 'true' || hasToken);
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
