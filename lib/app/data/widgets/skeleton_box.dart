import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../config/app_color.dart';
export 'app_skeletons.dart';

class SkeletonShimmerController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animController;

  @override
  void onInit() {
    super.onInit();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void onClose() {
    animController.dispose();
    super.onClose();
  }
}

class SkeletonBox extends GetView<SkeletonShimmerController> {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: circle ? null : height,
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius.r),
      ),
    );
  }
}

class SkeletonShimmer extends GetView<SkeletonShimmerController> {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SkeletonShimmerController>()) {
      Get.put(SkeletonShimmerController());
    }

    return AnimatedBuilder(
      animation: controller.animController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final dx = bounds.width;
            final dy = bounds.height;
            final rect = Rect.fromLTWH(
              -dx + (dx * 2 + dy) * controller.animController.value,
              -dy,
              dx + dy,
              dx + dy,
            );
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColor.white.withValues(alpha: 0),
                AppColor.white.withValues(alpha: 0.55),
                AppColor.white.withValues(alpha: 0),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: child,
    );
  }
}

class SkeletonList extends GetView<SkeletonShimmerController> {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding,
    this.shrinkWrap = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding:
                  EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12.h),
              child: const _SkeletonTile(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends GetView<SkeletonShimmerController> {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBox(width: 48, height: 48, circle: true),
          SizedBox(width: 12.w),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(width: 140.w, height: 13.h, radius: 6),
                SizedBox(height: 8.h),
                SkeletonBox(width: 200.w, height: 10.h, radius: 5),
                SizedBox(height: 6.h),
                SkeletonBox(width: 90.w, height: 10.h, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonProfile extends GetView<SkeletonShimmerController> {
  const SkeletonProfile({
    super.key,
    this.itemCount = 8,
    this.shrinkWrap = true,
  });

  final int itemCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  const SkeletonBox(width: 84, height: 84, circle: true),
                  SizedBox(height: 12.h),
                  SkeletonBox(width: 150.w, height: 16.h, radius: 8),
                  SizedBox(height: 8.h),
                  SkeletonBox(width: 110.w, height: 11.h, radius: 5),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            ...List.generate(
              itemCount,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: const _SkeletonTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonHome extends GetView<SkeletonShimmerController> {
  const SkeletonHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: const Color(0xFFECEFF3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 80.w, height: 26.h, radius: 6),
                      const Spacer(),
                      const SkeletonBox(width: 24, height: 24, circle: true),
                      SizedBox(width: 12.w),
                      const SkeletonBox(width: 24, height: 24, circle: true),
                      SizedBox(width: 12.w),
                      SkeletonBox(width: 38.w, height: 22.h, radius: 8),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              height: 220.h,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF3),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFECEFF3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  5,
                  (index) => Column(
                    children: [
                      const SkeletonBox(width: 44, height: 44, circle: true),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 42.w, height: 9.h, radius: 4),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 170.w, height: 16.h, radius: 7),
                  SkeletonBox(width: 48.w, height: 12.h, radius: 5),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  const _SkeletonHorizontalCard(),
                  SizedBox(width: 12.w),
                  const _SkeletonHorizontalCard(),
                  SizedBox(width: 12.w),
                  const _SkeletonHorizontalCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonHorizontalCard extends GetView<SkeletonShimmerController> {
  const _SkeletonHorizontalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160.w,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120.w, height: 12.h, radius: 6),
                SizedBox(height: 6.h),
                SkeletonBox(width: 70.w, height: 10.h, radius: 5),
                SizedBox(height: 12.h),
                SkeletonBox(width: 56.w, height: 14.h, radius: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
