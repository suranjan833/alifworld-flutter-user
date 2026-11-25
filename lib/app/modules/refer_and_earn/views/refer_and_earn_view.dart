import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/refer_and_earn_controller.dart';
import 'widgets/refer_rank_card.dart';
import 'widgets/referral_code_card.dart';
import 'widgets/referral_earnings_card.dart';
import 'widgets/referral_hero_banner.dart';
import 'widgets/referral_level_breakdown_card.dart';

class ReferAndEarnView extends GetView<ReferAndEarnController> {
  const ReferAndEarnView({super.key});

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
        title: Text(
          'Refer and Earn',
          style: GoogleFonts.lato(
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.refreshAll(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.referralInfo.value == null) {
          return const SkeletonList(itemCount: 6);
        }

        final info = controller.referralInfo.value;
        if (info == null) {
          return Center(
            child: Text(
              'Failed to load referral details.',
              style: GoogleFonts.lato(color: AppColor.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          color: AppColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReferralHeroBanner(info: info),
                SizedBox(height: 16.h),
                ReferRankCard(info: info),
                SizedBox(height: 16.h),
                ReferralCodeCard(info: info),
                SizedBox(height: 16.h),
                ReferralEarningsCard(info: info),
                SizedBox(height: 16.h),
                ReferralLevelBreakdownCard(info: info),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      }),
    );
  }
}
