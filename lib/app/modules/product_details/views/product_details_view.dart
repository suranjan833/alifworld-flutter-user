import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsView extends GetView<ProductDetailsController> {
  const ProductDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColor.textPrimary,
            size: 24.r,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Product Details',
          style: GoogleFonts.lato(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isWishlisted.value ? Iconsax.heart5 : Iconsax.heart,
                color: controller.isWishlisted.value
                    ? AppColor.primary
                    : AppColor.textPrimary,
                size: 22.r,
              ),
              onPressed: () => controller.toggleWishlist(),
            ),
          ),
          Obx(() {
            if (!Get.isRegistered<BagController>()) {
              Get.put(BagController());
            }
            final bagCtrl = Get.find<BagController>();
            final count = bagCtrl.totalItemCount;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.shopping_bag,
                    color: AppColor.textPrimary,
                    size: 22.r,
                  ),
                  onPressed: () {
                    if (!Get.isRegistered<BagController>()) {
                      Get.put(BagController());
                    }
                    Get.find<BagController>().fetchCart(force: true);
                    Get.toNamed(Routes.BAG);
                  },
                ),
                if (count > 0)
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: IgnorePointer(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: count > 9 ? 4.w : 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A00),
                          shape:
                              count > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius:
                              count > 9 ? BorderRadius.circular(10.r) : null,
                          border: Border.all(color: AppColor.white, width: 1.5.r),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.r,
                          minHeight: 16.r,
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColor.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingDetails.value && controller.product.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.primary),
          );
        }

        if (controller.product.value == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.box,
                      size: 28.r,
                      color: AppColor.textHint,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Product Not Found',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'This product is not currently available in the live catalog.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'Back to Catalog',
                      style: TextStyle(color: AppColor.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Product Image Carousel Gallery
                    _buildImageGallery(),
                    SizedBox(height: 10.h),

                    // 2. Product Title, Rating & Price Card
                    _buildProductInfoCard(),
                    SizedBox(height: 10.h),

                    // 3. Variant Selector Card (if variants exist)
                    _buildVariantsSection(),

                    // 4. Quantity Selector Card
                    _buildQuantityCard(),
                    SizedBox(height: 10.h),

                    // 5. Product Specifications / Highlights Card
                    _buildSpecificationsCard(),
                    SizedBox(height: 10.h),

                    // 6. Description Card
                    _buildDescriptionCard(),
                    SizedBox(height: 10.h),

                    // 7. Seller Details Card
                    _buildSellerCard(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom Bar (Add to Bag & Buy Now)
            _buildBottomActionBar(),
          ],
        );
      }),
    );
  }

  Widget _buildImageGallery() {
    return Obx(() {
      final images = controller.imagesList;
      final discount = controller.activeDiscount;
      final openBox = controller.isOpenBoxDelivery;

      return Container(
        width: double.infinity,
        color: AppColor.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 250.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        controller.selectedImageIndex.value = index;
                      },
                      itemBuilder: (context, index) {
                        final imgUrl = images[index];
                        return Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Center(
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Iconsax.image,
                                size: 60.r,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Discount Badge
                if (discount.isNotEmpty)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        discount,
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                // Open Box Delivery Badge
                if (openBox)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 13.r,
                            color: const Color(0xFF0284C7),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Open Box',
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (images.length > 1) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: controller.selectedImageIndex.value == index ? 18.w : 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: controller.selectedImageIndex.value == index
                          ? AppColor.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildProductInfoCard() {
    return Obx(() {
      final item = controller.product.value;
      if (item == null) return const SizedBox.shrink();
      final title = item.displayTitle;
      final brand = item.displayBrand;
      final rating = item.displayRating.toString();
      final reviews = item.displayReviewsCount.toString();
      final priceStr = controller.activePriceFormatted;
      final originalPriceStr = controller.activeOriginalPriceFormatted;
      final stock = controller.activeStock;

      return Container(
        width: double.infinity,
        color: AppColor.white,
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  brand.toString().toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryDark,
                    letterSpacing: 1,
                  ),
                ),
                if (stock != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: stock > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: stock > 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                        width: 1.r,
                      ),
                    ),
                    child: Text(
                      stock > 0 ? 'In Stock ($stock left)' : 'Out of Stock',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: stock > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              title.toString(),
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
                height: 1.3,
              ),
            ),
            SizedBox(height: 10.h),

            // Rating Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16.r,
                        color: AppColor.primaryDark,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        rating,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '($reviews reviews)',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Price Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceStr,
                  style: GoogleFonts.lato(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                if (originalPriceStr != null) ...[
                  SizedBox(width: 10.w),
                  Text(
                    originalPriceStr,
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      color: AppColor.textHint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildVariantsSection() {
    return Obx(() {
      final variants = controller.variants;
      if (variants.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        color: AppColor.white,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Option',
              style: GoogleFonts.lato(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: List.generate(variants.length, (index) {
                final v = variants[index];
                final label = v.label;
                final isSelected = controller.selectedVariantIndex.value == index;

                return InkWell(
                  onTap: () => controller.selectVariant(index),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primary.withValues(alpha: 0.1) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5.r : 1.r,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColor.primaryDark : AppColor.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuantityCard() {
    return Container(
      width: double.infinity,
      color: AppColor.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.r),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 18.r, color: AppColor.textPrimary),
                  onPressed: () => controller.decrementQuantity(),
                ),
                Obx(
                  () => Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      '${controller.selectedQuantity.value}',
                      style: GoogleFonts.lato(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 18.r, color: AppColor.textPrimary),
                  onPressed: () => controller.incrementQuantity(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard() {
    return Obx(() {
      final item = controller.product.value;
      if (item == null) return const SizedBox.shrink();
      final category = item.categoryName;
      final brand = item.displayBrand;
      final sku = controller.activeSku;
      final attrs = controller.selectedVariant?.attributes;

      return Container(
        width: double.infinity,
        color: AppColor.white,
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Specifications',
              style: GoogleFonts.lato(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            if (brand.isNotEmpty) _buildSpecRow('Brand', brand),
            if (category != null && category.isNotEmpty)
              _buildSpecRow('Category', category),
            if (sku != null && sku.isNotEmpty) _buildSpecRow('SKU', sku),
            if (attrs != null && attrs.isNotEmpty) ...[
              for (var entry in attrs.entries)
                if (entry.value != null && entry.value.toString().isNotEmpty)
                  _buildSpecRow(entry.key, entry.value.toString()),
            ],
            _buildSpecRow('Authenticity', '100% Genuine Guaranteed'),
            _buildSpecRow('Delivery', 'Standard & Open Box Available'),
          ],
        ),
      );
    });
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      color: AppColor.white,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => Text(
              controller.product.value?.cleanDescription ??
                  'High-quality premium product featuring sleek modern design, durable build, and advanced technology. Perfect for everyday usage with industry-leading performance and customer warranty.',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                color: AppColor.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return Obx(() {
      final seller = controller.seller.value;
      final avatar = seller?.avatar.isNotEmpty == true
          ? seller!.avatar
          : 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=200&auto=format&fit=crop';
      final shopName = seller?.shopName ?? 'Alif Official Store';
      final rating = seller?.rating ?? 4.9;
      final reviews = seller?.reviewsCount ?? '1.2k';

      return Container(
        width: double.infinity,
        color: AppColor.white,
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seller Information',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.openSellerDetails(),
                  child: Text(
                    'View Store',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Material(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: () => controller.openSellerDetails(),
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Row(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE2E8F0),
                          image: DecorationImage(
                            image: NetworkImage(avatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  shopName,
                                  style: GoogleFonts.lato(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16.r,
                                  color: const Color(0xFF0284C7),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              '$rating ★ • $reviews ratings',
                              style: GoogleFonts.lato(
                                fontSize: 12.5.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22.r,
                        color: const Color(0xFFA0A7B5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 1.w),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.addToBag(),
                icon: Icon(
                  Iconsax.shopping_bag,
                  size: 18.r,
                  color: AppColor.textPrimary,
                ),
                label: Text(
                  'Add to Bag',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(
                    color: AppColor.border,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.buyNow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
