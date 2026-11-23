import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/referral_level_history_controller.dart';

class ReferralLevelHistoryView extends GetView<ReferralLevelHistoryController> {
  const ReferralLevelHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
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
            'Level ${controller.level.value} Referrals',
            style: GoogleFonts.lato(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isInitialLoading.value && controller.items.isEmpty) {
          return CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: _buildHeaderCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSkeletonLoader(),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColor.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: _buildHeaderCard(),
                ),
              ),
              if (controller.items.isEmpty && !controller.isLoading.value)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else ...[
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.items[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    item.name.isNotEmpty
                                        ? item.name[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.lato(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.lato(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 1.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'Level ${item.level}',
                                        style: GoogleFonts.lato(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.formattedJoinedDate.isNotEmpty)
                                Text(
                                  item.formattedJoinedDate,
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    color: AppColor.textHint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: controller.items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 36.h),
                    child: _buildFooterSection(),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'L${controller.level.value}',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${controller.level.value} Network',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  controller.items.isNotEmpty
                      ? 'Showing ${controller.items.length} ${controller.items.length == 1 ? 'member' : 'members'}'
                      : 'Loading members...',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (controller.ratePct.value > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '${controller.ratePct.value}% Bonus',
                style: GoogleFonts.lato(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SkeletonShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: List.generate(
            7,
            (index) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const SkeletonBox(width: 40, height: 40, circle: true),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 130.w, height: 14.h, radius: 4),
                        SizedBox(height: 6.h),
                        SkeletonBox(width: 60.w, height: 12.h, radius: 4),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 75.w, height: 12.h, radius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.user_search,
                size: 40.r,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Level ${controller.level.value} Referrals Yet',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Users who register through your Level ${controller.level.value} referral link or invited by your downline will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    final hasMore = controller.nextCursor.value != null &&
        controller.nextCursor.value!.isNotEmpty;

    if (hasMore) {
      return Center(
        child: SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton(
            onPressed:
                controller.isLoadingMore.value ? null : controller.loadMore,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.white,
              foregroundColor: AppColor.primary,
              elevation: 0,
              side: BorderSide(color: AppColor.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: controller.isLoadingMore.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.primary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Loading more...',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 18.r),
                      SizedBox(width: 6.w),
                      Text(
                        'Load More Referrals',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    if (controller.items.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            'All Level ${controller.level.value} referrals loaded',
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              color: AppColor.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
