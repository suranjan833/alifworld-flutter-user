import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
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
        title: Text(
          'Seller Profile',
          style: GoogleFonts.lato(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Seller Profile Header Banner
            Obx(() {
              final s = controller.seller;

              return Container(
                width: double.infinity,
                color: AppColor.white,
                padding: EdgeInsets.all(20.r),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64.r,
                          height: 64.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE2E8F0),
                            image: DecorationImage(
                              image: NetworkImage(s['avatar'] as String? ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s['name'] as String? ?? 'Seller',
                                    style: GoogleFonts.lato(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
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
                              SizedBox(height: 3.h),
                              Text(
                                s['location'] as String? ?? '',
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => controller.toggleFollow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.isFollowing.value
                                ? const Color(0xFFF1F5F9)
                                : AppColor.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            controller.isFollowing.value
                                ? 'Following'
                                : 'Follow',
                            style: GoogleFonts.lato(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: controller.isFollowing.value
                                  ? AppColor.textSecondary
                                  : AppColor.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Stats bar
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Rating', '${s['rating']} ★'),
                          _buildStatItem(
                            'Reviews',
                            s['reviewsCount'] as String? ?? '0',
                          ),
                          _buildStatItem(
                            'Response',
                            s['responseRate'] as String? ?? '0%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 10.h),

            // 2. About Seller
            Obx(() {
              final bio = controller.seller['bio'] as String? ?? '';
              if (bio.isEmpty) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                color: AppColor.white,
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Store',
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      bio,
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        color: AppColor.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 10.h),

            // 3. Products Grid
            Container(
              width: double.infinity,
              color: AppColor.white,
              padding: EdgeInsets.all(20.r),
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

                  Obx(
                    () {
                      if (controller.sellerProducts.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              'No products listed by this store yet.',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                        ),
                        itemCount: controller.sellerProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.sellerProducts[index];
                          final img = product['image']?.toString() ?? '';
                          final brand = product['brand']?.toString() ?? '';
                          final title = product['title']?.toString() ??
                              product['name']?.toString() ??
                              '';
                          final price = product['price']?.toString() ?? '';

                          return GestureDetector(
                            onTap: () => controller.openProductDetails(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 110.h,
                                    width: double.infinity,
                                    padding: EdgeInsets.all(8.r),
                                    child: Center(
                                      child: img.isNotEmpty
                                          ? Image.network(
                                              img,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Icon(Icons.image,
                                                          size: 32.r,
                                                          color: AppColor.grey),
                                            )
                                          : Icon(Icons.image,
                                              size: 32.r, color: AppColor.grey),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (brand.isNotEmpty)
                                          Text(
                                            brand,
                                            style: GoogleFonts.lato(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColor.primaryDark,
                                            ),
                                          ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          title,
                                          style: GoogleFonts.lato(
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          price,
                                          style: GoogleFonts.lato(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11.5.sp,
            color: AppColor.textSecondary,
          ),
        ),
      ],
    );
  }
}
