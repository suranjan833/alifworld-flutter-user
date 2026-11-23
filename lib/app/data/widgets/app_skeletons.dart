import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../config/app_color.dart';
import 'skeleton_box.dart';

class SkeletonCardGrid extends GetView<SkeletonShimmerController> {
  const SkeletonCardGrid({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 0.62,
    this.padding,
    this.shrinkWrap = true,
  });

  final int itemCount;
  final double aspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends GetView<SkeletonShimmerController> {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(color: const Color(0xFFECEFF3)),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 12.h, radius: 6),
                  SizedBox(height: 6.h),
                  SkeletonBox(width: 70.w, height: 10.h, radius: 5),
                  const Spacer(),
                  SkeletonBox(width: 56.w, height: 14.h, radius: 7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonDetail extends GetView<SkeletonShimmerController> {
  const SkeletonDetail({
    super.key,
    this.includeGallery = true,
    this.includeSpecs = true,
  });

  final bool includeGallery;
  final bool includeSpecs;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 320.h,
            color: const Color(0xFFECEFF3),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100.w, height: 12.h, radius: 6),
                SizedBox(height: 10.h),
                SkeletonBox(width: double.infinity, height: 18.h, radius: 8),
                SizedBox(height: 6.h),
                SkeletonBox(width: 220.w, height: 18.h, radius: 8),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    SkeletonBox(width: 90.w, height: 22.h, radius: 8),
                    SizedBox(width: 10.w),
                    SkeletonBox(width: 60.w, height: 14.h, radius: 6),
                  ],
                ),
                SizedBox(height: 20.h),
                if (includeSpecs) ...[
                  Row(
                    children: [
                      Expanded(child: const _SkeletonStatTile()),
                      SizedBox(width: 10.w),
                      Expanded(child: const _SkeletonStatTile()),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(child: const _SkeletonStatTile()),
                      SizedBox(width: 10.w),
                      Expanded(child: const _SkeletonStatTile()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonStatTile extends GetView<SkeletonShimmerController> {
  const _SkeletonStatTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 28, height: 28, circle: true),
          SizedBox(height: 10.h),
          SkeletonBox(width: 90.w, height: 16.h, radius: 7),
          SizedBox(height: 6.h),
          SkeletonBox(width: 60.w, height: 10.h, radius: 5),
        ],
      ),
    );
  }
}

class SkeletonCart extends GetView<SkeletonShimmerController> {
  const SkeletonCart({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (_, _) => const _SkeletonCartItem(),
            ),
          ),
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              children: [
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 10.h),
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 10.h),
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 14.h),
                SkeletonBox(width: double.infinity, height: 46.h, radius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCartItem extends GetView<SkeletonShimmerController> {
  const _SkeletonCartItem();

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
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120.w, height: 13.h, radius: 6),
                SizedBox(height: 8.h),
                SkeletonBox(width: double.infinity, height: 10.h, radius: 5),
                SizedBox(height: 8.h),
                SkeletonBox(width: 80.w, height: 14.h, radius: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonChat extends GetView<SkeletonShimmerController> {
  const SkeletonChat({super.key, this.bubbleCount = 8});

  final int bubbleCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        itemCount: bubbleCount,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final isMe = index.isOdd;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: 36.h,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoriesSkeleton extends GetView<SkeletonShimmerController> {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 130.w, height: 22.h, radius: 6),
                      SizedBox(height: 8.h),
                      SkeletonBox(width: 170.w, height: 12.h, radius: 6),
                    ],
                  ),
                ),
                const SkeletonBox(width: 40, height: 40, circle: true),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.32,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 90.w, height: 14.h, radius: 6),
                      SizedBox(height: 8.h),
                      SkeletonBox(width: 60.w, height: 14.h, radius: 6),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 56.w, height: 18.h, radius: 9),
                          const SkeletonBox(
                            width: 24,
                            height: 24,
                            circle: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryProductsSkeleton extends GetView<SkeletonShimmerController> {
  const CategoryProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84.w,
            decoration: const BoxDecoration(
              color: AppColor.white,
              border: Border(
                right: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: Column(
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                  child: Column(
                    children: [
                      const SkeletonBox(width: 38, height: 38, circle: true),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 52.w, height: 9.h, radius: 4),
                    ],
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
                  child: Row(
                    children: [
                      SkeletonBox(width: 84.w, height: 32.h, radius: 12),
                      SizedBox(width: 8.w),
                      SkeletonBox(width: 76.w, height: 32.h, radius: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 20.h),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF3),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: double.infinity,
                              height: 90.h,
                              radius: 12,
                            ),
                            SizedBox(height: 10.h),
                            SkeletonBox(width: 70.w, height: 12.h, radius: 6),
                            SizedBox(height: 6.h),
                            SkeletonBox(width: 48.w, height: 10.h, radius: 5),
                            const Spacer(),
                            SkeletonBox(width: 64.w, height: 14.h, radius: 7),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
