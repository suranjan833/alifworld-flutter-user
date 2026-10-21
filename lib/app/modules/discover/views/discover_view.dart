import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/discover_controller.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DiscoverController>()) {
      Get.put(DiscoverController());
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Obx(
          () => controller.isLoading.value
              ? const SkeletonHome()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header: Discover Title + Bag Icon
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discover',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Icon(
                      Iconsax.shopping_bag,
                      size: 24.r,
                      color: AppColor.textPrimary,
                    ),
                  ],
                ),
              ),

              // 2. Categories Horizontal Bar (replaces old seller stories)
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      controller.discoverCategories.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: _buildCategoryChip(
                          controller.discoverCategories[index],
                          isSelected:
                              controller.selectedCategoryIndex.value == index,
                          onTap: () => controller.selectCategory(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
              Divider(height: 1.h, color: const Color(0xFFEEEEEE)),
              SizedBox(height: 16.h),

              // 3. Staggered Feed Posts (2 Columns)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(
                  () {
                    if (controller.posts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Text(
                            'No items found in this category',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    final leftIndices = <int>[];
                    final rightIndices = <int>[];
                    for (int i = 0; i < controller.posts.length; i++) {
                      if (i % 2 == 0) {
                        leftIndices.add(i);
                      } else {
                        rightIndices.add(i);
                      }
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 0; i < leftIndices.length; i++) ...[
                                if (i > 0) SizedBox(height: 16.h),
                                _buildPostCard(
                                  controller.posts[leftIndices[i]],
                                  leftIndices[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Right Column
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 0; i < rightIndices.length; i++) ...[
                                if (i > 0) SizedBox(height: 16.h),
                                _buildPostCard(
                                  controller.posts[rightIndices[i]],
                                  rightIndices[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Horizontal category chip: circular image + label, highlighted when
  /// selected.
  Widget _buildCategoryChip(
    Map<String, dynamic> category, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = category['accent'] as Color? ?? const Color(0xFFF6F7F9);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(
                color: isSelected ? AppColor.primary : Colors.transparent,
                width: 2.r,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                category['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Iconsax.image,
                    size: 18.r,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            category['name'] as String,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColor.textPrimary
                  : AppColor.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final hasOverlayText = (post['overlayText'] as String? ?? '').isNotEmpty;
    final isLiked = post['isLiked'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media Card
        GestureDetector(
          onTap: () {
            final prod = post['productModel'];
            if (prod != null) {
              Get.toNamed(Routes.PRODUCT_DETAILS,
                  arguments: prod.toDetailsMap());
            } else {
              Get.toNamed(Routes.PRODUCT_DETAILS,
                  arguments: post['raw'] ?? post);
            }
          },
          child: Container(
            width: double.infinity,
            height: (index % 4 == 0)
                ? 260.h
                : (index % 4 == 1)
                    ? 220.h
                    : (index % 4 == 2)
                        ? 230.h
                        : 270.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Stack(
            children: [
              // Main Image
              Image.network(
                post['image'] as String,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Icon(
                      Iconsax.image,
                      size: 32.r,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),

              // Bottom Gradient Overlay for text readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 90.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Center Banner Text (e.g. "NEXT-LEVEL DESIGN.")
              if (hasOverlayText)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      post['overlayText'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Title at bottom of card
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: Text(
                  post['title'] as String,
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ),

        SizedBox(height: 8.h),

        // Seller Info & Likes Row under card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Seller Info (Avatar + Name)
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10.r,
                    backgroundImage: NetworkImage(
                      post['sellerAvatar'] as String,
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      post['sellerName'] as String,
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Likes Button
            GestureDetector(
              onTap: () => controller.toggleLike(index),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Iconsax.heart5 : Iconsax.heart,
                    size: 14.r,
                    color: isLiked ? Colors.red : AppColor.textPrimary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${post['likes']}',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
