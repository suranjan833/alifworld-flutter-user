import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/app_image.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/widgets/brand_logo_widget.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../data/widgets/typewriter_search_hint.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../controllers/home_controller.dart';
import '../models/home_category_model.dart';
import '../models/showcase_model.dart';
import 'widgets/auto_scrolling_mini_banners.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: controller.currentCategory.bgColor,
        body: controller.isLoading.value
            ? const SafeArea(child: SkeletonHome())
            : SafeArea(
                child: RefreshIndicator(
                  color: AppColor.primary,
                  backgroundColor: AppColor.white,
                  onRefresh: controller.refreshData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // 1. Location Header (commented out for now)
                      // SliverToBoxAdapter(
                      //   child: GestureDetector(
                      //     onTap: () => _showLocationBottomSheet(context),
                      //     behavior: HitTestBehavior.opaque,
                      //     child: Padding(
                      //       padding: EdgeInsets.only(
                      //         left: 16.w,
                      //         right: 16.w,
                      //         top: 10.h,
                      //         bottom: 8.h,
                      //       ),
                      //       child: Row(
                      //         children: [
                      //           Icon(
                      //             Iconsax.location5,
                      //             size: 20.r,
                      //             color: AppColor.textPrimary,
                      //           ),
                      //           SizedBox(width: 8.w),
                      //           Expanded(
                      //             child: Obx(
                      //               () => Text(
                      //                 controller.currentLocation.value,
                      //                 style: GoogleFonts.lato(
                      //                   fontSize: 15.sp,
                      //                   fontWeight: FontWeight.w700,
                      //                   color: AppColor.textPrimary,
                      //                 ),
                      //                 maxLines: 1,
                      //                 overflow: TextOverflow.ellipsis,
                      //               ),
                      //             ),
                      //           ),
                      //           SizedBox(width: 4.w),
                      //           Icon(
                      //             Icons.keyboard_arrow_down_rounded,
                      //             size: 22.r,
                      //             color: AppColor.textPrimary,
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // 1. Top Bar, Dynamic Category Header Banner & Category Navigation Bar
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Top App Bar Card (Logo, Wishlist, Notifications, Language, Search)
                            _buildTopHeaderCard(),

                            SizedBox(height: 12.h),

                            // Dynamic Category Mobile Header Background Banner from API
                            _buildCategoryMobileHeaderBanner(),

                            SizedBox(height: 12.h),

                            // Translucent Category Navigation Tabs Bar
                            _buildCategoryTabBar(),

                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),

                      // 2. Scrollable Body Content
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Rails from catalog/showcase matching website
                            _buildRailsSection(),

                            SizedBox(height: 24.h),

                            // 6. Category Showcase Mini Banners (Image-only, Auto-scrolling)
                            Obx(() {
                              final miniBanners =
                                  controller.showcase.value?.miniBanners ?? [];
                              return AutoScrollingMiniBanners(
                                miniBanners: miniBanners,
                              );
                            }),

                            SizedBox(height: 24.h),

                            // 7. Level It Up Promo Banner
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: InkWell(
                                onTap: () {
                                  Get.toNamed(
                                    Routes.CATEGORY_PRODUCTS,
                                    arguments: {
                                      'name': "Men's Fashion",
                                      'slug': 'fashion',
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF232936),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: Image.network(
                                          'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?q=80&w=400&auto=format&fit=crop',
                                          width: 100.w,
                                          height: 80.h,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 100.w,
                                                    height: 80.h,
                                                    color: AppColor.grey.shade700,
                                                    child: const Icon(
                                                      Iconsax.shopping_bag,
                                                      color: AppColor.white,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      SizedBox(width: 14.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const SizedBox(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFF9900,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.r,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'LEVEL IT UP',
                                                        style: GoogleFonts.lato(
                                                          fontSize: 10.sp,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: AppColor.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: 2.w),
                                                      Icon(
                                                        Icons
                                                            .north_east_rounded,
                                                        size: 12.r,
                                                        color: AppColor.white,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              'BUY 3\nGET EXTRA\n10% OFF',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFFFFB800),
                                                height: 1.1,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 3.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColor.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                'Offer auto-applies at checkout',
                                                style: GoogleFonts.lato(
                                                  fontSize: 9.sp,
                                                  color: AppColor.white
                                                      .withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // 8. Top Brands Section Header
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Top Brands',
                                    style: GoogleFonts.lato(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => Get.toNamed(Routes.TOP_BRANDS),
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 2.h,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View all',
                                            style: GoogleFonts.lato(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.primary,
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 11.r,
                                            color: AppColor.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // Top Brands Logo Cards Horizontal Scroll
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              physics: const BouncingScrollPhysics(),
                              child: Obx(
                                () => Row(
                                  children: controller.topBrands
                                      .map((brand) => _buildBrandCard(brand))
                                      .toList(),
                                ),
                              ),
                            ),

                            SizedBox(height: 30.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRailsSection() {
    return Obx(() {
      final isLoading = controller.isCategoryProductsLoading.value;
      if (isLoading) {
        return _buildProductLoadingSkeleton();
      }

      final rails = controller.showcase.value?.rails ?? [];
      if (rails.isEmpty) {
        return _buildEmptyCategoryNotice();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rails.map((rail) => _buildSingleRail(rail)).toList(),
      );
    });
  }

  Widget _buildSingleRail(ShowcaseRailModel rail) {
    if (rail.products.isEmpty) return const SizedBox.shrink();

    final railTitle = rail.categoryName.toLowerCase().startsWith('handpicked')
        ? rail.categoryName
        : 'Handpicked From ${rail.categoryName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  railTitle,
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  Get.toNamed(
                    Routes.CATEGORY_PRODUCTS,
                    arguments: {
                      'name': rail.categoryName,
                      'slug': rail.categorySlug,
                    },
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.r,
                        color: AppColor.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(
              rail.products.length,
              (index) =>
                  _buildProductCard(rail.products[index].toDetailsMap(), index),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildEmptyCategoryNotice() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFECEEF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7E6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Iconsax.box, size: 22.r, color: AppColor.primaryDark),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No products in ${controller.currentCategory.name} currently',
                  style: GoogleFonts.lato(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Check out all available categories and items',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () => Get.toNamed(
              Routes.CATEGORY_PRODUCTS,
              arguments: {
                'name': controller.currentCategory.name,
                'slug': controller.currentCategory.slug == 'all'
                    ? ''
                    : controller.currentCategory.slug,
              },
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Explore',
              style: GoogleFonts.lato(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductLoadingSkeleton() {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(2, (railIndex) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 170.w, height: 16.h, radius: 6),
                    SkeletonBox(width: 48.w, height: 12.h, radius: 4),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 160.w,
                      margin: EdgeInsets.only(right: 14.w),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: const SkeletonBox(
                              width: 22,
                              height: 22,
                              circle: true,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Center(
                            child: SkeletonBox(
                              width: double.infinity,
                              height: 90.h,
                              radius: 10,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          SkeletonBox(width: 120.w, height: 13.h, radius: 4),
                          SizedBox(height: 6.h),
                          SkeletonBox(width: 70.w, height: 11.h, radius: 4),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SkeletonBox(width: 60.w, height: 16.h, radius: 4),
                              SkeletonBox(width: 28.w, height: 28.h, radius: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final isFav = product['isFavorite'] as bool? ?? false;

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 14.w),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Favorite Button top right
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => controller.toggleFavorite(index),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? Iconsax.heart5 : Iconsax.heart,
                          size: 16.r,
                          color: isFav ? AppColor.red : AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Product Image
                  Center(
                    child: Image.network(
                      product['image'] as String,
                      height: 90.h,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SkeletonShimmer(
                          child: Container(
                            height: 90.h,
                            width: 90.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF3),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 90.h,
                        color: AppColor.grey.shade100,
                        child: Icon(
                          Iconsax.image,
                          size: 32.r,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Title
                  Text(
                    product['title'] as String,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Discount Badge
                  if ((product['discount'] as String?)?.isNotEmpty ?? false)
                    Text(
                      product['discount'] as String,
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),

                  SizedBox(height: 4.h),

                  // Price and Original Price (Responsive Wrap without overflow)
                  Padding(
                    padding: EdgeInsets.only(right: 28.w),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5.w,
                      runSpacing: 2.h,
                      children: [
                        Text(
                          product['price'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        if ((product['originalPrice'] as String?)?.isNotEmpty ??
                            false)
                          Text(
                            product['originalPrice'] as String,
                            style: GoogleFonts.lato(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColor.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Plus Add Button bottom right
            Positioned(
              right: 10.w,
              bottom: 10.h,
              child: GestureDetector(
                onTap: () async {
                  if (!Get.isRegistered<BagController>()) {
                    Get.put(BagController());
                  }
                  final bagCtrl = Get.find<BagController>();
                  await bagCtrl.addItemToBag(product);
                  await bagCtrl.fetchCart(showLoading: false, force: true);
                  bagCtrl.cartItems.refresh();
                  Get.snackbar(
                    'Added to Bag',
                    '${product['title'] ?? product['name'] ?? "Item"} added to shopping bag',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColor.primary,
                    colorText: AppColor.white,
                    duration: const Duration(seconds: 2),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColor.white,
                    size: 20.r,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Logo on left, Wishlist + Notifications + Language on right
          Row(
            children: [
              Image.asset(AppImage.logo, height: 28.h, fit: BoxFit.contain),
              const Spacer(),
              // Wishlist Heart
              GestureDetector(
                onTap: () => Get.toNamed(Routes.MY_WISHLIST),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    Iconsax.heart,
                    size: 22.r,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              // Notifications Bell
              GestureDetector(
                onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    Iconsax.notification,
                    size: 22.r,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              // Bag with live cart count badge
              GestureDetector(
                onTap: () {
                  if (!Get.isRegistered<BagController>()) {
                    Get.put(BagController());
                  }
                  Get.find<BagController>().fetchCart(force: true);
                  if (Get.isRegistered<MainNavigationController>()) {
                    Get.find<MainNavigationController>().changeTab(3);
                  } else {
                    Get.toNamed(Routes.BAG);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Obx(() {
                    if (!Get.isRegistered<BagController>()) {
                      Get.put(BagController());
                    }
                    final bagCtrl = Get.find<BagController>();
                    final count = bagCtrl.totalItemCount;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Iconsax.shopping_bag,
                          size: 22.r,
                          color: AppColor.textPrimary,
                        ),
                        if (count > 0)
                          Positioned(
                            top: -4.h,
                            right: -6.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: count > 9 ? 3.5.w : 4.5.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5A00),
                                shape: count > 9
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: count > 9
                                    ? BorderRadius.circular(10.r)
                                    : null,
                                border: Border.all(
                                  color: AppColor.white,
                                  width: 1.2.r,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 15.r,
                                minHeight: 15.r,
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              // Language Selector
              Container(
                margin: EdgeInsets.only(left: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EN',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16.r,
                      color: AppColor.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Row 2: Search input with orange search button on right
          Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                SizedBox(width: 14.w),
                Expanded(
                  child: Obx(
                    () => TypewriterSearchHintText(
                      hints: [
                        controller.currentCategory.searchHint,
                        ...controller.searchHints,
                      ],
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        color: AppColor.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                // Orange search button
                Container(
                  width: 48.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A00),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(22.r),
                      bottomRight: Radius.circular(22.r),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColor.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMobileHeaderBanner() {
    return Obx(() {
      String headerUrl = controller.currentCategory.headerBgMobileUrl;
      if (headerUrl.isEmpty &&
          (controller.showcase.value?.fullHeaderBgMobileUrl.isNotEmpty ??
              false)) {
        headerUrl = controller.showcase.value!.fullHeaderBgMobileUrl;
      }
      if (headerUrl.isNotEmpty) {
        headerUrl = resolveImageUrl(headerUrl);
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: GestureDetector(
          onTap: () {
            Get.toNamed(
              Routes.CATEGORY_PRODUCTS,
              arguments: {
                'name': controller.currentCategory.name,
                'slug': controller.currentCategory.slug == 'all'
                    ? ''
                    : controller.currentCategory.slug,
              },
            );
          },
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Container(
                key: ValueKey<String>(headerUrl),
                width: double.infinity,
                height: 220.h,
                decoration: BoxDecoration(
                  color: controller.currentCategory.bgColor,
                ),
                child: Image.network(
                  headerUrl,
                  width: double.infinity,
                  height: 220.h,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SkeletonShimmer(
                      child: Container(
                        width: double.infinity,
                        height: 220.h,
                        color: const Color(0xFFECEFF3),
                      ),
                    );
                  },
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
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        physics: const BouncingScrollPhysics(),
        child: Obx(
          () => Row(
            children: List.generate(
              controller.categories.length,
              (index) => _buildCategoryTab(index),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryFallbackIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'all':
        return Icons.shopping_bag_outlined;
      case 'electronics':
        return Icons.phone_android_rounded;
      case 'fashion':
      case 'clothing':
        return Icons.checkroom_rounded;
      case 'home-living':
      case 'furniture':
        return Icons.chair_outlined;
      case 'beauty':
      case 'cosmetics':
        return Icons.brush_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'grocery':
        return Icons.shopping_basket_outlined;
      case 'baby-kids':
        return Icons.child_care_rounded;
      case 'sports':
        return Icons.fitness_center_rounded;
      case 'automotive':
        return Icons.directions_car_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'toys':
        return Icons.sports_esports_rounded;
      case 'jewelry':
        return Icons.diamond_outlined;
      case 'pets':
        return Icons.pets_rounded;
      case 'tools':
        return Icons.build_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildCategoryIcon({
    required HomeCategoryModel category,
    required bool isSelected,
    required Color activeColor,
    required Color idleColor,
  }) {
    String iconUrl = category.fullImageUrl;
    if (iconUrl.isEmpty && (category.slug == 'all' || category.id == 'all')) {
      iconUrl = controller.showcase.value?.fullAllCategoryIconUrl ?? '';
    }

    if (iconUrl.isNotEmpty) {
      final isSvg =
          iconUrl.toLowerCase().endsWith('.svg') ||
          iconUrl.toLowerCase().contains('.svg?');

      if (isSvg) {
        return SvgPicture.network(
          iconUrl,
          width: 22.r,
          height: 22.r,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            isSelected ? activeColor : idleColor,
            BlendMode.srcIn,
          ),
          placeholderBuilder: (context) => SizedBox(
            width: 14.r,
            height: 14.r,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: isSelected ? activeColor : idleColor,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Icon(
            _getCategoryFallbackIcon(category.icon),
            size: 22.r,
            color: isSelected ? activeColor : idleColor,
          ),
        );
      } else {
        return Image.network(
          iconUrl,
          width: 24.r,
          height: 24.r,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            _getCategoryFallbackIcon(category.icon),
            size: 22.r,
            color: isSelected ? activeColor : idleColor,
          ),
        );
      }
    }

    return Icon(
      _getCategoryFallbackIcon(category.icon),
      size: 22.r,
      color: isSelected ? activeColor : idleColor,
    );
  }

  Widget _buildCategoryTab(int index) {
    final category = controller.categories[index];
    final isSelected = controller.selectedCategoryIndex.value == index;

    // Dynamic tap color from API (defaults to black if null / nothing coming)
    final tapColor = controller.showcase.value?.navTapColor ?? AppColor.black;
    final idleColor =
        controller.showcase.value?.navIdleColor ?? const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () => controller.selectCategory(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: isSelected
                    ? tapColor.withValues(alpha: 0.08)
                    : AppColor.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _buildCategoryIcon(
                  category: category,
                  isSelected: isSelected,
                  activeColor: tapColor,
                  idleColor: idleColor,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: 66.w,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? tapColor : const Color(0xFF4B5563),
                  height: 1.15,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              height: 2.5.h,
              width: 22.w,
              decoration: BoxDecoration(
                color: isSelected ? tapColor : AppColor.transparent,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCard(Map<String, String> brand) {
    return Container(
      width: 135.w,
      height: 95.h,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
      ),
      child: Material(
        color: AppColor.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            final name = brand['name'] ?? '';
            final logo = brand['logo'] ?? '';
            Get.toNamed(
              Routes.CATEGORY_PRODUCTS,
              arguments: {
                'name': name,
                'brand': name,
                'slug': name.toLowerCase(),
                'brandSlug': name.toLowerCase(),
                'image': logo,
              },
            );
          },
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: BrandLogoWidget(
                logoUrl: brand['logo'] ?? '',
                brandName: brand['name'] ?? '',
                width: 105.w,
                height: 65.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showLocationBottomSheet(BuildContext context) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 12.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColor.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Location',
                    style: GoogleFonts.montserrat(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22.r,
                      color: AppColor.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: 4.h),
              Text(
                'Select your delivery spot to view available products.',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: AppColor.textSecondary,
                ),
              ),

              SizedBox(height: 20.h),

              // Option 1: Fetch GPS Location Button
              GestureDetector(
                onTap: () async {
                  await controller.fetchGPSLocation();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F52BA).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF0F52BA).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F52BA),
                          shape: BoxShape.circle,
                        ),
                        child: Obx(
                          () => controller.isFetchingLocation.value
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.white,
                                  ),
                                )
                              : Icon(
                                  Iconsax.gps,
                                  color: AppColor.white,
                                  size: 18.r,
                                ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fetch Current Location',
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F52BA),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Using GPS for precise location',
                              style: GoogleFonts.lato(
                                fontSize: 11.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF0F52BA),
                        size: 20.r,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Divider with OR
              Row(
                children: [
                  Expanded(child: Divider(color: AppColor.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      'OR',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textHint,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColor.grey.shade300)),
                ],
              ),

              SizedBox(height: 16.h),

              // Option 2: Type Location Manually
              Text(
                'Type Location Manually',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),

              SizedBox(height: 8.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.location,
                      color: AppColor.textSecondary,
                      size: 18.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          color: AppColor.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter area, city or pin code...',
                          hintStyle: GoogleFonts.lato(
                            fontSize: 13.sp,
                            color: AppColor.textHint,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            controller.setLocation(value.trim());
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (textController.text.trim().isNotEmpty) {
                          controller.setLocation(textController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.textPrimary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              // Saved Locations Header
              Text(
                'Saved Addresses',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),

              SizedBox(height: 10.h),

              // Address 1
              _buildSavedAddressTile(
                icon: Iconsax.home,
                title: 'Home',
                address: 'Bakali coloni, Vijay Nagar, Bhuj, Gujarat',
                onTap: () {
                  controller.setLocation(
                    'Bakali coloni, Vijay Nagar, Bhuj, Gujar...',
                  );
                  Navigator.pop(context);
                },
              ),

              SizedBox(height: 8.h),

              // Address 2
              _buildSavedAddressTile(
                icon: Iconsax.briefcase,
                title: 'Work',
                address: 'Commercial Hub, Ring Road, Bhuj, Gujarat',
                onTap: () {
                  controller.setLocation(
                    'Commercial Hub, Ring Road, Bhuj, Gujar...',
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedAddressTile({
    required IconData icon,
    required String title,
    required String address,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: AppColor.textPrimary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    address,
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      color: AppColor.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.r,
              color: AppColor.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
