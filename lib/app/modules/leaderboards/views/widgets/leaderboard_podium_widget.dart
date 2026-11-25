import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/leaderboard_controller.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardPodiumWidget extends GetView<LeaderboardController> {
  const LeaderboardPodiumWidget({super.key});

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rank1 = controller.entryRank1;
      final rank2 = controller.entryRank2;
      final rank3 = controller.entryRank3;

      if (rank1 == null && rank2 == null && rank3 == null) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place (Silver, Left)
            Expanded(
              child: _buildPodiumSlot(
                entry: rank2,
                rankNumber: 2,
                rankLabel: '2nd',
                crownColor: const Color(0xFF94A3B8),
                pedestalHeight: 68.h,
                avatarSize: 52.r,
                pedestalGradient: const LinearGradient(
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderWidth: 2.2,
              ),
            ),
            SizedBox(width: 8.w),

            // 1st Place (Gold, Center - Tallest)
            Expanded(
              child: _buildPodiumSlot(
                entry: rank1,
                rankNumber: 1,
                rankLabel: '1st',
                crownColor: const Color(0xFFEAB308),
                pedestalHeight: 92.h,
                avatarSize: 64.r,
                pedestalGradient: const LinearGradient(
                  colors: [Color(0xFFFEF08A), Color(0xFFFDE047)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderWidth: 3.0,
                isFirst: true,
              ),
            ),
            SizedBox(width: 8.w),

            // 3rd Place (Bronze, Right)
            Expanded(
              child: _buildPodiumSlot(
                entry: rank3,
                rankNumber: 3,
                rankLabel: '3rd',
                crownColor: const Color(0xFFB45309),
                pedestalHeight: 52.h,
                avatarSize: 52.r,
                pedestalGradient: const LinearGradient(
                  colors: [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderWidth: 2.2,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPodiumSlot({
    required LeaderboardEntryModel? entry,
    required int rankNumber,
    required String rankLabel,
    required Color crownColor,
    required double pedestalHeight,
    required double avatarSize,
    required LinearGradient pedestalGradient,
    required double borderWidth,
    bool isFirst = false,
  }) {
    if (entry == null) {
      return SizedBox(
        height: pedestalHeight + 110.h,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: pedestalHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
          ),
        ),
      );
    }

    final isMe = controller.isMyEntry(entry);
    final avatarUrl = entry.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown Icon
        Icon(
          Icons.emoji_events_rounded,
          size: isFirst ? 24.r : 20.r,
          color: crownColor,
        ),
        SizedBox(height: 2.h),

        // Avatar + Rank Number Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: crownColor, width: borderWidth),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: crownColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildInitials(entry.name, crownColor),
                      )
                    : _buildInitials(entry.name, crownColor),
              ),
            ),
            // Rank Number Badge
            Positioned(
              bottom: -4.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: crownColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  '$rankNumber',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Name + [You] Chip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isMe) ...[
              SizedBox(width: 3.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'You',
                  style: GoogleFonts.inter(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Points
        Text(
          '${_formatNumber(entry.points)} pts',
          style: GoogleFonts.lato(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 6.h),

        // Pedestal Base Block
        Container(
          width: double.infinity,
          height: pedestalHeight,
          decoration: BoxDecoration(
            gradient: pedestalGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            border: Border.all(color: crownColor.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rankNumber',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                rankLabel,
                style: GoogleFonts.lato(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
