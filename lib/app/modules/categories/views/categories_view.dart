import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/categories_controller.dart';
import '../models/category_model.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController());
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColor.primary,
          backgroundColor: AppColor.white,
          onRefresh: controller.refreshCategories,
          child: Obx(
            () => controller.isLoading.value
                ? const CategoriesSkeleton()
                : _buildLoadedBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedBody() {
    return Column(
      children: [
        // Header: Title, subtitle and search button
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${controller.categories.length} collections to explore',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Search button in a soft tinted circle
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFECEEF2),
                      width: 1.r,
                    ),
                  ),
                  child: Icon(
                    Iconsax.search_normal_1,
                    size: 18.r,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Compact 2-column category grid with staggered entrance
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.32,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              // Scale-only entrance: the card is ALWAYS visible (opacity is
              // never gated), so the list can never render blank.
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1.0),
                duration: Duration(milliseconds: 280 + index * 30),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: _buildCategoryCard(controller.categories[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel item) {
    final accent = item.accent ?? const Color(0xFFEFF1F5);
    final imageUrl = item.image ?? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=400&auto=format&fit=crop';
    final name = item.name ?? 'Category';

    return _PressableCard(
      onTap: () {
        Get.toNamed(Routes.CATEGORY_PRODUCTS, arguments: item.toJson());
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColor.white, width: 1.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.05),
              blurRadius: 14.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Category image anchored bottom-right
            Positioned(
              right: -14.w,
              bottom: -10.h,
              child: Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white.withValues(alpha: 0.45),
                ),
                padding: EdgeInsets.all(6.r),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColor.grey.shade300,
                      child: Icon(
                        Iconsax.image,
                        size: 22.r,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Category name on top-left
            Positioned(
              left: 14.w,
              top: 14.h,
              right: 52.w,
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Item count pill bottom-left
            Positioned(
              left: 14.w,
              bottom: 12.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${item.count} items',
                  style: GoogleFonts.inter(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ),

            // Small arrow chip bottom-right (over the image)
            Positioned(
              right: 10.w,
              bottom: 10.h,
              child: Container(
                width: 24.r,
                height: 24.r,
                decoration: const BoxDecoration(
                  color: AppColor.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 13.r,
                  color: AppColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card that scales down slightly while pressed for a tactile premium feel.
class _PressableCard extends StatefulWidget {
  const _PressableCard({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
