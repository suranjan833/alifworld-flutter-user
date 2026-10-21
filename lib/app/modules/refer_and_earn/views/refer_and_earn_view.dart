import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/refer_and_earn_controller.dart';

class ReferAndEarnView extends GetView<ReferAndEarnController> {
  const ReferAndEarnView({super.key});

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
          'Refer and Earn',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            // Top Illustration Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70.r,
                    height: 70.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7E6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.gift,
                        color: AppColor.primaryDark,
                        size: 36.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Refer Friends & Earn Rewards!',
                    style: GoogleFonts.lato(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Share your unique referral code with friends. You both get ₹100 when they place their first order!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      color: AppColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Referral Code Box
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(
                          () => Text(
                            controller.referralCode.value,
                            style: GoogleFonts.lato(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColor.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => controller.copyCode(),
                          icon: Icon(Iconsax.copy, size: 16.r),
                          label: Text(
                            'Copy',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ],
                    ),
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
