import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/rewards_info_model.dart';
import '../../../../data/services/rewards_service.dart';
import '../../controllers/leaderboard_controller.dart';

class StarBandsSheet extends GetView<LeaderboardController> {
  final List<StarBandModel>? bands;
  final String? period;

  const StarBandsSheet({
    super.key,
    this.bands,
    this.period,
  });

  static void show(BuildContext context, {String? period}) {
    if (Get.isRegistered<RewardsService>()) {
      RewardsService.to.fetchRewardsInfo();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StarBandsSheet(period: period),
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    String resolvedPeriodKey = 'daily';
    if (period != null && period!.trim().isNotEmpty) {
      resolvedPeriodKey = period!.toLowerCase().trim();
    } else if (Get.isRegistered<LeaderboardController>()) {
      resolvedPeriodKey = controller.selectedPeriod.value.toLowerCase().trim();
    }

    final periodTitle = resolvedPeriodKey.isNotEmpty
        ? (resolvedPeriodKey[0].toUpperCase() + resolvedPeriodKey.substring(1))
        : 'Daily';

    return Obx(() {
      final rewardsInfo = Get.isRegistered<RewardsService>()
          ? RewardsService.to.info.value
          : null;
      final clubPeriodTiers = rewardsInfo?.customerClub[resolvedPeriodKey];

      final bronzePts = clubPeriodTiers?.bronze?.threshold ??
          (resolvedPeriodKey == 'daily'
              ? 1000
              : (resolvedPeriodKey == 'weekly'
                  ? 10000
                  : (resolvedPeriodKey == 'monthly' ? 50000 : 100000)));
      final bronzePct = clubPeriodTiers?.bronze?.pct ?? 1;

      final silverPts = clubPeriodTiers?.silver?.threshold ??
          (resolvedPeriodKey == 'daily'
              ? 2000
              : (resolvedPeriodKey == 'weekly'
                  ? 20000
                  : (resolvedPeriodKey == 'monthly' ? 100000 : 1500000)));
      final silverPct = clubPeriodTiers?.silver?.pct ?? 2;

      final goldPts = clubPeriodTiers?.gold?.threshold ??
          (resolvedPeriodKey == 'daily'
              ? 5000
              : (resolvedPeriodKey == 'weekly'
                  ? 40000
                  : (resolvedPeriodKey == 'monthly' ? 200000 : 2500000)));
      final goldPct = clubPeriodTiers?.gold?.pct ?? 3;

      final tierItems = [
        _ClubTierItem(
          'Bronze',
          '${_formatNumber(bronzePts)} points',
          '$bronzePct% pool share',
          const Color(0xFFB45309),
        ),
        _ClubTierItem(
          'Silver',
          '${_formatNumber(silverPts)} points',
          '$silverPct% pool share',
          const Color(0xFF64748B),
        ),
        _ClubTierItem(
          'Gold',
          '${_formatNumber(goldPts)} points',
          '$goldPct% pool share',
          const Color(0xFFD97706),
        ),
      ];

      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Club details · $periodTitle',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.r,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              ...List.generate(tierItems.length, (index) {
                final item = tierItems[index];
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SizedBox(
                            width: 60.w,
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            item.points,
                            style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.share,
                            style: GoogleFonts.inter(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != tierItems.length - 1)
                      Divider(
                        height: 24.h,
                        thickness: 1.r,
                        color: const Color(0xFFF1F5F9),
                      ),
                  ],
                );
              }),
              SizedBox(height: 14.h),
              Center(
                child: Container(
                  width: 50.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ClubTierItem {
  final String name;
  final String points;
  final String share;
  final Color color;

  const _ClubTierItem(this.name, this.points, this.share, this.color);
}
