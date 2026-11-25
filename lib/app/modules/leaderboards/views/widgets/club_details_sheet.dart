import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/services/rewards_service.dart';
import '../../controllers/club_details_controller.dart';

class ClubDetailsSheet extends GetView<ClubDetailsController> {
  final String? period;

  const ClubDetailsSheet({
    super.key,
    this.period,
  });

  static void show(BuildContext context, {String? period}) {
    if (!Get.isRegistered<RewardsService>()) {
      Get.put(RewardsService());
    }
    RewardsService.to.fetchRewardsInfo();

    if (!Get.isRegistered<ClubDetailsController>()) {
      Get.put(ClubDetailsController());
    }
    Get.find<ClubDetailsController>().setPeriod(period);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClubDetailsSheet(period: period),
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  static Color _getTierColor(String name) {
    switch (name.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFB45309);
      case 'silver':
        return const Color(0xFF64748B);
      case 'gold':
        return const Color(0xFFD97706);
      case 'platinum':
        return const Color(0xFF0284C7);
      case 'diamond':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activePeriod = (period != null && period!.trim().isNotEmpty)
          ? period!.toLowerCase().trim()
          : controller.selectedPeriod.value;

      final periodTitle = activePeriod.isNotEmpty
          ? (activePeriod[0].toUpperCase() + activePeriod.substring(1))
          : 'Daily';

      final rewardsInfo = Get.isRegistered<RewardsService>()
          ? RewardsService.to.info.value
          : null;
      final clubPeriodTiers = rewardsInfo?.customerClub[activePeriod];

      final List<_ClubTierItem> tierItems = [];

      if (clubPeriodTiers != null && clubPeriodTiers.allTiers.isNotEmpty) {
        final sortedKeys = clubPeriodTiers.allTiers.keys.toList()
          ..sort((a, b) {
            final tA = clubPeriodTiers.allTiers[a]?.threshold ?? 0;
            final tB = clubPeriodTiers.allTiers[b]?.threshold ?? 0;
            return tA.compareTo(tB);
          });

        for (final k in sortedKeys) {
          final tier = clubPeriodTiers.allTiers[k]!;
          final displayName = k.capitalizeFirst ?? k;
          tierItems.add(
            _ClubTierItem(
              displayName,
              '${_formatNumber(tier.threshold)} points',
              '${tier.pct}% pool share',
              _getTierColor(k),
            ),
          );
        }
      } else {
        // Fallback defaults while rewards info is fetching
        final bronzePts = clubPeriodTiers?.bronze?.threshold ??
            (activePeriod == 'daily'
                ? 1000
                : (activePeriod == 'weekly'
                    ? 10000
                    : (activePeriod == 'monthly' ? 50000 : 100000)));
        final bronzePct = clubPeriodTiers?.bronze?.pct ?? 1;

        final silverPts = clubPeriodTiers?.silver?.threshold ??
            (activePeriod == 'daily'
                ? 2000
                : (activePeriod == 'weekly'
                    ? 20000
                    : (activePeriod == 'monthly' ? 100000 : 1500000)));
        final silverPct = clubPeriodTiers?.silver?.pct ?? 2;

        final goldPts = clubPeriodTiers?.gold?.threshold ??
            (activePeriod == 'daily'
                ? 5000
                : (activePeriod == 'weekly'
                    ? 40000
                    : (activePeriod == 'monthly' ? 200000 : 2500000)));
        final goldPct = clubPeriodTiers?.gold?.pct ?? 3;

        tierItems.addAll([
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
        ]);
      }

      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
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
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
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
              SizedBox(height: 18.h),
              ...List.generate(tierItems.length, (index) {
                final item = tierItems[index];
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
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
                            width: 68.w,
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
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
                        height: 22.h,
                        thickness: 1.r,
                        color: const Color(0xFFF1F5F9),
                      ),
                  ],
                );
              }),
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
