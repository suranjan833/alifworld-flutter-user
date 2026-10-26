import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/country_picker_dialog.dart';
import '../controllers/signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Get.back(),
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

                // Header Title
                Text(
                  'Create Account',
                  style: GoogleFonts.lato(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Sign up now to get started with your account.',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                ),

                SizedBox(height: 20.h),

                // 1. Full Name
                _buildFieldLabel('Full Name'),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: controller.nameController,
                  validator: controller.validateName,
                  textCapitalization: TextCapitalization.words,
                  style: _inputTextStyle,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Iconsax.user,
                  ),
                ),

                SizedBox(height: 12.h),

                // 2. Email Address with Verification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Email Address'),
                    Obx(() {
                      if (controller.isEmailVerified.value) {
                        return _buildVerifiedChip('Verified');
                      }
                      if (!controller.hasEmailInput.value) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: controller.isSendingEmailOtp.value
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
                                  color: AppColor.primaryLight,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColor.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.w,
                                  ),
                                ),
                                child: Text(
                                  controller.isEmailOtpSent.value
                                      ? 'Resend OTP'
                                      : 'Verify Email',
                                  style: GoogleFonts.lato(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryDark,
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
                    return _buildOtpVerificationBox(
                      title: 'Enter Email OTP',
                      controller: controller.emailOtpController,
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
                        return _buildVerifiedChip('Verified');
                      }
                      if (!controller.hasPhoneInput.value) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: controller.isSendingPhoneOtp.value
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
                                  color: AppColor.primaryLight,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColor.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.w,
                                  ),
                                ),
                                child: Text(
                                  controller.isPhoneOtpSent.value
                                      ? 'Resend OTP'
                                      : 'Verify Phone',
                                  style: GoogleFonts.lato(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryDark,
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
                    return _buildOtpVerificationBox(
                      title: 'Enter Phone OTP',
                      controller: controller.phoneOtpController,
                      isVerifying: controller.isVerifyingPhoneOtp.value,
                      onVerify: controller.verifyPhoneOtp,
                    );
                  }
                  return const SizedBox.shrink();
                }),

                SizedBox(height: 12.h),

                // 4. Password
                _buildFieldLabel('Password'),
                SizedBox(height: 4.h),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    validator: controller.validatePassword,
                    obscureText: !controller.isPasswordVisible.value,
                    style: _inputTextStyle,
                    decoration: _buildInputDecoration(
                      hintText: 'Enter password (min 6 chars)',
                      prefixIcon: Iconsax.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Iconsax.eye
                              : Iconsax.eye_slash,
                          color: AppColor.textSecondary,
                          size: 18.r,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // 5. Confirm Password
                _buildFieldLabel('Confirm Password'),
                SizedBox(height: 4.h),
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPasswordController,
                    validator: controller.validateConfirmPassword,
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    style: _inputTextStyle,
                    decoration: _buildInputDecoration(
                      hintText: 'Re-enter your password',
                      prefixIcon: Iconsax.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Iconsax.eye
                              : Iconsax.eye_slash,
                          color: AppColor.textSecondary,
                          size: 18.r,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // 6. Referral Code (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Referral Code'),
                    Text(
                      '(Optional)',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.referralCodeController,
                  builder: (context, value, _) {
                    return TextFormField(
                      controller: controller.referralCodeController,
                      textCapitalization: TextCapitalization.characters,
                      style: _inputTextStyle,
                      decoration: _buildInputDecoration(
                        hintText: 'Enter referral code (if any)',
                        prefixIcon: Iconsax.gift,
                      ).copyWith(
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18.r,
                                  color: AppColor.textSecondary,
                                ),
                                onPressed: () =>
                                    controller.referralCodeController.clear(),
                              )
                            : null,
                      ),
                    );
                  },
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
                      'Already have an account? ',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.goToLogin,
                      child: Text(
                        'Log In',
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
    );
  }

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

  TextStyle get _inputTextStyle => GoogleFonts.lato(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColor.textPrimary,
  );

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
        borderSide: const BorderSide(color: AppColor.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5),
      ),
    );
  }

  Widget _buildVerifiedChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 13.r,
            color: const Color(0xFF2E7D32),
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationBox({
    required String title,
    required TextEditingController controller,
    required bool isVerifying,
    required VoidCallback onVerify,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColor.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '6-digit OTP',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 12.sp,
                        letterSpacing: 0,
                        color: AppColor.textHint,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      filled: true,
                      fillColor: AppColor.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                          color: AppColor.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                height: 42.h,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: isVerifying
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.white,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
