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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              Row(
                children: [
                  Icon(Iconsax.star, color: const Color(0xFFFBBF24), size: 16.r),
                  SizedBox(width: 4.w),
                  Text(
                    '${progress.points} pts',
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.white,
                    ),
                  ),
                ],
              ),
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
    final bandName = star.band?.displayName ?? 'No Star Band';

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
        Text(
          bandName,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF60A5FA),
          ),
        ),
      ],
    );
  }
}
