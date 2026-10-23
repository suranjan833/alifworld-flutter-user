import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../controllers/order_success_controller.dart';

class OrderSuccessView extends GetView<OrderSuccessController> {
  const OrderSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 30.h),
              // Success Animation Circle
              Container(
                width: 90.r,
                height: 90.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                    size: 64.r,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Thank you for your order. Your payment was verified.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),

              // Order Confirmation Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Obx(
                      () => _buildInfoRow('Order ID', controller.orderId.value),
                    ),
                    SizedBox(height: 10.h),
                    Obx(() {
                      if (!controller.showPaymentId) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoRow(
                            'Payment ID',
                            controller.paymentId.value,
                          ),
                          SizedBox(height: 10.h),
                        ],
                      );
                    }),
                    Obx(
                      () => _buildInfoRow(
                        'Payment Mode',
                        controller.paymentMethod.value,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Obx(
                      () => _buildInfoRow(
                        'Payment Status',
                        controller.formattedPaymentStatus,
                        isStatus: true,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Obx(
                      () => _buildInfoRow(
                        'Total Amount',
                        '৳${controller.totalAmount.value.toStringAsFixed(2)}',
                        isHighlight: true,
                      ),
                    ),
                    // Estimated Delivery commented out for now
                    /*
                    SizedBox(height: 12.h),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 18.r,
                          color: const Color(0xFF16A34A),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Delivery',
                                style: GoogleFonts.lato(
                                  fontSize: 12.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Expected by 26 Sep 2026',
                                style: GoogleFonts.lato(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    */
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => controller.trackOrder(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Track Order',
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () => controller.continueShopping(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: const BorderSide(color: AppColor.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isStatus = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(width: 12.w),
        if (isStatus)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: value.toLowerCase().contains('partially')
                  ? const Color(0xFFFFFBEB)
                  : (value.toLowerCase().contains('paid')
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: value.toLowerCase().contains('partially')
                    ? const Color(0xFFFDE68A)
                    : (value.toLowerCase().contains('paid')
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.lato(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: value.toLowerCase().contains('partially')
                    ? const Color(0xFFB45309)
                    : (value.toLowerCase().contains('paid')
                        ? const Color(0xFF15803D)
                        : AppColor.textPrimary),
              ),
            ),
          )
        else
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.lato(
                fontSize: isHighlight ? 15.sp : 13.5.sp,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.bold,
                color:
                    isHighlight ? AppColor.primaryDark : AppColor.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
