import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/points_badge.dart';
import '../controllers/seller_details_controller.dart';

class SellerDetailsView extends GetView<SellerDetailsController> {
  const SellerDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColor.white,
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
        title: Obx(
          () => Text(
            controller.shop.value?.shopName ?? 'Seller Store',
            style: GoogleFonts.lato(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.shop.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isNotFound.value) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.shop_remove, size: 56.r, color: AppColor.textSecondary),
                  SizedBox(height: 16.h),
                  Text(
                    'Shop Not Found',
                    style: GoogleFonts.lato(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This seller store is not currently active or approved.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: const Text('Go Back', style: TextStyle(color: AppColor.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final s = controller.shop.value;
        final shopName = s?.shopName ?? 'Store';
        final logoUrl = s?.fullLogoUrl ?? '';
        final bannerUrl = s?.fullBannerUrl ?? '';
        final desc = s?.description ?? '';

        return RefreshIndicator(
          onRefresh: () => controller.fetchShop(refresh: true),
          color: AppColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Seller Profile Header (Banner, Logo, Shop Name, Description per §6)
                Container(
                  width: double.infinity,
                  color: AppColor.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner
                      if (bannerUrl.isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: 120.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(bannerUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60.r,
                              height: 60.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                image: logoUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(logoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: logoUrl.isEmpty
                                  ? const Icon(Iconsax.shop, color: AppColor.primary)
                                  : null,
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          shopName,
                                          style: GoogleFonts.lato(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 18.r,
                                        color: const Color(0xFF0284C7),
                                      ),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      desc,
                                      style: GoogleFonts.lato(
                                        fontSize: 12.5.sp,
                                        color: AppColor.textSecondary,
                                        height: 1.35,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // 2. Products Section
                Container(
                  width: double.infinity,
                  color: AppColor.white,
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products from this Store',
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      if (controller.products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 36.h),
                          child: Center(
                            child: Text(
                              'No products currently listed.',
                              style: GoogleFonts.lato(
                                fontSize: 13.5.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.64,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                          ),
                          itemCount: controller.products.length,
                          itemBuilder: (context, index) {
                            final product = controller.products[index];
                            return _buildProductCard(product);
                          },
                        ),
                        if (controller.nextCursor.value != null) ...[
                          SizedBox(height: 18.h),
                          Center(
                            child: ElevatedButton(
                              onPressed: controller.isLoadingMore.value
                                  ? null
                                  : () => controller.loadMore(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: controller.isLoadingMore.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: AppColor.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Load More',
                                      style: TextStyle(color: AppColor.white),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProductCard(ShopProductItem product) {
    return GestureDetector(
      onTap: () => controller.openProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.03),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 115.h,
              width: double.infinity,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              ),
              child: Center(
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Iconsax.image, size: 32.r, color: AppColor.grey),
                      )
                    : Icon(Iconsax.image, size: 32.r, color: AppColor.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Points badge per §3
                  if (product.productPoints > 0) ...[
                    PointsBadge(
                      points: product.productPoints,
                      compact: true,
                    ),
                    SizedBox(height: 4.h),
                  ],

                  if (product.discount.isNotEmpty)
                    Text(
                      product.discount,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),

                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      if (product.formattedOriginalPrice != null) ...[
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            product.formattedOriginalPrice!,
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              color: AppColor.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

