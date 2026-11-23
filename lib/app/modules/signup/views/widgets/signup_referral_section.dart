import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/signup_controller.dart';

class SignupReferralSection extends GetView<SignupController> {
  final InputDecoration Function({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) inputDecorationBuilder;

  const SignupReferralSection({
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
        Obx(() {
          final isLookingUp = controller.isLookingUpReferral.value;
          final err = controller.referralError.value;
          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.referralCodeController,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: controller.referralCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: _inputTextStyle,
                    maxLength: 8,
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) =>
                        null,
                    decoration: inputDecorationBuilder(
                      hintText: 'Enter 8-digit referral code',
                      prefixIcon: Iconsax.gift,
                    ).copyWith(
                      enabledBorder: err != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: AppColor.error,
                                width: 1.5,
                              ),
                            )
                          : null,
                      focusedBorder: err != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: AppColor.error,
                                width: 1.5,
                              ),
                            )
                          : null,
                      suffixIcon: isLookingUp
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primary,
                                ),
                              ),
                            )
                          : (value.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18.r,
                                    color: AppColor.textSecondary,
                                  ),
                                  onPressed: () {
                                    controller.referralCodeController.clear();
                                    controller.referralLookup.value = null;
                                    controller.referralError.value = null;
                                  },
                                )
                              : null),
                    ),
                  ),
                  if (err != null) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 4.h, left: 4.w),
                      child: Text(
                        err,
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.error,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        }),
        Obx(() {
          final ref = controller.referralLookup.value;
          if (ref == null) return const SizedBox.shrink();
          return Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF86EFAC),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: const Color(0xFF16A34A),
                  backgroundImage: ref.avatarUrl != null &&
                          ref.avatarUrl!.isNotEmpty
                      ? NetworkImage(ref.avatarUrl!)
                      : null,
                  child: ref.avatarUrl == null || ref.avatarUrl!.isEmpty
                      ? Text(
                          ref.name.isNotEmpty ? ref.name[0].toUpperCase() : 'R',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Referred by',
                            style: GoogleFonts.lato(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13.r,
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        ref.name,
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ref.maskedPhone.isNotEmpty)
                        Text(
                          ref.maskedPhone,
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
