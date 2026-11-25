import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/config/app_color.dart';
import '../../../leaderboards/models/leaderboard_model.dart';
import '../../controllers/account_controller.dart';

class LifetimeRankCard extends GetView<AccountController> {
  const LifetimeRankCard({super.key});

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _showLifetimeInfoSheet(
    BuildContext context,
    LifetimeProgressModel? lifetime,
  ) {
    final bronze = lifetime?.thresholds.bronze ?? 10000;
    final silver = lifetime?.thresholds.silver ?? 50000;
    final gold = lifetime?.thresholds.gold ?? 100000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                      'Lifetime Rank Ladder',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
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
              SizedBox(height: 16.h),
              Text(
                'Lifetime ranking points are earned from posted orders. Unlike periodic club points, your lifetime points never reset or expire.',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              _buildLadderTierRow('Regular', '0 - ${_formatNumber(bronze - 1)} pts', const Color(0xFF9CA3AF), 'Starting rank'),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _buildLadderTierRow('Bronze', '${_formatNumber(bronze)} pts', const Color(0xFFB45309), 'Priority club & perks'),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _buildLadderTierRow('Silver', '${_formatNumber(silver)} pts', const Color(0xFF6B7280), 'VIP rewards & gifts'),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _buildLadderTierRow('Gold', '${_formatNumber(gold)}+ pts', const Color(0xFFD97706), 'Top rank & company rewards'),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLadderTierRow(String title, String pts, Color color, String desc) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.lato(
                  fontSize: 11.5.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Text(
          pts,
          style: GoogleFonts.lato(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(String? rank) {
    switch (rank?.toLowerCase()) {
      case 'gold':
        return const Color(0xFFD97706);
      case 'silver':
        return const Color(0xFF6B7280);
      case 'bronze':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myProg = controller.myProgress.value;
      final lifetime = myProg?.lifetime;

      final points = lifetime?.points ?? 0;
      final currentRank = lifetime?.currentRank;
      final isRanked = currentRank != null &&
          currentRank.isNotEmpty &&
          currentRank.toLowerCase() != 'regular';
      final rankDisplay = isRanked ? currentRank.capitalizeFirst! : 'No rank yet';
      final nextRank = lifetime?.nextRankDisplay ?? 'Bronze';
      final pointsToNext = lifetime?.pointsToNext ?? (10000 - points).clamp(0, 10000);
      final fillPct = lifetime != null
          ? lifetime.computeTimelineFill().clamp(0.0, 1.0)
          : (points / 10000.0 * (1.0 / 3.0)).clamp(0.0, 1.0);

      final rankColor = _getRankColor(currentRank);

      final bronze = lifetime?.thresholds.bronze ?? 10000;
      final silver = lifetime?.thresholds.silver ?? 50000;
      final gold = lifetime?.thresholds.gold ?? 100000;

      int activeIndex = 0;
      if (points >= gold) {
        activeIndex = 3;
      } else if (points >= silver) {
        activeIndex = 2;
      } else if (points >= bronze) {
        activeIndex = 1;
      } else {
        activeIndex = 0;
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(18.r),
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
            // 1. Header: Avatar + Title + Status + Info Button
            Row(
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 19.r,
                    color: const Color(0xFFEA580C),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Lifetime Rank',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  rankDisplay,
                  style: GoogleFonts.lato(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isRanked ? rankColor : const Color(0xFF475569),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _showLifetimeInfoSheet(context, lifetime),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18.r,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // 2. 4-Node Progress Ladder
            _buildTimelineTrack(fillPct, activeIndex),

            SizedBox(height: 14.h),

            // 3. Bottom Progress Callout
            points >= gold
                ? Text(
                    '🎉 Top rank reached: Gold',
                    style: GoogleFonts.lato(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: GoogleFonts.lato(
                        fontSize: 12.5.sp,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Earn ${_formatNumber(pointsToNext)} more points to reach ',
                        ),
                        TextSpan(
                          text: nextRank,
                          style: GoogleFonts.lato(
                            color: const Color(0xFFEA580C),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      );
    });
  }

  Widget _buildTimelineTrack(double fillFraction, int activeIndex) {
    const tiers = ['Regular', 'Bronze', 'Silver', 'Gold'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background & Progress Connecting Track
          Positioned(
            top: 15.r,
            left: 20.w,
            right: 20.w,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth;
                final filledW = (totalW * fillFraction).clamp(0.0, totalW);

                return Stack(
                  children: [
                    Container(
                      height: 4.h,
                      width: totalW,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Container(
                      height: 4.h,
                      width: filledW,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 4 Node Badges & Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(tiers.length, (idx) {
              final isCurrent = idx == activeIndex;
              final isPassed = idx < activeIndex;
              final tierName = tiers[idx];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Badge
                  if (isCurrent)
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEA580C),
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 3.5.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 15.r,
                        color: Colors.white,
                      ),
                    )
                  else if (isPassed)
                    Container(
                      width: 30.r,
                      height: 30.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEA580C),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 15.r,
                        color: Colors.white,
                      ),
                    )
                  else
                    Container(
                      width: 30.r,
                      height: 30.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5.r,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 15.r,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  // Label Below
                  Text(
                    tierName,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFFEA580C)
                          : (isPassed ? const Color(0xFF334155) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
