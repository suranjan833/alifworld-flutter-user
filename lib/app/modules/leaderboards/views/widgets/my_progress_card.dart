import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../models/leaderboard_model.dart';

class MyProgressCard extends StatelessWidget {
  final MyProgressPeriodModel progress;
  final int pendingPoints;
  final bool showStar; // true on Leaderboards, false on Account

  const MyProgressCard({
    super.key,
    required this.progress,
    this.pendingPoints = 0,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF0F1123),
              Color(0xFF151833),
              Color(0xFF1D1B44),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.20),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1123).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-right purple / violet luminous ambient wave aura
            Positioned(
              right: -30.w,
              top: -30.h,
              child: Container(
                width: 170.w,
                height: 130.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF818CF8).withValues(alpha: 0.30),
                      const Color(0xFF6366F1).withValues(alpha: 0.18),
                      const Color(0xFF4338CA).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Period Header & Total Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      progress.period.toUpperCase(),
                      style: GoogleFonts.lato(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Your Progress',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.white,
                    ),
                  ),
                ],
              ),
              _GlowingPointsBadge(points: progress.points),
            ],
          ),

          SizedBox(height: 14.h),

          // Club Progress
          if (progress.club != null) _buildClubSection(progress.club!),

          // Star Progress
          if (showStar && progress.star != null) ...[
            SizedBox(height: 12.h),
            const Divider(color: Color(0xFF334155), height: 1),
            SizedBox(height: 12.h),
            _buildStarSection(progress.star!),
          ],

          // Pending points note
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

  Widget _buildClubSection(MyProgressClubModel club) {
    final currentTier = club.currentTier ?? 'No Tier';
    final nextTier = club.nextTier;
    final progressVal = (club.progressPct / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Iconsax.crown, color: const Color(0xFFF59E0B), size: 16.r),
                SizedBox(width: 6.w),
                Text(
                  'Club: ${currentTier.toUpperCase()}${club.currentTierPct != null ? " (${club.currentTierPct}%)" : ""}',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
            if (nextTier != null)
              Text(
                '${club.pointsToNext} pts to ${nextTier.toUpperCase()}',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  color: const Color(0xFF94A3B8),
                ),
              )
            else
              Text(
                'Top Tier Held',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: progressVal,
            minHeight: 6.h,
            backgroundColor: const Color(0xFF334155),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
          ),
        ),
      ],
    );
  }

  Widget _buildStarSection(MyProgressStarModel star) {
    final rankText = star.rank != null ? '#${star.rank}' : 'Unranked';
    final bandName = star.displayBand.isNotEmpty ? star.displayBand : 'No Star Band';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Iconsax.medal, color: const Color(0xFF60A5FA), size: 16.r),
            SizedBox(width: 6.w),
            Text(
              'Rank: $rankText',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE2E8F0),
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
                color: const Color(0xFF60A5FA),
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

/// Circular golden points token (`<circle cx="12" cy="12" r="10" fill="url(#pts-_r_0_)" stroke="#A85E00" stroke-width="1.4">`)
/// along with animated left-to-right glowing points text.
class _GlowingPointsBadge extends StatefulWidget {
  final int points;
  const _GlowingPointsBadge({required this.points});

  @override
  State<_GlowingPointsBadge> createState() => _GlowingPointsBadgeState();
}

class _GlowingPointsBadgeState extends State<_GlowingPointsBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value;
        final slide = -1.0 + (progress * 3.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 19.r,
              height: 19.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF3B0),
                    Color(0xFFFFD54F),
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                  stops: [0.0, 0.35, 0.7, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFA85E00),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.star_rounded,
                size: 11.r,
                color: const Color(0xFF78350F),
              ),
            ),
            SizedBox(width: 5.w),
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    (slide - 0.3).clamp(0.0, 1.0),
                    slide.clamp(0.0, 1.0),
                    (slide + 0.3).clamp(0.0, 1.0),
                  ],
                  colors: const [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFE082),
                    Color(0xFFFFFFFF),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                '${widget.points} pts',
                style: GoogleFonts.lato(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
