import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../data/widgets/skeleton_box.dart';
import '../../controllers/category_products_controller.dart';

class CategoryProductsGridSkeleton extends GetView<CategoryProductsController> {
  final bool showSidebar;
  const CategoryProductsGridSkeleton({super.key, this.showSidebar = true});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          showSidebar ? 10.w : 16.w,
          6.h,
          showSidebar ? 10.w : 16.w,
          20.h,
        ),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: showSidebar ? 0.52 : 0.68,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBox(width: 48.w, height: 10.h, radius: 4),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 110.w, height: 12.h, radius: 4),
                      SizedBox(height: 4.h),
                      SkeletonBox(width: 60.w, height: 10.h, radius: 4),
                      SizedBox(height: 8.h),
                      SkeletonBox(width: 70.w, height: 14.h, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
