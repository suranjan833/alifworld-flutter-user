import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../services/rewards_service.dart';
import '../../routes/app_pages.dart';

class PointsBadgeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animController;

  @override
  void onInit() {
    super.onInit();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void onClose() {
    animController.dispose();
    super.onClose();
  }
}

class PointsBadge extends GetView<PointsBadgeController> {
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

    if (!Get.isRegistered<PointsBadgeController>()) {
      Get.put(PointsBadgeController());
    }

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
      color: const Color(0xFFB45309),
      letterSpacing: -0.2,
    );

    final coinSize = iconSize ?? (compact ? 14.r : 16.r);
    final borderRadius = BorderRadius.circular(compact ? 6.r : 8.r);

    return AnimatedBuilder(
      animation: controller.animController,
      builder: (context, child) {
        final alignX = -2.5 + (controller.animController.value * 5.0);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Container(
                padding: padding ??
                    EdgeInsets.symmetric(
                      horizontal: compact ? 6.w : 8.w,
                      vertical: compact ? 2.h : 4.h,
                    ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.r,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    SizedBox(width: compact ? 4.w : 5.w),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(alignX - 0.7, 0.0),
                          end: Alignment(alignX + 0.7, 0.0),
                          colors: const [
                            Color(0xFFB45309),
                            Color(0xFFEA580C),
                            Color(0xFFF59E0B),
                            Color(0xFFB45309),
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        '$moneyFormatted points',
                        style: textStyle.copyWith(color: Colors.white),
                      ),
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
              ),
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
