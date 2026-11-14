import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../services/rewards_service.dart';
import '../../routes/app_pages.dart';

/// Points badge used across listing cards and PDP:
/// Displays gold coin icon (`<circle cx="12" cy="12" r="10" fill="url(#pts-_r_0_)" stroke="#A85E00" stroke-width="1.4">`)
/// + points value in money (৳) + "points" (e.g. 🪙 ৳300 points) with left-to-right animated glow.
/// Only visible when [points] > 0.
class PointsBadge extends StatefulWidget {
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
  State<PointsBadge> createState() => _PointsBadgeState();
}

class _PointsBadgeState extends State<PointsBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points <= 0) return const SizedBox.shrink();

    // Use live pointValueMinor from RewardsService (fallback 100)
    int pointValueMinor = 100;
    if (Get.isRegistered<RewardsService>()) {
      pointValueMinor = RewardsService.to.pointValueMinor;
    }
    final moneyValue = (widget.points * pointValueMinor) / 100.0;
    final moneyFormatted =
        '৳${moneyValue.toStringAsFixed(moneyValue.truncateToDouble() == moneyValue ? 0 : 2)}';

    final textStyle = GoogleFonts.inter(
      fontSize: widget.fontSize ?? (widget.compact ? 10.5.sp : 12.sp),
      fontWeight: FontWeight.w700,
      color: const Color(0xFFB45309), // amber-700
      letterSpacing: -0.2,
    );

    final coinSize = widget.iconSize ?? (widget.compact ? 14.r : 16.r);
    final borderRadius = BorderRadius.circular(widget.compact ? 6.r : 8.r);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweep coordinate from left (-2.5) to right (+2.5)
        final alignX = -2.5 + (_controller.value * 5.0);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Badge Base Container
              Container(
                padding: widget.padding ??
                    EdgeInsets.symmetric(
                      horizontal: widget.compact ? 6.w : 8.w,
                      vertical: widget.compact ? 2.h : 4.h,
                    ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // amber-100
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: const Color(0xFFFDE68A), // amber-200
                    width: 1.r,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gold Coin Icon with exact SVG specs:
                    // <circle cx="12" cy="12" r="10" fill="url(#pts-_r_0_)" stroke="#A85E00" stroke-width="1.4">
                    Container(
                      width: coinSize,
                      height: coinSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFDF59),
                            Color(0xFFF59E0B),
                            Color(0xFFD97706),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFA85E00),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA85E00).withValues(alpha: 0.35),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '৳',
                          style: GoogleFonts.inter(
                            fontSize: coinSize * 0.62,
                            fontWeight: FontWeight.w900,
                            color: AppColor.white,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: widget.compact ? 4.w : 5.w),
                    // Points text with animated Left-to-Right glow
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(alignX - 0.7, 0.0),
                          end: Alignment(alignX + 0.7, 0.0),
                          colors: const [
                            Color(0xFFB45309), // normal amber-700
                            Color(0xFFEA580C), // bright glowing orange
                            Color(0xFFF59E0B), // bright glowing amber
                            Color(0xFFB45309), // normal amber-700
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        '$moneyFormatted points',
                        style: textStyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.showInfoButton) ...[
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: widget.onInfoTap ?? () => Get.toNamed(Routes.POINTS_HELP),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(2.r),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: (widget.iconSize ?? 15.r) * 0.95,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Left-to-right sweeping light sheen / gloss bar across the badge
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment(alignX - 0.7, 0.0),
                        end: Alignment(alignX + 0.7, 0.0),
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
