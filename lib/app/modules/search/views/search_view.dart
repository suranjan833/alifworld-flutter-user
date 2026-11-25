import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/points_badge.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../../categories/models/product_model.dart';
import '../controllers/catalog_search_controller.dart';

class SearchView extends GetView<CatalogSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CatalogSearchController>()) {
      Get.put(CatalogSearchController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildSearchBar(context),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isPreSearch) {
            return _buildPreSearchBody();
          }

          if (controller.isLoading.value) {
            return _buildLoadingSkeleton();
          }

          if (controller.products.isEmpty) {
            return _buildEmptyState();
          }

          return _buildSearchResults();
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar Search Field
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildSearchBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(66.h),
      child: Container(
        color: AppColor.white,
        padding: EdgeInsets.fromLTRB(
          8.w,
          MediaQuery.of(context).padding.top + 8.h,
          16.w,
          10.h,
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColor.textPrimary,
                size: 24.r,
              ),
              onPressed: () => Get.back(),
              tooltip: 'Back',
            ),

            // Search Input Container
            Expanded(
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Icon(
                      Iconsax.search_normal_1,
                      size: 18.r,
                      color: AppColor.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        focusNode: controller.focusNode,
                        textInputAction: TextInputAction.search,
                        autofocus:
                            controller.searchQuery.value.isEmpty &&
                            controller.selectedCategorySlug.value.isEmpty,
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands...',
                          hintStyle: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            color: AppColor.textHint,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: controller.onQueryChanged,
                        onSubmitted: controller.onSubmit,
                      ),
                    ),
                    Obx(
                      () => controller.searchQuery.value.isNotEmpty
                          ? GestureDetector(
                              onTap: controller.clearSearch,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 8.h,
                                ),
                                child: Container(
                                  width: 22.r,
                                  height: 22.r,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCBD5E1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14.r,
                                    color: AppColor.white,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Orange Search Action Button
            GestureDetector(
              onTap: () => controller.onSubmit(controller.textController.text),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A00), Color(0xFFFF5A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5A00).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColor.white,
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pre-Search State (Recent + Trending + Categories)
  // ---------------------------------------------------------------------------

  Widget _buildPreSearchBody() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      children: [
        // 1. Recent Searches
        Obx(() {
          if (controller.recentSearches.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 16.r,
                        color: AppColor.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Recent Searches',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: controller.clearAllRecentSearches,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: controller.recentSearches.map((term) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: () => controller.selectKeyword(term),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                term,
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              GestureDetector(
                                onTap: () =>
                                    controller.removeRecentSearch(term),
                                child: Padding(
                                  padding: EdgeInsets.all(2.r),
                                  child: Icon(
                                    Icons.close,
                                    size: 14.r,
                                    color: AppColor.textHint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
            ],
          );
        }),

        // 2. Popular / Trending Searches
        Row(
          children: [
            Icon(Iconsax.trend_up, size: 16.r, color: const Color(0xFFFF5A00)),
            SizedBox(width: 6.w),
            Text(
              'Trending Searches',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: controller.popularSearches.map((kw) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => controller.selectKeyword(kw),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 7.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥 $kw',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 26.h),

        // 3. Explore by Category
        Obx(() {
          if (controller.categories.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.category,
                    size: 16.r,
                    color: AppColor.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Explore by Category',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: controller.categories.map((cat) {
                  final slug = cat['slug']?.toString() ?? '';
                  final name = cat['name']?.toString() ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => controller.setCategory(slug, name),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          child: Text(
                            name,
                            style: GoogleFonts.lato(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search Results State
  // ---------------------------------------------------------------------------

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Filter & Sort Sticky Bar
        _buildFilterSortBar(),

        // Product Grid
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5A00),
            backgroundColor: AppColor.white,
            onRefresh: () => controller.performSearch(saveToHistory: false),
            child: GridView.builder(
              controller: controller.scrollController,
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 20.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.62,
              ),
              itemCount:
                  controller.products.length +
                  (controller.hasMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFFF5A00),
                      ),
                    ),
                  );
                }

                final product = controller.products[index];
                return _buildProductCard(context, product);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter & Sort Bar
  // ---------------------------------------------------------------------------

  Widget _buildFilterSortBar() {
    return Container(
      color: AppColor.white,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Column(
        children: [
          Row(
            children: [
              // Sort Pill
              Obx(() {
                String sortLabel = 'Relevance';
                switch (controller.selectedSort.value) {
                  case 'price_asc':
                    sortLabel = 'Price: Low-High';
                    break;
                  case 'price_desc':
                    sortLabel = 'Price: High-Low';
                    break;
                  case 'newest':
                    sortLabel = 'Newest';
                    break;
                }

                final isFiltered = controller.selectedSort.value != 'relevance';

                return _buildPill(
                  icon: Icons.swap_vert_rounded,
                  label: sortLabel,
                  isSelected: isFiltered,
                  onTap: _showSortBottomSheet,
                );
              }),

              SizedBox(width: 8.w),

              // Filter Pill (Price, Category)
              Obx(() {
                final hasFilter =
                    controller.minPriceFilter.value != null ||
                    controller.maxPriceFilter.value != null;
                return _buildPill(
                  icon: Iconsax.setting_4,
                  label: 'Price Range',
                  isSelected: hasFilter,
                  onTap: _showFilterBottomSheet,
                );
              }),

              const Spacer(),

              // Live item count
              Obx(
                () => Text(
                  '${controller.products.length}${controller.hasMore.value ? '+' : ''} items',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Horizontal Category Filter Pills
          Obx(() {
            if (controller.categories.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 36.h,
              margin: EdgeInsets.only(top: 8.h),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(
                    name: 'All',
                    isSelected: controller.selectedCategorySlug.value.isEmpty,
                    onTap: () => controller.setCategory('', ''),
                  ),
                  ...controller.categories.map((c) {
                    final slug = c['slug']?.toString() ?? '';
                    final name = c['name']?.toString() ?? '';
                    final isSelected =
                        controller.selectedCategorySlug.value == slug;
                    return _buildCategoryChip(
                      name: name,
                      isSelected: isSelected,
                      onTap: () => controller.setCategory(slug, name),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5A00)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.r,
              color: isSelected
                  ? const Color(0xFFFF5A00)
                  : AppColor.textPrimary,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFFF5A00)
                    : AppColor.textPrimary,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.r,
              color: isSelected
                  ? const Color(0xFFFF5A00)
                  : AppColor.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF5A00)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Text(
              name,
              style: GoogleFonts.lato(
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColor.white : AppColor.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Product Card
  // ---------------------------------------------------------------------------

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final productId = product.id ?? '';
    final imageUrl = product.image ?? '';
    final title = product.title ?? 'Product';
    final brand = product.brand ?? product.categoryName ?? 'Alifworld';
    final price = product.price;
    final originalPrice = product.originalPrice;
    final discount = product.discount ?? '';
    final points = product.productPoints ?? 0;

    return GestureDetector(
      onTap: () =>
          Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product.toJson()),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFFAFBFC),
                    padding: EdgeInsets.all(8.r),
                    child: Center(
                      child: imageUrl.isEmpty
                          ? Icon(
                              Iconsax.image,
                              size: 32.r,
                              color: AppColor.textSecondary,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Iconsax.image,
                                size: 32.r,
                                color: AppColor.textSecondary,
                              ),
                            ),
                    ),
                  ),

                  // Discount Badge
                  if (discount.isNotEmpty)
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          discount,
                          style: GoogleFonts.lato(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),

                  // Points Badge
                  if (points > 0)
                    Positioned(
                      left: 8.w,
                      bottom: 8.h,
                      child: PointsBadge(points: points, compact: true),
                    ),

                  // Wishlist Heart
                  Positioned(
                    right: 6.w,
                    top: 6.h,
                    child: Obx(() {
                      final vId = (product.variants != null &&
                              product.variants!.isNotEmpty)
                          ? product.variants!.first['id']?.toString()
                          : null;
                      final isWish =
                          controller.isVariantWishlisted(vId, productId);
                      return GestureDetector(
                        onTap: () =>
                            controller.toggleWishlist(productId, vId),
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColor.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isWish
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16.r,
                            color: isWish
                                ? const Color(0xFFEF4444)
                                : AppColor.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Info Content
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '৳${price.toStringAsFixed(0)}',
                        style: GoogleFonts.lato(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF5A00),
                        ),
                      ),
                      if (originalPrice != null && originalPrice > price) ...[
                        SizedBox(width: 6.w),
                        Text(
                          '৳${originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: AppColor.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // Empty State & Skeleton
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_status,
                size: 38.r,
                color: AppColor.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Products Found',
              style: GoogleFonts.lato(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'We couldn\'t find any match for "${controller.searchQuery.value}". Try checking for spelling or using different keywords.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: controller.clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A00),
                foregroundColor: AppColor.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Explore All Products',
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SkeletonShimmer(
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 20.h),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.62,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SkeletonBox(height: double.infinity, radius: 12),
                ),
                SizedBox(height: 10.h),
                SkeletonBox(height: 10.h, width: 60.w, radius: 4),
                SizedBox(height: 6.h),
                SkeletonBox(height: 14.h, width: double.infinity, radius: 4),
                SizedBox(height: 4.h),
                SkeletonBox(height: 14.h, width: 80.w, radius: 4),
                SizedBox(height: 10.h),
                SkeletonBox(height: 16.h, width: 70.w, radius: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Sheets (Sort & Filter)
  // ---------------------------------------------------------------------------

  void _showSortBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort By',
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close,
                    size: 20.r,
                    color: AppColor.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildSortOption('Relevance (Default)', 'relevance'),
            _buildSortOption('Price: Low to High', 'price_asc'),
            _buildSortOption('Price: High to Low', 'price_desc'),
            _buildSortOption('Newest Arrivals', 'newest'),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = controller.selectedSort.value == value;
    return InkWell(
      onTap: () {
        controller.setSort(value);
        Get.back();
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFF5A00)
                    : AppColor.textPrimary,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFFFF5A00),
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final minCtrl = TextEditingController(
      text: controller.minPriceFilter.value != null
          ? controller.minPriceFilter.value!.toStringAsFixed(0)
          : '',
    );
    final maxCtrl = TextEditingController(
      text: controller.maxPriceFilter.value != null
          ? controller.maxPriceFilter.value!.toStringAsFixed(0)
          : '',
    );

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Range Filter',
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    minCtrl.clear();
                    maxCtrl.clear();
                    controller.applyPriceFilter(null, null);
                    Get.back();
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Price (৳)',
                      labelStyle: GoogleFonts.lato(fontSize: 12.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Price (৳)',
                      labelStyle: GoogleFonts.lato(fontSize: 12.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: () {
                  final min = double.tryParse(minCtrl.text.trim());
                  final max = double.tryParse(maxCtrl.text.trim());
                  controller.applyPriceFilter(min, max);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A00),
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filter',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
