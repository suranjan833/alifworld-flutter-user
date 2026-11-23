import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/category_products_controller.dart';

class CategorySubcategorySidebar extends GetView<CategoryProductsController> {
  const CategorySubcategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84.w,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          right: BorderSide(color: const Color(0xFFF1F5F9), width: 1.r),
        ),
      ),
      child: Obx(() {
        final selectedIndex = controller.selectedSubCategoryIndex.value;
        final subCats = controller.subCategories;

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          itemCount: subCats.length,
          itemBuilder: (context, index) {
            final subCategory = subCats[index];
            final isSelected = index == selectedIndex;

            return GestureDetector(
              onTap: () => controller.selectSubCategory(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF7E6)
                      : AppColor.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.white
                            : const Color(0xFFF6F7F9),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFBAF18,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: index == 0
                            ? Icon(
                                Icons.shopping_basket_outlined,
                                size: 20.r,
                                color: isSelected
                                    ? const Color(0xFFD98200)
                                    : AppColor.textSecondary,
                              )
                            : ClipOval(
                                child: Image.network(
                                  subCategory['icon'] as String,
                                  width: 24.r,
                                  height: 24.r,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Iconsax.grid_5,
                                        size: 18.r,
                                        color: isSelected
                                            ? const Color(0xFFD98200)
                                            : AppColor.textSecondary,
                                      ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subCategory['name'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFD98200)
                            : AppColor.textSecondary,
                        height: 1.15,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
