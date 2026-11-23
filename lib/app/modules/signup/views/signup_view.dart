import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/country_picker_dialog.dart';
import '../../../routes/app_pages.dart';
import '../controllers/signup_controller.dart';
import 'widgets/signup_otp_box.dart';
import 'widgets/signup_password_section.dart';
import 'widgets/signup_referral_section.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  void _handleBack(BuildContext context) {
    final prev = Get.previousRoute;
    final isFromInternalScreen = prev.isNotEmpty &&
        prev != Routes.SPLASH &&
        prev != Routes.SIGNUP &&
        prev != Routes.REGISTER &&
        prev != '/register' &&
        prev != '/signup' &&
        prev != '/notfound' &&
        prev != '/';
    if (isFromInternalScreen && Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(Routes.MAIN_NAVIGATION);
    }
  }

  TextStyle get _inputTextStyle => GoogleFonts.lato(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      );

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.lato(
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textHint),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColor.textSecondary, size: 18.r)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColor.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5),
      ),
      errorStyle: GoogleFonts.lato(
        fontSize: 11.5.sp,
        color: AppColor.error,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.transparent,
          elevation: 0,
          toolbarHeight: 44.h,
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left_2,
              color: AppColor.textPrimary,
              size: 20.r,
            ),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),
                  Text(
                    'create_account'.tr,
                    style: GoogleFonts.lato(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'signup_subtitle'.tr,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 1. Full Name
                  _buildFieldLabel('full_name'.tr),
                  SizedBox(height: 4.h),
                  TextFormField(
                    controller: controller.nameController,
                    validator: controller.validateName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textCapitalization: TextCapitalization.words,
                    style: _inputTextStyle,
                    decoration: _buildInputDecoration(
                      hintText: 'enter_full_name'.tr,
                      prefixIcon: Iconsax.user,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // 2. Email Address
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Email Address'),
                      Obx(() {
                        if (controller.isEmailVerified.value) {
                          return const SignupVerifiedChip(text: 'Verified');
                        }
                        if (!controller.hasEmailInput.value) {
                          return const SizedBox.shrink();
                        }
                        final cooldown = controller.emailCooldown.value;
                        final isCooldownActive = cooldown > 0;
                        return GestureDetector(
                          onTap: (controller.isSendingEmailOtp.value ||
                                  isCooldownActive)
                              ? null
                              : controller.sendEmailOtp,
                          child: controller.isSendingEmailOtp.value
                              ? SizedBox(
                                  width: 14.r,
                                  height: 14.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.primary,
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCooldownActive
                                        ? const Color(0xFFF1F5F9)
                                        : AppColor.primaryLight,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: isCooldownActive
                                          ? const Color(0xFFCBD5E1)
                                          : AppColor.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    isCooldownActive
                                        ? 'Resend (${cooldown}s)'
                                        : (controller.isEmailOtpSent.value
                                            ? 'Resend OTP'
                                            : 'Verify Email'),
                                    style: GoogleFonts.lato(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isCooldownActive
                                          ? AppColor.textSecondary
                                          : AppColor.primaryDark,
                                    ),
                                  ),
                                ),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  TextFormField(
                    controller: controller.emailController,
                    validator: controller.validateEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.emailAddress,
                    style: _inputTextStyle,
                    decoration: _buildInputDecoration(
                      hintText: 'Enter your email address',
                      prefixIcon: Iconsax.sms,
                    ),
                  ),

                  // Inline Email OTP Box
                  Obx(() {
                    if (controller.isEmailOtpSent.value &&
                        !controller.isEmailVerified.value) {
                      return SignupOtpBox(
                        title: 'Enter Email OTP',
                        textController: controller.emailOtpController,
                        isVerifying: controller.isVerifyingEmailOtp.value,
                        onVerify: controller.verifyEmailOtp,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  SizedBox(height: 12.h),

                  // 3. Phone Number with Country Code & Verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Phone Number'),
                      Obx(() {
                        if (controller.isPhoneVerified.value) {
                          return const SignupVerifiedChip(text: 'Verified');
                        }
                        if (!controller.hasPhoneInput.value) {
                          return const SizedBox.shrink();
                        }
                        final cooldown = controller.phoneCooldown.value;
                        final isCooldownActive = cooldown > 0;
                        return GestureDetector(
                          onTap: (controller.isSendingPhoneOtp.value ||
                                  isCooldownActive)
                              ? null
                              : controller.sendPhoneOtp,
                          child: controller.isSendingPhoneOtp.value
                              ? SizedBox(
                                  width: 14.r,
                                  height: 14.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.primary,
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCooldownActive
                                        ? const Color(0xFFF1F5F9)
                                        : AppColor.primaryLight,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: isCooldownActive
                                          ? const Color(0xFFCBD5E1)
                                          : AppColor.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    isCooldownActive
                                        ? 'Resend (${cooldown}s)'
                                        : (controller.isPhoneOtpSent.value
                                            ? 'Resend OTP'
                                            : 'Verify Phone'),
                                    style: GoogleFonts.lato(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isCooldownActive
                                          ? AppColor.textSecondary
                                          : AppColor.primaryDark,
                                    ),
                                  ),
                                ),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Material(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          child: InkWell(
                            onTap: () => CountryPickerDialog.show(
                              context,
                              controller.selectedCountry.value,
                              controller.selectCountry,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              height: 48.h,
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: AppColor.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    controller.selectedCountry.value.flag,
                                    style: TextStyle(fontSize: 18.sp),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    controller.selectedCountry.value.dialCode,
                                    style: GoogleFonts.lato(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    Iconsax.arrow_down_1,
                                    color: AppColor.textSecondary,
                                    size: 16.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextFormField(
                          controller: controller.phoneController,
                          validator: controller.validatePhone,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          style: _inputTextStyle,
                          decoration: _buildInputDecoration(
                            hintText: '01XXXXXXXXX',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Inline Phone OTP Box
                  Obx(() {
                    if (controller.isPhoneOtpSent.value &&
                        !controller.isPhoneVerified.value) {
                      return SignupOtpBox(
                        title: 'Enter Phone OTP',
                        textController: controller.phoneOtpController,
                        isVerifying: controller.isVerifyingPhoneOtp.value,
                        onVerify: controller.verifyPhoneOtp,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  SizedBox(height: 12.h),

                  // 4 & 5. Password & Confirm Password
                  SignupPasswordSection(
                    inputDecorationBuilder: _buildInputDecoration,
                  ),
                  SizedBox(height: 12.h),

                  // 6. Referral Code (Optional)
                  SignupReferralSection(
                    inputDecorationBuilder: _buildInputDecoration,
                  ),
                  SizedBox(height: 24.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
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
                                'Create Account',
                                style: GoogleFonts.lato(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Footer: Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'already_have_account'.tr,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.goToLogin,
                        child: Text(
                          'sign_in'.tr,
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
