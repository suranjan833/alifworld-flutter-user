import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/widgets/app_cached_image.dart';
import '../../../../data/widgets/points_badge.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/category_products_controller.dart';
import '../../models/product_model.dart';

class CategoryProductCard extends GetView<CategoryProductsController> {
  final ProductModel product;

  const CategoryProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final productId = product.id ?? '';
    final imageUrl = product.image ?? '';
    final title = product.title ?? 'Product';
    final brand = product.brand ?? 'Brand';
    final price = product.price;
    final originalPrice = product.originalPrice;
    final discount = product.discount ?? '';

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product.toJson()),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.04),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFFAFBFC),
                    padding: EdgeInsets.all(10.r),
                    child: Center(
                      child: imageUrl.isEmpty
                          ? Icon(
                              Iconsax.image,
                              size: 32.r,
                              color: AppColor.textSecondary,
                            )
                          : AppCachedImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                    ),
                  ),

                  if (product.badge != null)
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          product.badge!,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Obx(() {
                      final vId = (product.variants != null &&
                              product.variants!.isNotEmpty)
                          ? product.variants!.first['id']?.toString()
                          : null;
                      final isWishlisted = controller.isVariantWishlisted(vId);
                      return GestureDetector(
                        onTap: () => controller.toggleWishlist(productId, vId),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Container(
                            key: ValueKey<bool>(isWishlisted),
                            width: 26.r,
                            height: 26.r,
                            decoration: BoxDecoration(
                              color: isWishlisted
                                  ? const Color(0xFFFFF7E6)
                                  : AppColor.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.black.withValues(alpha: 0.06),
                                  blurRadius: 5.r,
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted ? Iconsax.heart5 : Iconsax.heart,
                              size: 14.r,
                              color: isWishlisted
                                  ? const Color(0xFFFBAF18)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  Positioned(
                    right: 8.w,
                    bottom: 8.h,
                    child: GestureDetector(
                      onTap: () => controller.addToCart(product),
                      child: Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primary.withValues(alpha: 0.35),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 20.r,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (discount.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Iconsax.discount_shape,
                          size: 11.r,
                          color: const Color(0xFF16A34A),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          discount,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],

                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),

                  Text(
                    brand,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColor.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((product.productPoints ?? 0) > 0) ...[
                    SizedBox(height: 4.h),
                    PointsBadge(
                      points: product.productPoints!,
                      compact: true,
                    ),
                  ],
                  SizedBox(height: 6.h),

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5.w,
                    runSpacing: 2.h,
                    children: [
                      Text(
                        '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (originalPrice != null && originalPrice > price)
                        Text(
                          '৳${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)}',
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColor.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
