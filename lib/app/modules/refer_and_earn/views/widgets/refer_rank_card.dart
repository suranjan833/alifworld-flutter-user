import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/referral_model.dart';
import '../../controllers/refer_and_earn_controller.dart';

class ReferRankCard extends GetView<ReferAndEarnController> {
  final ReferralInfoModel info;

  const ReferRankCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final rank = info.referRank;
    const stops = ['Unranked', 'Bronze', 'Silver', 'Gold'];
    final currentRankStr = rank.rank.capitalizeFirst ?? 'Unranked';

    double fillPct = 0.0;
    if (rank.l1Count >= rank.thresholds.gold) {
      fillPct = 1.0;
    } else if (rank.l1Count >= rank.thresholds.silver) {
      fillPct = (2 +
              (rank.l1Count - rank.thresholds.silver) /
                  (rank.thresholds.gold - rank.thresholds.silver)) /
          3.0;
    } else if (rank.l1Count >= rank.thresholds.bronze) {
      fillPct = (1 +
              (rank.l1Count - rank.thresholds.bronze) /
                  (rank.thresholds.silver - rank.thresholds.bronze)) /
          3.0;
    } else {
      fillPct = (rank.l1Count / rank.thresholds.bronze) / 3.0;
    }

    const double circleSize = 32.0;
    const double lineHeight = 4.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Orange Hero Header
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFER RANK',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 26.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${rank.l1Count}',
                          style: GoogleFonts.lato(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'level-1 referrals',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Rank Pill
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        color: const Color(0xFFFFD54F),
                        size: 20.r,
                      ),
                      SizedBox(width: 6.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refer rank',
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            currentRankStr,
                            style: GoogleFonts.lato(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Timeline Stepper Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final colWidth = totalWidth / stops.length;
                    final startX = colWidth * 0.5;
                    final trackWidth = colWidth * (stops.length - 1);
                    final activeWidth =
                        (trackWidth * fillPct.clamp(0.0, 1.0)).toDouble();

                    return Stack(
                      children: [
                        // Background track line strictly connecting node centers
                        Positioned(
                          left: startX,
                          top: (circleSize.r - lineHeight.h) / 2,
                          width: trackWidth,
                          height: lineHeight.h,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius:
                                  BorderRadius.circular(lineHeight.h / 2),
                            ),
                          ),
                        ),
                        // Active progress fill line
                        if (activeWidth > 0)
                          Positioned(
                            left: startX,
                            top: (circleSize.r - lineHeight.h) / 2,
                            width: activeWidth,
                            height: lineHeight.h,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
                                borderRadius:
                                    BorderRadius.circular(lineHeight.h / 2),
                              ),
                            ),
                          ),
                        // Evenly-spaced stops
                        Row(
                          children: stops.map((stop) {
                            final isReached = _isRankReached(stop, rank.rank);
                            final reqCount =
                                _getStopThreshold(stop, rank.thresholds);

                            return Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: circleSize.r,
                                    height: circleSize.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isReached
                                          ? const Color(0xFFE65100)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isReached
                                            ? const Color(0xFFE65100)
                                            : const Color(0xFFCBD5E1),
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isReached
                                                  ? const Color(0xFFE65100)
                                                  : Colors.black)
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.emoji_events_rounded,
                                        size: 15.r,
                                        color: isReached
                                            ? Colors.white
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    stop,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                      fontSize: 12.sp,
                                      fontWeight: isReached
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isReached
                                          ? const Color(0xFFE65100)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    reqCount,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 18.h),

                // Callout Alert Box
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEDD5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.award,
                          color: const Color(0xFFEA580C),
                          size: 18.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          rank.nextRank != null &&
                                  rank.referralsToNext != null
                              ? 'Invite ${rank.referralsToNext} more friends to reach ${rank.nextRank!.capitalizeFirst}'
                              : 'You have reached the top Gold rank!',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Thresholds Subtext
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Bronze ${rank.thresholds.bronze} · Silver ${rank.thresholds.silver} · Gold ${rank.thresholds.gold} level-1 referrals\n'
                    'Ranks celebrate your referrals — top referrers may receive gifts from the Alifworld team.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStopThreshold(String stop, ReferThresholds t) {
    switch (stop.toLowerCase()) {
      case 'unranked':
        return '0';
      case 'bronze':
        return '${t.bronze}';
      case 'silver':
        return '${t.silver}';
      case 'gold':
        return '${t.gold}';
      default:
        return '';
    }
  }

  bool _isRankReached(String stop, String currentRank) {
    const order = ['unranked', 'bronze', 'silver', 'gold'];
    final curIdx = order.indexOf(currentRank.toLowerCase());
    final stopIdx = order.indexOf(stop.toLowerCase());
    return curIdx >= stopIdx && stopIdx != -1;
  }
}
