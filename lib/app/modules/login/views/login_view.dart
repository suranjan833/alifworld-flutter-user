import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/country_picker_dialog.dart';
import '../controllers/login_controller.dart';

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
                  SizedBox(height: 32.h),

                  // Brand Header Badge / Icon
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

                  SizedBox(height: 20.h),

                  // Header Titles
                  Text(
                    'Welcome Back!',
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
                        ? 'Enter your phone number to receive an OTP.'
                        : 'Sign in with your phone number and password.',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.normal,
                      color: AppColor.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Dynamic Fields Based on Login Mode
                  if (!controller.isOtpLogin.value) ...[
                    // --- PASSWORD LOGIN MODE ---
                    Text(
                      'Phone Number',
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
                      inputFormatters: [
                        _PhoneOrEmailInputFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        final trimmed = v.trim();
                        if (!trimmed.contains('@')) {
                          final digits = trimmed.replaceAll(RegExp(r'\D'), '');
                          if (digits.length > 11) {
                            return 'Phone number cannot exceed 11 digits';
                          }
                          if (digits.length < 10) {
                            return 'Please enter a valid 11-digit phone number';
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
                        hintText: 'Enter phone number (e.g. 01XXXXXXXXX)',
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
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      'Password',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      style: GoogleFonts.lato(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
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
                      ),
                    ),
                  ] else ...[
                    // --- OTP LOGIN MODE ---
                    Text(
                      'Phone Number',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country Code Picker Button
                        Material(
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
                                    Icons.arrow_drop_down_rounded,
                                    color: AppColor.textSecondary,
                                    size: 20.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Phone Number TextFormField
                        Expanded(
                          child: TextFormField(
                            controller: controller.phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            onChanged: (_) => controller.validatePhone(),
                            validator: controller.validatePhoneInput,
                            style: GoogleFonts.lato(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '01XXXXXXXXX',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 14.sp,
                                color: AppColor.textHint,
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
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (controller.isOtpSent.value) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'OTP Code',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: controller.otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColor.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter OTP code',
                          hintStyle: GoogleFonts.lato(
                            fontSize: 14.sp,
                            letterSpacing: 0,
                            color: AppColor.textHint,
                          ),
                          prefixIcon: const Icon(Icons.security_rounded),
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
                        ),
                      ),
                    ],
                  ],

                  SizedBox(height: 24.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value ||
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
                                  ? 'Sign In'
                                  : (controller.isOtpSent.value
                                      ? 'Verify & Sign In'
                                      : 'Verify Phone'),
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Toggle Login Method Button (Login with OTP vs Login with Password)
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
                            ? 'Login with Password instead'
                            : 'Login with OTP',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Footer: Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.goToSignup,
                        child: Text(
                          'Sign Up',
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
    // If it's an email (contains @ or latin letters), allow standard typing
    if (text.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(text)) {
      return newValue;
    }
    // If it's digits / phone number, strictly limit to 11 digits
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      return oldValue;
    }
    return newValue;
  }
}
