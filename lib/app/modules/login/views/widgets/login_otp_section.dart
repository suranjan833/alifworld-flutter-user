import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/widgets/country_picker_dialog.dart';
import '../../controllers/login_controller.dart';

class LoginOtpSection extends GetView<LoginController> {
  const LoginOtpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'phone_number'.tr,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (controller.isOtpSent.value)
                InkWell(
                  onTap: controller.editPhoneNumber,
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.edit_2,
                          size: 13.r,
                          color: AppColor.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'edit_number'.tr,
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: TextFormField(
                  controller: controller.phoneController,
                  focusNode: controller.phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
          ),
          if (controller.isOtpSent.value) ...[
            SizedBox(height: 16.h),
            Text(
              'otp_code'.tr,
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                hintText: 'enter_otp_hint'.tr,
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
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'enter_6_digit_otp'.tr,
                  style: GoogleFonts.lato(
                    fontSize: 11.5.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : controller.requestOtp,
                  child: Text(
                    'resend_otp'.tr,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
