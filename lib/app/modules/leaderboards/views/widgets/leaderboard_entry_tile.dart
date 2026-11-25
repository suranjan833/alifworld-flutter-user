import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/rewards_info_model.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardEntryTile extends GetView<LeaderboardController> {
  final LeaderboardEntryModel entry;
  final bool isMe;
  final StarBandModel? band;

  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    required this.isMe,
    this.band,
  });

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

  Color _getBandColor(String? key) {
    switch (key?.toLowerCase()) {
      case 'mega_star':
        return const Color(0xFFEAB308);
      case 'super_star':
        return const Color(0xFF94A3B8);
      case 'star':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getBandTitle(String? key) {
    switch (key?.toLowerCase()) {
      case 'mega_star':
        return 'Mega Star';
      case 'super_star':
        return 'Super Star';
      case 'star':
        return 'Star';
      default:
        return '';
    }
  }

  IconData _getBandIcon(String? key) {
    switch (key?.toLowerCase()) {
      case 'mega_star':
      case 'super_star':
        return Icons.emoji_events_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = entry.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final bandKey = band?.key;
    final bandColor = _getBandColor(bandKey);
    final bandTitle = _getBandTitle(bandKey);
    final bandIcon = _getBandIcon(bandKey);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF7ED) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isMe ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
          width: isMe ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isMe ? 0.05 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Number (#4, #5, etc.)
          SizedBox(
            width: 34.w,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: isMe ? const Color(0xFFEA580C) : const Color(0xFF475569),
              ),
            ),
          ),

          // User Avatar / Initials
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(
                color: isMe ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitials(entry.name),
                    )
                  : _buildInitials(entry.name),
            ),
          ),
          SizedBox(width: 10.w),

          // Name + Masked Phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.maskedPhone != null && entry.maskedPhone!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    entry.maskedPhone!,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Points + Star Band Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatNumber(entry.points)} pts',
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (bandTitle.isNotEmpty) ...[
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: bandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: bandColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bandIcon, size: 10.r, color: bandColor),
                      SizedBox(width: 3.w),
                      Text(
                        bandTitle,
                        style: GoogleFonts.inter(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: bandColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}
