import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../controllers/login_controller.dart';
import 'widgets/login_header.dart';
import 'widgets/login_otp_section.dart';
import 'widgets/login_password_section.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: controller.formKey,
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginHeader(),
                  if (!controller.isOtpLogin.value)
                    LoginPasswordSection(
                      phoneOrEmailFormatter: _PhoneOrEmailInputFormatter(),
                    )
                  else
                    const LoginOtpSection(),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed:
                          controller.isLoading.value ||
                              (controller.isOtpLogin.value &&
                                  !controller.isOtpSent.value &&
                                  !controller.hasPhoneInput.value)
                          ? null
                          : controller.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: AppColor.primary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                color: AppColor.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Text(
                              !controller.isOtpLogin.value
                                  ? 'sign_in'.tr
                                  : (controller.isOtpSent.value
                                        ? 'verify_and_sign_in'.tr
                                        : 'verify_phone'.tr),
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Center(
                    child: TextButton.icon(
                      onPressed: controller.toggleLoginMode,
                      icon: Icon(
                        controller.isOtpLogin.value
                            ? Icons.lock_outline_rounded
                            : Icons.sms_outlined,
                        size: 18.r,
                        color: AppColor.primary,
                      ),
                      label: Text(
                        controller.isOtpLogin.value
                            ? 'login_with_password'.tr
                            : 'login_with_otp'.tr,
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "dont_have_account".tr,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.goToSignup,
                        child: Text(
                          'sign_up'.tr,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneOrEmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(text)) {
      return newValue;
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      return oldValue;
    }
    return newValue;
  }
}
