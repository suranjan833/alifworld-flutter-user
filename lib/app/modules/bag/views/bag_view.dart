import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/no_internet_dialog.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../controllers/bag_controller.dart';
import '../models/cart_model.dart';

class BagView extends GetView<BagController> {
  const BagView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController(), permanent: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shopping Bag',
              style: GoogleFonts.lato(
                fontSize: 19.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            Obx(
              () => controller.cartItems.isNotEmpty
                  ? Text(
                      '${controller.totalItemCount} ${controller.totalItemCount == 1 ? 'item' : 'items'} in your bag',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        color: AppColor.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Obx(
            () => controller.cartItems.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColor.error,
                      size: 22.r,
                    ),
                    tooltip: 'Clear Cart',
                    onPressed: () => _confirmClearCart(context),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cartItems.isEmpty) {
          return const SkeletonCart();
        }

        if (controller.hasInternetError.value && controller.cartItems.isEmpty) {
          return RefreshIndicator(
            color: AppColor.primary,
            onRefresh: () => controller.refreshCart(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.75.sh,
                child: NoInternetWidget(
                  onRetry: () => controller.fetchCart(showLoading: true, force: true),
                ),
              ),
            ),
          );
        }

        if (controller.cartItems.isEmpty) {
          return RefreshIndicator(
            color: AppColor.primary,
            onRefresh: () => controller.refreshCart(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.75.sh,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84.r,
                          height: 84.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7E6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Iconsax.shopping_bag,
                              size: 44.r,
                              color: AppColor.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          'Your Shopping Bag is Empty',
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Explore our top products and add your favorites to your bag.',
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            color: AppColor.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 22.h),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (Get.isRegistered<MainNavigationController>()) {
                              Get.find<MainNavigationController>().changeTab(0);
                            } else {
                              Get.offAllNamed(Routes.MAIN_NAVIGATION);
                            }
                          },
                          icon: Icon(
                            Iconsax.shop,
                            size: 18.r,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Explore Products',
                            style: GoogleFonts.lato(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Free Shipping threshold banner
            _buildFreeShippingBanner(),

            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () => controller.refreshCart(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items List
                      ...List.generate(controller.cartItems.length, (index) {
                        final item = controller.cartItems[index];
                        return _buildCartItemCard(item, index);
                      }),
                      SizedBox(height: 12.h),

                      // Order Price Summary Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: GoogleFonts.lato(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildSummaryRow(
                              'Subtotal (${controller.totalItemCount} items)',
                              '৳${controller.subtotal.toStringAsFixed(2)}',
                            ),
                            SizedBox(height: 8.h),
                            _buildSummaryRow(
                              'Delivery Fee',
                              controller.deliveryFee == 0
                                  ? 'FREE'
                                  : '৳${controller.deliveryFee.toStringAsFixed(2)}',
                              isGreen: controller.deliveryFee == 0,
                            ),
                            if (controller.tax > 0) ...[
                              SizedBox(height: 8.h),
                              _buildSummaryRow(
                                'Estimated Tax',
                                '৳${controller.tax.toStringAsFixed(2)}',
                              ),
                            ],
                            SizedBox(height: 12.h),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            SizedBox(height: 12.h),
                            _buildSummaryRow(
                              'Total Payable',
                              '৳${controller.totalAmount.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Checkout Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0), width: 1.w),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '৳${controller.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 48.h,
                      child: ElevatedButton.icon(
                        onPressed: () => controller.proceedToCheckout(),
                        icon: Text(
                          'Checkout',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        label: const Icon(
                          Iconsax.arrow_right_3,
                          size: 18,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 22.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFreeShippingBanner() {
    final sub = controller.subtotal;
    final isFree = sub >= 499;
    final diff = (499 - sub).clamp(0.0, 499.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: isFree ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFree ? Iconsax.tick_circle : Iconsax.truck_fast,
            size: 16.r,
            color: isFree ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          SizedBox(width: 8.w),
          Text(
            isFree
                ? '🎉 You have unlocked FREE Delivery!'
                : 'Add ৳${diff.toStringAsFixed(0)} more to unlock FREE Delivery',
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: isFree ? const Color(0xFF059669) : const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item, int index) {
    final price = item.price;
    final qty = item.quantity;
    final hasStockWarning = item.maxStock != null && item.maxStock! <= 5 && item.maxStock! > 0;
    final isMaxReached = item.maxStock != null && qty >= item.maxStock!;

    return Dismissible(
      key: Key('cart_${item.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColor.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) => controller.removeItem(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 76.r,
              height: 76.r,
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFEDF2F7)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: item.image.isNotEmpty
                    ? Image.network(
                        item.image,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Iconsax.image,
                          size: 28.r,
                          color: AppColor.textSecondary,
                        ),
                      )
                    : Icon(
                        Iconsax.image,
                        size: 28.r,
                        color: AppColor.textSecondary,
                      ),
              ),
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.brand,
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => controller.removeItem(index),
                        child: Padding(
                          padding: EdgeInsets.all(2.r),
                          child: Icon(
                            Icons.close,
                            size: 18.r,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.title,
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variantLabel != null &&
                      item.variantLabel!.isNotEmpty &&
                      item.variantLabel != item.title) ...[
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.variantLabel!,
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (hasStockWarning) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Only ${item.maxStock} left in stock!',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '৳${price.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                      ),

                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                qty == 1 ? Iconsax.trash : Icons.remove_rounded,
                                size: 16.r,
                                color: qty == 1
                                    ? AppColor.error
                                    : AppColor.textPrimary,
                              ),
                              onPressed: () =>
                                  controller.decrementQuantity(index),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(6.r),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text(
                                '$qty',
                                style: GoogleFonts.lato(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_rounded,
                                size: 16.r,
                                color: isMaxReached
                                    ? const Color(0xFF94A3B8)
                                    : AppColor.textPrimary,
                              ),
                              onPressed: isMaxReached
                                  ? () => controller.incrementQuantity(index)
                                  : () => controller.incrementQuantity(index),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(6.r),
                            ),
                          ],
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

  void _confirmClearCart(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Clear Shopping Bag?',
          style: GoogleFonts.lato(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your shopping bag?',
          style: GoogleFonts.lato(
            fontSize: 13.5.sp,
            color: AppColor.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: AppColor.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: isBold ? 15.sp : 13.5.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColor.textPrimary : AppColor.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: isBold ? 17.sp : 14.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isGreen
                ? const Color(0xFF16A34A)
                : (isBold ? AppColor.textPrimary : AppColor.textPrimary),
          ),
        ),
      ],
    );
  }
}
