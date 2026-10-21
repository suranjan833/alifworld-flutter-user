import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/brand_logo_widget.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../home/models/showcase_model.dart';
import '../controllers/top_brands_controller.dart';

class TopBrandsView extends GetView<TopBrandsController> {
  const TopBrandsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TopBrandsController>()) {
      Get.put(TopBrandsController());
    }

    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                backgroundColor: Colors.white,
                onRefresh: controller.fetchBrands,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildSkeletonGrid();
                  }

                  final brands = controller.filteredBrands;
                  if (brands.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildBrandsGrid(brands);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      title: Row(
        children: [
          Text(
            'Top Brands',
            style: GoogleFonts.lato(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColor.primaryLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${controller.filteredBrands.length}',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
        ),
        child: TextField(
          controller: controller.searchController,
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search brands (e.g. Apple, Nike, Acer)...',
            hintStyle: GoogleFonts.lato(
              fontSize: 13.sp,
              color: AppColor.textHint,
            ),
            prefixIcon: Icon(
              Iconsax.search_normal,
              size: 20.r,
              color: AppColor.textHint,
            ),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20.r,
                        color: AppColor.textHint,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13.h),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandsGrid(List<BrandModel> brands) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 14.w,
        childAspectRatio: 0.94,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return _buildBrandCard(brand);
      },
    );
  }

  Widget _buildBrandCard(BrandModel brand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => controller.onBrandTap(brand),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              children: [
                // Bigger, prominently sized logo container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: BrandLogoWidget(
                        logoUrl: brand.fullLogoUrl,
                        brandName: brand.name,
                        width: 120.w,
                        height: 75.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                // Brand name label with arrow
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          brand.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.r,
                        color: AppColor.textHint,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return SkeletonShimmer(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          childAspectRatio: 0.94,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 12.r,
                  ),
                ),
                SizedBox(height: 10.h),
                SkeletonBox(
                  width: 80.w,
                  height: 16.h,
                  radius: 4.r,
                ),
                SizedBox(height: 4.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76.r,
              height: 76.r,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_status,
                size: 34.r,
                color: AppColor.textHint,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Brands Found',
              style: GoogleFonts.lato(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'We could not find any brands matching "${controller.searchQuery.value}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: controller.clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
