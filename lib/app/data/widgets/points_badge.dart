import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../services/rewards_service.dart';
import '../../routes/app_pages.dart';

/// Points badge used across listing cards and PDP:
/// Displays gold coin icon + points value in money (৳) + "points" (e.g. 🪙 ৳300 points)
/// Only visible when [points] > 0.
class PointsBadge extends StatelessWidget {
  final int points;
  final bool showInfoButton;
  final VoidCallback? onInfoTap;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final bool compact;

  const PointsBadge({
    super.key,
    required this.points,
    this.showInfoButton = false,
    this.onInfoTap,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (points <= 0) return const SizedBox.shrink();

    // Use live pointValueMinor from RewardsService (fallback 100)
    int pointValueMinor = 100;
    if (Get.isRegistered<RewardsService>()) {
      pointValueMinor = RewardsService.to.pointValueMinor;
    }
    final moneyValue = (points * pointValueMinor) / 100.0;
    final moneyFormatted =
        '৳${moneyValue.toStringAsFixed(moneyValue.truncateToDouble() == moneyValue ? 0 : 2)}';

    final textStyle = GoogleFonts.inter(
      fontSize: fontSize ?? (compact ? 10.5.sp : 12.sp),
      fontWeight: FontWeight.w700,
      color: const Color(0xFFB45309), // amber-700
      letterSpacing: -0.2,
    );

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 6.w : 8.w,
            vertical: compact ? 2.h : 4.h,
          ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // amber-100
        borderRadius: BorderRadius.circular(compact ? 6.r : 8.r),
        border: Border.all(
          color: const Color(0xFFFDE68A), // amber-200
          width: 1.r,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gold Coin Icon
          Container(
            width: iconSize ?? (compact ? 13.r : 15.r),
            height: iconSize ?? (compact ? 13.r : 15.r),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                '৳',
                style: GoogleFonts.inter(
                  fontSize: (iconSize ?? (compact ? 13.r : 15.r)) * 0.65,
                  fontWeight: FontWeight.w900,
                  color: AppColor.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 4.w : 5.w),
          Text(
            '$moneyFormatted points',
            style: textStyle,
          ),
          if (showInfoButton) ...[
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onInfoTap ?? () => Get.toNamed(Routes.POINTS_HELP),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: (iconSize ?? 15.r) * 0.95,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
