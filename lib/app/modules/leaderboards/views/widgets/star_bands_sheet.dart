import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/rewards_info_model.dart';
import '../../../../data/services/rewards_service.dart';
import '../../controllers/leaderboard_controller.dart';

class StarBandsSheet extends GetView<LeaderboardController> {
  const StarBandsSheet({super.key});

  static void show(BuildContext context) {
    if (Get.isRegistered<RewardsService>()) {
      RewardsService.to.fetchRewardsInfo();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const StarBandsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rewardsInfo = Get.isRegistered<RewardsService>()
          ? RewardsService.to.info.value
          : null;
      final bands = (rewardsInfo != null && rewardsInfo.customerStarBands.isNotEmpty)
          ? rewardsInfo.customerStarBands
          : [
              StarBandModel(key: 'mega_star', from: 1, to: 10, pct: 1),
              StarBandModel(key: 'super_star', from: 11, to: 50, pct: 1),
              StarBandModel(key: 'star', from: 51, to: 100, pct: 1),
            ];

      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),

              // Header: Icon + Title + Subtitle
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF1EB),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        size: 22.r,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conditions & Rewards',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Star rank bands and pool rewards',
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Band Cards
              ...bands.map((band) => _buildBandCard(band)),
              SizedBox(height: 14.h),

              // Bottom Info Box
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20.r,
                      height: 20.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEA580C),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '!',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFEA580C),
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Rankings are based on points earned from posted orders during the selected trailing period. Pool rewards are distributed equally among members of each band.',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBandCard(StarBandModel band) {
    Color tagBg;
    Color tagColor;
    if (band.key == 'mega_star') {
      tagBg = const Color(0xFFFEF3C7);
      tagColor = const Color(0xFFD97706);
    } else if (band.key == 'super_star') {
      tagBg = const Color(0xFFDBEAFE);
      tagColor = const Color(0xFF2563EB);
    } else {
      tagBg = const Color(0xFFD1FAE5);
      tagColor = const Color(0xFF059669);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              band.displayName,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: tagColor,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              'Ranks ${band.from} – ${band.to}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EB),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '${band.pct}% Pool',
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
