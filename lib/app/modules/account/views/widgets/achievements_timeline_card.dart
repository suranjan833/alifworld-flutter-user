import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/config/app_color.dart';
import '../../../leaderboards/views/widgets/club_details_sheet.dart';
import '../../controllers/account_controller.dart';
import 'milestone_timeline_widget.dart';

class AchievementsTimelineCard extends GetView<AccountController> {
  const AchievementsTimelineCard({super.key});

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myProg = controller.myProgress.value;
      final activePeriod = controller.selectedClubPeriod.value;
      final periodModel = myProg?.getPeriod(activePeriod);
      final club = periodModel?.club;

      final points = periodModel?.points ?? 0;
      final currentTier = club?.currentTier ?? 'No tier yet';
      final nextTier = club?.nextTier ?? 'Bronze';
      final pointsToNext = club?.pointsToNext ?? 1000;
      final progressVal = ((club?.progressPct ?? 0) / 100.0).clamp(0.0, 1.0);
      final nextTierPct = club?.nextTierPct;

      const periods = [
        {'key': 'daily', 'label': 'Daily'},
        {'key': 'weekly', 'label': 'Weekly'},
        {'key': 'monthly', 'label': 'Monthly'},
        {'key': 'yearly', 'label': 'Yearly'},
      ];

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
        padding: EdgeInsets.all(16.r),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Trophy Icon + "My achievements" + Subtitle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 24.r,
                  color: const Color(0xFFD97706),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My achievements',
                        style: GoogleFonts.lato(
                          fontSize: 16.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Your club tier, across every period.',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // 2. Period Filter Segmented Pills (Daily, Weekly, Monthly, Yearly)
            Row(
              children: periods.map((p) {
                final isSelected = activePeriod == p['key'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: GestureDetector(
                      onTap: () =>
                          controller.changeClubPeriod(p['key'] as String),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF621C),
                                    Color(0xFFEA580C),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p['label'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColor.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),

            // 3. Main Achievement Card (Top Gradient Banner + Bottom Timeline Body)
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
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
                          // Left: Period Points & Value
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${activePeriod.toUpperCase()} POINTS',
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
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
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

                          // Right: Glassmorphism Club Tier Pill
                          GestureDetector(
                            onTap: () => ClubDetailsSheet.show(
                              context,
                              period: activePeriod,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
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
                            activePeriod: activePeriod,
                            pointsToNext: pointsToNext,
                            nextTierDisplayName: nextTierDisplayName,
                            poolShareText: poolShareText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Builds the soft peach/amber incentive pill at bottom
  Widget _buildIncentivePill({
    required BuildContext context,
    required String activePeriod,
    required int pointsToNext,
    required String nextTierDisplayName,
    required String poolShareText,
  }) {
    return GestureDetector(
      onTap: () => ClubDetailsSheet.show(context, period: activePeriod),
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
}
