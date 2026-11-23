import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../models/leaderboard_model.dart';
import 'milestone_timeline_widget.dart';

class MyProgressCard extends GetView<LeaderboardController> {
  final MyProgressPeriodModel progress;
  final int pendingPoints;
  final bool showStar;

  const MyProgressCard({
    super.key,
    required this.progress,
    this.pendingPoints = 0,
    this.showStar = true,
  });

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final club = progress.club;
    final points = progress.points;
    final currentTier = club?.currentTier ?? 'No tier yet';
    final nextTier = club?.nextTier ?? 'Bronze';
    final pointsToNext = club?.pointsToNext ?? 1000;
    final progressVal = ((club?.progressPct ?? 0) / 100.0).clamp(0.0, 1.0);
    final nextTierPct = club?.nextTierPct;

    final currentTierDisplay =
        (currentTier.isEmpty || currentTier.toLowerCase() == 'no tier')
            ? 'No tier yet'
            : (currentTier.capitalizeFirst ?? currentTier);

    final nextTierDisplayName = (nextTier.isEmpty ||
            nextTier.toLowerCase() == 'no tier')
        ? 'Bronze'
        : (nextTier.capitalizeFirst ?? nextTier);

    final poolShareText = nextTierPct != null
        ? '$nextTierPct% pool share'
        : (nextTierDisplayName == 'Bronze' ? '1% pool share' : 'tier share');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Column(
          children: [
            // Top Half: Vibrant Warm Orange Gradient Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE65100),
                    Color(0xFFBF360C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress.period.toUpperCase()} POINTS',
                          style: GoogleFonts.lato(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFDF59),
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFA85E00),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '৳',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '$points',
                              style: GoogleFonts.lato(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Points',
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  SizedBox(width: 14.w),
                  GestureDetector(
                    onTap: () => controller.showClubDetailsSheet(
                      context,
                      period: progress.period,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 20.r,
                            color: const Color(0xFFFFD54F),
                          ),
                          SizedBox(width: 7.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Club',
                                style: GoogleFonts.lato(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                currentTierDisplay,
                                style: GoogleFonts.lato(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15.r,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Half: White Background with Timeline UI & Incentive Pill
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
              ),
              child: Column(
                children: [
                  MilestoneTimelineWidget(
                    currentTier: currentTier,
                    progressVal: progressVal,
                  ),
                  SizedBox(height: 18.h),
                  _buildIncentivePill(
                    context: context,
                    period: progress.period,
                    pointsToNext: pointsToNext,
                    nextTierDisplayName: nextTierDisplayName,
                    poolShareText: poolShareText,
                  ),
                  if (showStar && progress.star != null) ...[
                    SizedBox(height: 14.h),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () => controller.showConditionsSheet(context),
                      behavior: HitTestBehavior.opaque,
                      child: _buildStarSection(progress.star!),
                    ),
                  ],
                  if (pendingPoints > 0) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          color: const Color(0xFF94A3B8),
                          size: 13.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Pending: $pendingPoints pts (unsettled orders)',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncentivePill({
    required BuildContext context,
    required String period,
    required int pointsToNext,
    required String nextTierDisplayName,
    required String poolShareText,
  }) {
    return GestureDetector(
      onTap: () => controller.showClubDetailsSheet(context, period: period),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFFFEDD5),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24.r,
              height: 24.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFDF59),
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '৳',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: const Color(0xFF1E293B),
                  ),
                  children: [
                    if (pointsToNext > 0) ...[
                      const TextSpan(text: 'Earn '),
                      TextSpan(
                        text: '${_formatNumber(pointsToNext)} more points ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'to reach '),
                      TextSpan(
                        text: nextTierDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                      TextSpan(
                        text: ' ($poolShareText)',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ] else ...[
                      const TextSpan(
                        text:
                            'You hold the top tier in this period! Enjoy maximum pool share.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.r,
              color: const Color(0xFFEA580C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarSection(MyProgressStarModel star) {
    final rankText = star.rank != null ? '#${star.rank}' : 'Unranked';
    final bandName =
        star.displayBand.isNotEmpty ? star.displayBand : 'No Star Band';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Iconsax.medal, color: const Color(0xFFF59E0B), size: 16.r),
            SizedBox(width: 6.w),
            Text(
              'Rank: $rankText',
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (star.totalRanked != null)
              Text(
                ' / ${star.totalRanked}',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bandName,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEA580C),
              ),
            ),
            if (star.ranksToNext > 0 && star.displayNextBand.isNotEmpty)
              Text(
                '${star.ranksToNext} ranks to ${star.displayNextBand}',
                style: GoogleFonts.lato(
                  fontSize: 10.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
