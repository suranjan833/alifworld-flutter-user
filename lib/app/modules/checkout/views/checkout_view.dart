import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          'Checkout',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery Address Card
                  Obx(
                    () => _buildSectionHeader(
                      'Delivery Address',
                      actionText: controller.addresses.isNotEmpty
                          ? (controller.addresses.length > 1
                              ? 'Change'
                              : '+ Add New')
                          : null,
                      onAction: () {
                        if (controller.addresses.length > 1) {
                          _showAddressSelectionBottomSheet(context);
                        } else {
                          controller.openAddAddressModal(context);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() {
                    if (controller.isLoadingAddresses.value) {
                      return Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (controller.addresses.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52.r,
                              height: 52.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF7E6),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Iconsax.location,
                                  size: 26.r,
                                  color: AppColor.primaryDark,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No Delivery Address',
                              style: GoogleFonts.lato(
                                fontSize: 15.5.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Add your shipping address to proceed with order',
                              style: GoogleFonts.lato(
                                fontSize: 12.5.sp,
                                color: AppColor.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 14.h),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  controller.openAddAddressModal(context),
                              icon: const Icon(
                                Iconsax.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                'Add Delivery Address',
                                style: GoogleFonts.lato(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.w,
                                  vertical: 10.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final selectedIndex =
                        controller.selectedAddressIndex.value;
                    final validIndex =
                        (selectedIndex >= 0 &&
                                selectedIndex < controller.addresses.length)
                            ? selectedIndex
                            : 0;
                    final addr = controller.addresses[validIndex];
                    final name = addr['name'] as String? ?? '';
                    final phone = addr['phone'] as String? ?? '';
                    final type = addr['type'] as String? ?? 'Home';
                    final addressText = addr['address'] as String? ?? '';

                    return InkWell(
                      onTap: () => _showAddressSelectionBottomSheet(context),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: Icon(
                                  Iconsax.location5,
                                  color: AppColor.primaryDark,
                                  size: 20.r,
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
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          type,
                                          style: GoogleFonts.lato(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (phone.isNotEmpty) ...[
                                        SizedBox(width: 8.w),
                                        Text(
                                          phone,
                                          style: GoogleFonts.lato(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (name.isNotEmpty && name != 'Customer') ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      name,
                                      style: GoogleFonts.lato(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 4.h),
                                  Text(
                                    addressText,
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp,
                                      color: AppColor.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Change',
                                    style: GoogleFonts.lato(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.primaryDark,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 16.r,
                                    color: AppColor.primaryDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 14.h),

                  // 2. Order Items Card
                  _buildSectionHeader('Order Items'),
                  SizedBox(height: 8.h),
                  Obx(() {
                    if (controller.items.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Text(
                            'No items in order',
                            style: GoogleFonts.lato(
                              fontSize: 13.5.sp,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: List.generate(controller.items.length, (
                          index,
                        ) {
                          final item = controller.items[index];
                          final isLast = index == controller.items.length - 1;
                          final price =
                              (item['price'] as num?)?.toDouble() ?? 0.0;
                          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                          final rawImg = item['image'] as String? ?? '';
                          final imgUrl =
                              (rawImg.isNotEmpty && !rawImg.startsWith('http'))
                              ? 'https://alifworld.vercel.app$rawImg'
                              : rawImg;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48.r,
                                    height: 48.r,
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: imgUrl.isNotEmpty
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Icon(
                                                  Iconsax.image,
                                                  size: 22.r,
                                                  color: AppColor.textSecondary,
                                                ),
                                          )
                                        : Icon(
                                            Iconsax.image,
                                            size: 22.r,
                                            color: AppColor.textSecondary,
                                          ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String? ??
                                              item['name'] as String? ??
                                              'Product',
                                          style: GoogleFonts.lato(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'Qty: $qty • ৳${price.toStringAsFixed(2)}',
                                          style: GoogleFonts.lato(
                                            fontSize: 12.sp,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '৳${(price * qty).toStringAsFixed(2)}',
                                    style: GoogleFonts.lato(
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLast)
                                Divider(
                                  color: const Color(0xFFF1F5F9),
                                  height: 16.h,
                                ),
                            ],
                          );
                        }),
                      ),
                    );
                  }),
                  SizedBox(height: 14.h),

                  // 3. Promo Code Section
                  _buildSectionHeader('Promo Code'),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Obx(() {
                      final hasApplied =
                          controller.appliedPromoCode.value.isNotEmpty;

                      if (hasApplied) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.discount_rounded,
                                  color: const Color(0xFF16A34A),
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Coupon "${controller.appliedPromoCode.value}" Applied',
                                  style: GoogleFonts.lato(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColor.error,
                                size: 18.r,
                              ),
                              onPressed: () => controller.removePromoCode(),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.promoCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Coupon Code (e.g. ALIF50)',
                                hintStyle: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  color: AppColor.textHint,
                                  letterSpacing: 0,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 10.h,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          ElevatedButton(
                            onPressed: () => controller.applyPromoCode(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.lato(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(height: 14.h),

                  // 4. Payment Method Selection
                  _buildSectionHeader('Payment Method'),
                  SizedBox(height: 8.h),
                  Obx(
                    () => Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: RadioGroup<String>(
                        groupValue: controller.selectedPaymentMethod.value,
                        onChanged: (val) =>
                            controller.selectPaymentMethod(val ?? 'COD'),
                        child: Column(
                          children: [
                            // 1. Pay from Wallet Option
                            _buildPaymentMethodTile(
                              id: 'Wallet',
                              title: 'Pay from Wallet',
                              subtitle:
                                  'Use your Main, Shopping or Advanced wallet balance',
                              extraText: controller.combinedWalletBalance > 0
                                  ? 'Combined balance: ৳${controller.combinedWalletBalance.toStringAsFixed(2)}'
                                  : null,
                              iconWidget: Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF630F),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (controller.selectedPaymentMethod.value ==
                                'Wallet') ...[
                              SizedBox(height: 6.h),
                              _buildWalletSelectionSection(),
                            ],

                            // Remainder Method Tile when Wallet is active
                            if (controller.selectedPaymentMethod.value ==
                                    'Wallet' &&
                                controller.remainingPayable > 0) ...[
                              SizedBox(height: 12.h),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Remaining ৳${controller.remainingPayable.toStringAsFixed(2)} — pay with',
                                  style: GoogleFonts.lato(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18.r,
                                      height: 18.r,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0284C7),
                                          width: 5,
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Icon(
                                      Iconsax.money_send,
                                      size: 20.r,
                                      color: AppColor.textPrimary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Cash on Delivery',
                                      style: GoogleFonts.lato(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Divider(color: Color(0xFFF1F5F9), height: 16),

                            // 2. Standalone Cash on Delivery Option
                            _buildPaymentMethodTile(
                              id: 'COD',
                              title: 'Cash on Delivery (COD)',
                              subtitle: 'Pay cash upon receiving delivery',
                              iconWidget: Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Icon(
                                    Iconsax.money_send,
                                    size: 20.r,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // 5. Payment Breakdown Summary Card
                  Obx(
                    () => Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Details',
                            style: GoogleFonts.lato(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildDetailRow(
                            'Items Subtotal',
                            '৳${controller.subtotal.value.toStringAsFixed(2)}',
                          ),
                          SizedBox(height: 8.h),
                          _buildDetailRow(
                            'Delivery Charge',
                            controller.deliveryFee.value == 0
                                ? 'FREE'
                                : '৳${controller.deliveryFee.value.toStringAsFixed(2)}',
                            isGreen: controller.deliveryFee.value == 0,
                          ),
                          if (controller.tax.value > 0) ...[
                            SizedBox(height: 8.h),
                            _buildDetailRow(
                              'Estimated Tax',
                              '৳${controller.tax.value.toStringAsFixed(2)}',
                            ),
                          ],
                          if (controller.discount.value > 0) ...[
                            SizedBox(height: 8.h),
                            _buildDetailRow(
                              'Promo Discount',
                              '- ৳${controller.discount.value.toStringAsFixed(2)}',
                              isGreen: true,
                            ),
                          ],
                          if (controller.selectedPaymentMethod.value ==
                                  'Wallet' &&
                              controller.walletDeductionAmount > 0) ...[
                            SizedBox(height: 8.h),
                            _buildDetailRow(
                              'Wallet',
                              '- ৳${controller.walletDeductionAmount.toStringAsFixed(2)}',
                              isGreen: true,
                            ),
                          ],
                          SizedBox(height: 10.h),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          SizedBox(height: 10.h),
                          _buildDetailRow(
                            controller.selectedPaymentMethod.value == 'Wallet'
                                ? 'Payable'
                                : 'Total Amount',
                            '৳${controller.finalPayable.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          if (controller.discount.value > 0) ...[
                            SizedBox(height: 12.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'You will save ৳${controller.discount.value.toStringAsFixed(2)} on this order',
                                  style: GoogleFonts.lato(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
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
                        'Total Payable',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Obx(
                        () => Text(
                          '৳${controller.finalPayable.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48.h,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isProcessingPayment.value
                            ? null
                            : () => controller.placeOrder(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller.selectedPaymentMethod.value == 'Wallet'
                                  ? const Color(0xFFFF630F)
                                  : AppColor.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: controller.isProcessingPayment.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                controller.selectedPaymentMethod.value ==
                                        'Wallet'
                                    ? 'Place order'
                                    : 'Place Order (COD)',
                                style: GoogleFonts.lato(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: GoogleFonts.lato(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.primaryDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required Widget iconWidget,
    String? extraText,
  }) {
    final isSelected = controller.selectedPaymentMethod.value == id;

    return InkWell(
      onTap: () => controller.selectPaymentMethod(id),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Radio<String>(value: id, activeColor: const Color(0xFF0284C7)),
            iconWidget,
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14.5.sp,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  if (extraText != null && extraText.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      extraText,
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF630F),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletKindRow({
    required String kind,
    required String title,
    required double balance,
    required double willUseAmount,
  }) {
    return Obx(() {
      final isChecked = controller.isWalletKindSelected(kind);

      return InkWell(
        onTap: () => controller.toggleWalletKind(kind),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color:
                  isChecked ? const Color(0xFFFF630F) : const Color(0xFFE5E7EB),
              width: isChecked ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFFFF630F) : Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: isChecked
                        ? const Color(0xFFFF630F)
                        : const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight:
                            isChecked ? FontWeight.bold : FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Available: ৳${balance.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isChecked) ...[
                Text(
                  'Will use: ৳${willUseAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF630F),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWalletSelectionSection() {
    return Obx(() {
      final maxPercent = controller.walletMaxPercent.value;
      final remainingAmount = controller.remainingPayable;
      final mainBal = controller.mainWalletBalance;
      final shoppingBal = controller.shoppingWalletBalance;
      final advanceBal = controller.advanceWalletBalance;

      return Container(
        margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFFDE68A),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Notice banner
            Text(
              'You can pay up to $maxPercent% of the order total from your wallets. The rest is payable on delivery.',
              style: GoogleFonts.lato(
                fontSize: 12.5.sp,
                color: const Color(0xFF78350F),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            SizedBox(height: 12.h),

            // 2. Main Wallet Row
            _buildWalletKindRow(
              kind: 'customer_main',
              title: 'Main Wallet',
              balance: mainBal,
              willUseAmount: controller.mainWalletWillUse,
            ),
            SizedBox(height: 8.h),

            // 3. Shopping Wallet Row
            _buildWalletKindRow(
              kind: 'customer_shopping',
              title: 'Shopping Wallet',
              balance: shoppingBal,
              willUseAmount: controller.shoppingWalletWillUse,
            ),
            SizedBox(height: 8.h),

            // 4. Advanced Shopping Row
            _buildWalletKindRow(
              kind: 'customer_advanced_shopping',
              title: 'Advanced Shopping',
              balance: advanceBal,
              willUseAmount: controller.advanceWalletWillUse,
            ),

            if (remainingAmount > 0) ...[
              SizedBox(height: 12.h),
              Text(
                'Remaining ৳${remainingAmount.toStringAsFixed(2)} will be paid as Cash on Delivery.',
                style: GoogleFonts.lato(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDetailRow(
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

  void _showAddressSelectionBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: EdgeInsets.only(
          top: 16.h,
          left: 20.w,
          right: 20.w,
          bottom: 24.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Delivery Address',
                  style: GoogleFonts.lato(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColor.textSecondary,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.addresses.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final addr = controller.addresses[index];
                    final isSelected =
                        controller.selectedAddressIndex.value == index;
                    final name = addr['name'] as String? ?? '';
                    final phone = addr['phone'] as String? ?? '';
                    final type = addr['type'] as String? ?? 'Home';
                    final addressText = addr['address'] as String? ?? '';

                    return InkWell(
                      onTap: () {
                        controller.selectAddress(index);
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColor.primary
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 2.h),
                              width: 20.r,
                              height: 20.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColor.primary
                                      : const Color(0xFF94A3B8),
                                  width: isSelected ? 5.5 : 1.5,
                                ),
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 7.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFFEDD5)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          type,
                                          style: GoogleFonts.lato(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? AppColor.primaryDark
                                                : AppColor.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (phone.isNotEmpty) ...[
                                        SizedBox(width: 8.w),
                                        Text(
                                          phone,
                                          style: GoogleFonts.lato(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (name.isNotEmpty &&
                                      name != 'Customer') ...[
                                    SizedBox(height: 3.h),
                                    Text(
                                      name,
                                      style: GoogleFonts.lato(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 4.h),
                                  Text(
                                    addressText,
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp,
                                      color: AppColor.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.openAddAddressModal(context);
                },
                icon: Icon(
                  Iconsax.add,
                  size: 18.r,
                  color: AppColor.primaryDark,
                ),
                label: Text(
                  'Add New Address',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColor.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
