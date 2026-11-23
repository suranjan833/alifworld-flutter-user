import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/app_skeletons.dart';
import '../../../data/widgets/brand_logo_widget.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../controllers/category_products_controller.dart';
import 'widgets/category_product_card.dart';
import 'widgets/category_products_grid_skeleton.dart';
import 'widgets/category_subcategory_sidebar.dart';

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
          backgroundColor: AppColor.white,
          onRefresh: controller.refreshProducts,
          child: Obx(
            () => controller.isLoading.value && controller.allProducts.isEmpty
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
          if (showSidebar) const CategorySubcategorySidebar(),
          Expanded(
            child: Column(
              children: [
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
                Expanded(
                  child: Obx(() {
                    if (controller.isProductsLoading.value &&
                        controller.allProducts.isEmpty) {
                      return CategoryProductsGridSkeleton(showSidebar: showSidebar);
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
                        return CategoryProductCard(product: products[index]);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.white,
      surfaceTintColor: AppColor.white,
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
                width: 38.r,
                height: 38.r,
                fit: BoxFit.contain,
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
        _buildCircularAction(
          icon: Iconsax.search_normal_1,
          onTap: () => Get.toNamed(Routes.SEARCH),
        ),
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
                        border: Border.all(color: AppColor.white, width: 1.5.r),
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
                            color: AppColor.white,
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
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE9ECF1), width: 1.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.03),
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
}
