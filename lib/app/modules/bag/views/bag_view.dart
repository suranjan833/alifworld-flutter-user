import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/bag_controller.dart';
import '../models/cart_model.dart';

class BagView extends GetView<BagController> {
  const BagView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController(), permanent: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<BagController>()) {
        Get.find<BagController>().fetchCart(showLoading: false);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Shopping Bag',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(
            () => controller.cartItems.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Iconsax.trash,
                      color: AppColor.error,
                      size: 20.r,
                    ),
                    onPressed: () => controller.clearCart(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const SkeletonCart();
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
                          width: 80.r,
                          height: 80.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7E6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Iconsax.shopping_bag,
                              size: 42.r,
                              color: AppColor.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
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
                          'Explore products and add them to your bag',
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            color: AppColor.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(Routes.HOME),
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
                            'Subtotal',
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
                          SizedBox(height: 8.h),
                          _buildSummaryRow(
                            'Estimated Tax (5%)',
                            '৳${controller.tax.toStringAsFixed(2)}',
                          ),
                          SizedBox(height: 10.h),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          SizedBox(height: 10.h),
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
                        icon: Icon(
                          Iconsax.card,
                          size: 18.r,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Proceed to Checkout',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
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

  Widget _buildCartItemCard(CartItemModel item, int index) {
    final price = item.price;
    final qty = item.quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70.r,
            height: 70.r,
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    fit: BoxFit.contain,
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
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: GoogleFonts.lato(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.title,
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  '৳${price.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    qty == 1 ? Iconsax.trash : Icons.remove_rounded,
                    size: 16.r,
                    color: qty == 1 ? AppColor.error : AppColor.textPrimary,
                  ),
                  onPressed: () => controller.decrementQuantity(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(6.r),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    '$qty',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    size: 16.r,
                    color: AppColor.textPrimary,
                  ),
                  onPressed: () => controller.incrementQuantity(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(6.r),
                ),
              ],
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
