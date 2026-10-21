import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../routes/app_pages.dart';
import '../../models/showcase_model.dart';

class AutoScrollingMiniBanners extends StatefulWidget {
  final List<ShowcaseMiniBannerModel> miniBanners;

  const AutoScrollingMiniBanners({
    super.key,
    required this.miniBanners,
  });

  @override
  State<AutoScrollingMiniBanners> createState() =>
      _AutoScrollingMiniBannersState();
}

class _AutoScrollingMiniBannersState extends State<AutoScrollingMiniBanners> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  bool _isUserInteracting = false;

  // Fallback banners when API miniBanners is empty
  static final List<ShowcaseMiniBannerModel> _fallbackBanners = [
    ShowcaseMiniBannerModel(
      id: 'fb-1',
      name: 'Audio & Headphones',
      slug: 'audio-headphones',
      imageUrl: 'https://alifworld.vercel.app/minibanners/audio-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-2',
      name: 'Footwear',
      slug: 'footwear',
      imageUrl: 'https://alifworld.vercel.app/minibanners/footwear-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-3',
      name: 'Furniture',
      slug: 'furniture',
      imageUrl: 'https://alifworld.vercel.app/minibanners/furniture-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-4',
      name: 'Laptops & Computers',
      slug: 'laptops-computers',
      imageUrl: 'https://alifworld.vercel.app/minibanners/laptop-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-5',
      name: "Men's Fashion",
      slug: 'mens-fashion',
      imageUrl:
          'https://alifworld.vercel.app/minibanners/mens-fashion-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-6',
      name: 'Mobile Phones',
      slug: 'mobile-phones',
      imageUrl: 'https://alifworld.vercel.app/minibanners/mobile-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-7',
      name: 'Skincare',
      slug: 'skincare',
      imageUrl: 'https://alifworld.vercel.app/minibanners/skincare-minibanner.png',
    ),
    ShowcaseMiniBannerModel(
      id: 'fb-8',
      name: 'TVs & Home Theater',
      slug: 'tvs-home-theater',
      imageUrl: 'https://alifworld.vercel.app/minibanners/tv-minibanner.png',
    ),
  ];

  List<ShowcaseMiniBannerModel> get _banners =>
      widget.miniBanners.isNotEmpty ? widget.miniBanners : _fallbackBanners;

  @override
  void initState() {
    super.initState();
    final count = _banners.length;
    // Set initial page in the middle of a large multiple for infinite circular scrolling
    final initialPage = count > 1 ? count * 500 : 0;
    _currentIndex = 0;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.84,
    );
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AutoScrollingMiniBanners oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.miniBanners.length != widget.miniBanners.length) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_banners.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (_isUserInteracting || !mounted) return;
      if (_pageController.hasClients) {
        final nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onUserTouchDown() {
    _isUserInteracting = true;
    _autoScrollTimer?.cancel();
  }

  void _onUserTouchUp() {
    _isUserInteracting = false;
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) => _onUserTouchDown(),
          onPointerUp: (_) => _onUserTouchUp(),
          onPointerCancel: (_) => _onUserTouchUp(),
          child: SizedBox(
            height: 185.h,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (pageIndex) {
                setState(() {
                  _currentIndex = pageIndex % banners.length;
                });
              },
              itemBuilder: (context, index) {
                final mb = banners[index % banners.length];
                return _buildBannerItem(mb);
              },
            ),
          ),
        ),
        if (banners.length > 1) ...[
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (dotIndex) {
              final isSelected = dotIndex == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                width: isSelected ? 16.w : 5.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBannerItem(ShowcaseMiniBannerModel mb) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.CATEGORY_PRODUCTS,
          arguments: {
            'name': mb.name,
            'slug': mb.slug,
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: AspectRatio(
            aspectRatio: 1.46, // matches 1515 x 1038 minibanner aspect ratio
            child: mb.fullImageUrl.isNotEmpty
                ? Image.network(
                    mb.fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: Center(
                        child: Icon(
                          Iconsax.image,
                          size: 40.r,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF1F5F9),
                    child: Center(
                      child: Icon(
                        Iconsax.image,
                        size: 40.r,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

