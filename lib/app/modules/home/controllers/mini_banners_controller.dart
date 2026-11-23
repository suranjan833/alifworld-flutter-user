import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/showcase_model.dart';

class MiniBannersController extends GetxController {
  late PageController pageController;
  Timer? _autoScrollTimer;
  final currentIndex = 0.obs;
  bool _isUserInteracting = false;
  int _bannerCount = 0;

  static final List<ShowcaseMiniBannerModel> fallbackBanners = [
    ShowcaseMiniBannerModel(
      id: 'fb-1',
      name: 'Audio & Headphones',
      slug: 'audio-headphones',
      imageUrl: '/minibanners/audio-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-2',
      name: 'Footwear',
      slug: 'footwear',
      imageUrl: '/minibanners/footwear-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-3',
      name: 'Furniture',
      slug: 'furniture',
      imageUrl: '/minibanners/furniture-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-4',
      name: 'Laptops & Computers',
      slug: 'laptops-computers',
      imageUrl: '/minibanners/laptop-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-5',
      name: "Men's Fashion",
      slug: 'mens-fashion',
      imageUrl: '/minibanners/mens-fashion-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-6',
      name: 'Mobile Phones',
      slug: 'mobile-phones',
      imageUrl: '/minibanners/mobile-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-7',
      name: 'Skincare',
      slug: 'skincare',
      imageUrl: '/minibanners/skincare-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-8',
      name: 'TVs & Home Theater',
      slug: 'tvs-home-theater',
      imageUrl: '/minibanners/tv-minibanner.png',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    final initialPage = 500 * 8;
    pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.84,
    );
  }

  void updateBannerCount(int count) {
    if (_bannerCount == count) return;
    _bannerCount = count;
    startAutoScroll();
  }

  void startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_bannerCount <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (_isUserInteracting) return;
      if (pageController.hasClients && pageController.page != null) {
        final nextPage = pageController.page!.round() + 1;
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void onUserTouchDown() {
    _isUserInteracting = true;
    _autoScrollTimer?.cancel();
  }

  void onUserTouchUp() {
    _isUserInteracting = false;
    startAutoScroll();
  }

  void onPageChanged(int pageIndex, int total) {
    if (total > 0) {
      currentIndex.value = pageIndex % total;
    }
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
