import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/services/app_translations.dart';
import '../../controllers/login_controller.dart';

class LoginHeader extends GetView<LoginController> {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColor.primaryLight,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Icon(
                    controller.isOtpLogin.value
                        ? Icons.phone_android_rounded
                        : Icons.lock_outline_rounded,
                    color: AppColor.primary,
                    size: 24.r,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => AppTranslations.openLanguageSelectionSheet(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.translate,
                        size: 16.r,
                        color: AppColor.primaryDark,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        AppTranslations.currentLanguageCode == 'bn'
                            ? 'বাংলা'
                            : 'English',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16.r,
                        color: AppColor.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'welcome_back'.tr,
            style: GoogleFonts.lato(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            controller.isOtpLogin.value
                ? 'login_otp_subtitle'.tr
                : 'login_password_subtitle'.tr,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.normal,
              color: AppColor.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 28.h),
        ],
      ),
    );
  }
}
