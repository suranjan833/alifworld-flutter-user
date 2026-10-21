import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/brand_logo_widget.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../controllers/category_products_controller.dart';
import '../models/product_model.dart';

class CategoryProductsView extends GetView<CategoryProductsController> {
  const CategoryProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CategoryProductsController>()) {
      Get.put(CategoryProductsController());
    }

    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColor.primary,
          backgroundColor: Colors.white,
          onRefresh: controller.refreshProducts,
          child: Obx(
            () => controller.isLoading.value
                ? const CategoryProductsSkeleton()
                : _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final showSidebar = controller.showSubCategorySidebar;

      return Row(
        children: [
          // 1. Left Vertical Sub-category Sidebar (shown only when category has subcategories)
          if (showSidebar) _buildSubCategorySidebar(),

          // 2. Right Main Products Listing Content Area
          Expanded(
            child: Column(
              children: [
                // Filter & Sort Control Pills Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
                  child: Row(
                    children: [
                      _buildPillButton(
                        icon: Iconsax.setting_4,
                        label: 'Filter',
                        trailing: Icons.keyboard_arrow_down_rounded,
                        onTap: () {},
                      ),
                      SizedBox(width: 8.w),
                      _buildPillButton(
                        icon: Icons.swap_vert_rounded,
                        label: 'Sort',
                        trailing: Icons.keyboard_arrow_down_rounded,
                        onTap: () {},
                      ),
                      const Spacer(),
                      // Live result count next to the controls
                      Obx(
                        () => Text(
                          '${controller.visibleItemCount} items',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Cards Grid
                Expanded(
                  child: Obx(() {
                    if (controller.isProductsLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
                      );
                    }

                    final products = controller.filteredProducts;

                    if (products.isEmpty) {
                      return _buildEmptyState();
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        showSidebar ? 10.w : 16.w,
                        6.h,
                        showSidebar ? 10.w : 16.w,
                        20.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: showSidebar ? 0.52 : 0.68,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(context, product);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: AppColor.textPrimary,
          size: 24.r,
        ),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Obx(
        () => Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFECEEF2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: BrandLogoWidget(
                logoUrl: controller.categoryImage.value,
                brandName: controller.categoryName.value,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () {
                      final idx = controller.selectedSubCategoryIndex.value;
                      final title = idx == 0
                          ? controller.categoryName.value
                          : (controller.subCategories[idx]['name'] as String)
                              .replaceAll('\n', ' ');
                      return Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      );
                    },
                  ),
                  Obx(
                    () => Text(
                      '${controller.visibleItemCount} products',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildCircularAction(icon: Iconsax.search_normal_1, onTap: () {}),
        SizedBox(width: 6.w),
        Obx(() {
          if (!Get.isRegistered<BagController>()) {
            Get.put(BagController());
          }
          final bagCtrl = Get.find<BagController>();
          final count = bagCtrl.totalItemCount;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildCircularAction(
                icon: Iconsax.shopping_bag,
                onTap: () {
                  if (!Get.isRegistered<BagController>()) {
                    Get.put(BagController());
                  }
                  Get.find<BagController>().fetchCart(force: true);
                  Get.toNamed(Routes.BAG);
                },
              ),
              if (count > 0)
                Positioned(
                  top: -2.h,
                  right: -2.w,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: count > 9 ? 3.5.w : 4.5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A00),
                        shape:
                            count > 9 ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius:
                            count > 9 ? BorderRadius.circular(10.r) : null,
                        border: Border.all(color: Colors.white, width: 1.5.r),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.r,
                        minHeight: 16.r,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        SizedBox(width: 12.w),
      ],
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFECEEF2), width: 1.r),
        ),
        child: Icon(icon, size: 17.r, color: AppColor.textPrimary),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSubCategorySidebar() {
    return Container(
      width: 84.w,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: const Color(0xFFF1F5F9), width: 1.r),
        ),
      ),
      child: Obx(() {
        final selectedIndex = controller.selectedSubCategoryIndex.value;
        final subCats = controller.subCategories;

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          itemCount: subCats.length,
          itemBuilder: (context, index) {
            final subCategory = subCats[index];
            final isSelected = index == selectedIndex;

            return GestureDetector(
              onTap: () => controller.selectSubCategory(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF7E6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon bubble
                    Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFF6F7F9),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFBAF18,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: index == 0
                            ? Icon(
                                Icons.shopping_basket_outlined,
                                size: 20.r,
                                color: isSelected
                                    ? const Color(0xFFD98200)
                                    : AppColor.textSecondary,
                              )
                            : ClipOval(
                                child: Image.network(
                                  subCategory['icon'] as String,
                                  width: 24.r,
                                  height: 24.r,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Iconsax.grid_5,
                                        size: 18.r,
                                        color: isSelected
                                            ? const Color(0xFFD98200)
                                            : AppColor.textSecondary,
                                      ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subCategory['name'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFD98200)
                            : AppColor.textSecondary,
                        height: 1.15,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Pills & Empty State
  // ---------------------------------------------------------------------------

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE9ECF1), width: 1.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 15.r, color: AppColor.textPrimary),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(width: 3.w),
            Icon(trailing, size: 15.r, color: AppColor.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.box,
                size: 28.r,
                color: AppColor.textHint,
              ),
            ),
            SizedBox(height: 12.h),
            Obx(
              () {
                if (controller.isBrandView) {
                  return Text(
                    'No products found for "${controller.categoryName.value}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  );
                }
                final idx = controller.selectedSubCategoryIndex.value;
                final subName = idx < controller.subCategories.length
                    ? (controller.subCategories[idx]['name'] as String).replaceAll('\n', ' ')
                    : '';
                return Text(
                  idx == 0
                      ? 'No products in this category yet'
                      : 'No products in "$subName" yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                );
              },
            ),
            SizedBox(height: 4.h),
            Obx(
              () => Text(
                controller.isBrandView
                    ? 'There are currently no products listed under this brand in the live catalog.'
                    : 'Try selecting another category or check back soon',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Product Card
  // ---------------------------------------------------------------------------

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final productId = product.id ?? '';
    final imageUrl = product.image ?? '';
    final title = product.title ?? 'Product';
    final brand = product.brand ?? 'Brand';
    final price = product.price;
    final originalPrice = product.originalPrice;
    final discount = product.discount ?? '';

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product.toJson()),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Badge, Wishlist Heart, and Add Floating Button
            Expanded(
              child: Stack(
                children: [
                  // Soft tinted image backdrop
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFFAFBFC),
                    padding: EdgeInsets.all(10.r),
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Iconsax.image,
                          size: 32.r,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Top Left Badge (e.g. "2 Pack")
                  if (product.badge != null)
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          product.badge!,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ),

                  // Top Right Wishlist Heart
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Obx(() {
                      final isWishlisted = controller.wishlistedProductIds
                          .contains(productId);
                      return GestureDetector(
                        onTap: () => controller.toggleWishlist(productId),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Container(
                            key: ValueKey<bool>(isWishlisted),
                            width: 26.r,
                            height: 26.r,
                            decoration: BoxDecoration(
                              color: isWishlisted
                                  ? const Color(0xFFFFF7E6)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 5.r,
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted ? Iconsax.heart5 : Iconsax.heart,
                              size: 14.r,
                              color: isWishlisted
                                  ? const Color(0xFFFBAF18)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Bottom Right Add Button (+)
                  Positioned(
                    right: 8.w,
                    bottom: 8.h,
                    child: GestureDetector(
                      onTap: () => controller.addToCart(product),
                      child: Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primary.withValues(alpha: 0.35),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 20.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info Section
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Discount Text (only when genuine discount exists)
                  if (discount.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Iconsax.discount_shape,
                          size: 11.r,
                          color: const Color(0xFF16A34A),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          discount,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Product Title
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),

                  // Brand Name
                  Text(
                    brand,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColor.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),

                  // Price Row (Responsive Wrap to prevent overflow on large numbers)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5.w,
                    runSpacing: 2.h,
                    children: [
                      Text(
                        '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (originalPrice != null && originalPrice > price)
                        Text(
                          '৳${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)}',
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColor.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
