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
      final currentRank = lifetime?.currentRankDisplay ?? 'Regular';
      final nextRank = lifetime?.nextRankDisplay;
      final pointsToNext = lifetime?.pointsToNext ?? (10000 - points).clamp(0, 10000);
      final fillPct = lifetime != null
          ? lifetime.computeTimelineFill().clamp(0.0, 1.0)
          : (points / 10000.0 * (1.0 / 3.0)).clamp(0.0, 1.0);

      final rankColor = _getRankColor(lifetime?.currentRank);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
            // 1. Header: Trophy Icon + Title + Current Rank Badge + Info Button
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 22.r,
                  color: rankColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lifetime Rank',
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${_formatNumber(points)} lifetime points earned',
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    currentRank,
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
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

            // 2. Continuous 4-Stop Progress Ladder
            _buildTimelineTrack(fillPct, points, lifetime?.thresholds),

            SizedBox(height: 14.h),

            // 3. Callout Text Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    nextRank != null ? Icons.trending_up_rounded : Icons.star_rounded,
                    size: 16.r,
                    color: nextRank != null ? const Color(0xFFEA580C) : const Color(0xFFD97706),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      nextRank != null
                          ? 'Earn ${_formatNumber(pointsToNext)} more points to reach $nextRank'
                          : '🎉 Top rank reached: Gold',
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
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

  Widget _buildTimelineTrack(
    double fillFraction,
    int points,
    LifetimeThresholdsModel? thresholds,
  ) {
    final bronze = thresholds?.bronze ?? 10000;
    final silver = thresholds?.silver ?? 50000;
    final gold = thresholds?.gold ?? 100000;

    final stops = [
      {'name': 'Regular', 'label': '0', 'reached': points >= 0, 'color': const Color(0xFF9CA3AF)},
      {'name': 'Bronze', 'label': '${bronze ~/ 1000}k', 'reached': points >= bronze, 'color': const Color(0xFFB45309)},
      {'name': 'Silver', 'label': '${silver ~/ 1000}k', 'reached': points >= silver, 'color': const Color(0xFF6B7280)},
      {'name': 'Gold', 'label': '${gold ~/ 1000}k', 'reached': points >= gold, 'color': const Color(0xFFD97706)},
    ];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const nodeSize = 16.0;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Inactive Background Track
                Container(
                  height: 4.h,
                  width: trackWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // Active Filled Track
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 4.h,
                  width: trackWidth * fillFraction,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9CA3AF), Color(0xFFB45309), Color(0xFF6B7280), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // 4 Stop Nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(stops.length, (idx) {
                    final stop = stops[idx];
                    final isReached = stop['reached'] as bool;
                    final color = stop['color'] as Color;

                    return Container(
                      width: nodeSize.r,
                      height: nodeSize.r,
                      decoration: BoxDecoration(
                        color: isReached ? color : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isReached ? color : const Color(0xFFCBD5E1),
                          width: 2.2,
                        ),
                        boxShadow: isReached
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: isReached
                          ? Icon(
                              Icons.check,
                              size: 10.r,
                              color: Colors.white,
                            )
                          : null,
                    );
                  }),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 8.h),
        // Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stops.length, (idx) {
            final stop = stops[idx];
            final color = stop['color'] as Color;
            final isReached = stop['reached'] as bool;

            return SizedBox(
              width: 56.w,
              child: Column(
                children: [
                  Text(
                    stop['name'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 10.5.sp,
                      fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
                      color: isReached ? color : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    stop['label'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 9.5.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
