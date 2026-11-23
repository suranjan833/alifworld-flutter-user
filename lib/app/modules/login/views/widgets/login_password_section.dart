import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/login_controller.dart';

class LoginPasswordSection extends GetView<LoginController> {
  final TextInputFormatter phoneOrEmailFormatter;

  const LoginPasswordSection({
    super.key,
    required this.phoneOrEmailFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phone_number'.tr,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller.identifierController,
          keyboardType: TextInputType.text,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: [phoneOrEmailFormatter],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'please_enter_phone'.tr;
            }
            final trimmed = v.trim();
            if (!trimmed.contains('@')) {
              final digits = trimmed.replaceAll(RegExp(r'\D'), '');
              if (digits.length > 11) {
                return 'phone_max_length'.tr;
              }
              if (digits.length < 10) {
                return 'please_enter_valid_phone'.tr;
              }
            }
            return null;
          },
          style: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'enter_phone_hint'.tr,
            hintStyle: GoogleFonts.lato(
              fontSize: 14.sp,
              color: AppColor.textHint,
            ),
            prefixIcon: const Icon(Icons.phone_android_rounded),
            filled: true,
            fillColor: AppColor.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColor.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColor.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColor.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColor.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColor.error,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.lato(
              fontSize: 11.5.sp,
              color: AppColor.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'password'.tr,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        Obx(
          () => TextFormField(
            controller: controller.passwordController,
            obscureText: !controller.isPasswordVisible.value,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'please_enter_password'.tr;
              }
              return null;
            },
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'enter_password_hint'.tr,
              hintStyle: GoogleFonts.lato(
                fontSize: 14.sp,
                color: AppColor.textHint,
              ),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColor.textSecondary,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              filled: true,
              fillColor: AppColor.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColor.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColor.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColor.error,
                  width: 1.5,
                ),
              ),
              errorStyle: GoogleFonts.lato(
                fontSize: 11.5.sp,
                color: AppColor.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
