import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/account_controller.dart';

class AccountBalanceBanner extends GetView<AccountController> {
  const AccountBalanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isLoggedIn.value) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: InkWell(
          onTap: () => Get.toNamed(Routes.WALLET),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColor.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Icon(
                    Iconsax.wallet_2,
                    color: AppColor.primary,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Wallet Balance',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '৳${controller.totalBalance.value.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '10 Wallets',
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.r,
                        color: const Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
