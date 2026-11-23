import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/signup_controller.dart';

class SignupPasswordSection extends GetView<SignupController> {
  final InputDecoration Function({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) inputDecorationBuilder;

  const SignupPasswordSection({
    super.key,
    required this.inputDecorationBuilder,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Password'),
        SizedBox(height: 4.h),
        Obx(
          () => TextFormField(
            controller: controller.passwordController,
            validator: controller.validatePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            obscureText: !controller.isPasswordVisible.value,
            style: _inputTextStyle,
            decoration: inputDecorationBuilder(
              hintText: 'Enter password (min 8 chars)',
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
        _buildFieldLabel('Confirm Password'),
        SizedBox(height: 4.h),
        Obx(
          () => TextFormField(
            controller: controller.confirmPasswordController,
            validator: controller.validateConfirmPassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            obscureText: !controller.isConfirmPasswordVisible.value,
            style: _inputTextStyle,
            decoration: inputDecorationBuilder(
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
      ],
    );
  }
}
