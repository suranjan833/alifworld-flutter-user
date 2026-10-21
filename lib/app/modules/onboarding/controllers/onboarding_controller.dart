import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../widgets/easy_returns_illustration.dart';
import '../widgets/track_orders_illustration.dart';

class OnboardingItem {
  final Widget illustration;
  final String title;
  final String description;
  final String buttonText;

  const OnboardingItem({
    required this.illustration,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}

class OnboardingController extends GetxController {
  late final PageController pageController;
  final currentPage = 0.obs;

  final List<OnboardingItem> items = const [
    OnboardingItem(
      illustration: TrackOrdersIllustration(),
      title: 'Track Your Orders',
      description: 'Stay updated with real-time tracking and get notifications about your order status.',
      buttonText: 'Next',
    ),
    OnboardingItem(
      illustration: EasyReturnsIllustration(),
      title: 'Easy Returns',
      description: 'Not satisfied? Return your items hassle-free with our 30-day return policy.',
      buttonText: 'Get Started',
    ),
  ];

  bool get isLastPage => currentPage.value == items.length - 1;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void onNextPressed() {
    if (isLastPage) {
      skipToHome();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipToHome() {
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
