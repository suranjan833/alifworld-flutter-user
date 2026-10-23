import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/my_profile_controller.dart';

class MyProfileView extends GetView<MyProfileController> {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColor.textPrimary,
            size: 24.r,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(
        () => controller.isLoading.value && controller.nameController.text.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColor.primary,
                ),
              )
            : RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () => controller.fetchProfile(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Header
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 86.r,
                              height: 86.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: AppColor.white,
                                  size: 46.r,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Get.snackbar(
                                    'Profile Photo',
                                    'Photo upload will be enabled in an upcoming release.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColor.textPrimary,
                                    colorText: AppColor.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(7.r),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColor.white,
                                      width: 2.5.w,
                                    ),
                                  ),
                                  child: Icon(
                                    Iconsax.camera,
                                    size: 16.r,
                                    color: AppColor.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Center(
                        child: Obx(
                          () => Text(
                            controller.userName.value,
                            style: GoogleFonts.lato(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Form Fields
                      _buildFieldLabel('Full Name'),
                      SizedBox(height: 6.h),
                      _buildTextField(
                        controller: controller.nameController,
                        hint: 'Enter your full name',
                        prefixIcon: Iconsax.user,
                      ),
                      SizedBox(height: 16.h),

                      _buildFieldLabel('Email Address'),
                      SizedBox(height: 6.h),
                      _buildTextField(
                        controller: controller.emailController,
                        hint: 'Enter your email address',
                        prefixIcon: Iconsax.sms,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),

                      _buildFieldLabel('Phone Number'),
                      SizedBox(height: 6.h),
                      _buildTextField(
                        controller: controller.phoneController,
                        hint: '01XXXXXXXXX',
                        prefixIcon: Iconsax.call,
                        suffixIcon: Iconsax.lock,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        readOnly: true,
                        helperText:
                            'Verified phone number is linked to your login account.',
                      ),
                      SizedBox(height: 16.h),

                      _buildFieldLabel('Date of Birth'),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: () => controller.selectDateOfBirth(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: controller.dobController,
                            hint: 'Select Date of Birth',
                            prefixIcon: Iconsax.calendar_1,
                            suffixIcon: Iconsax.arrow_down_1,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Gender Selection
                      _buildFieldLabel('Gender'),
                      SizedBox(height: 8.h),
                      Obx(
                        () => Row(
                          children: [
                            _buildGenderChip('Male'),
                            SizedBox(width: 12.w),
                            _buildGenderChip('Female'),
                            SizedBox(width: 12.w),
                            _buildGenderChip('Other'),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Save Button
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: (controller.isSaving.value ||
                                    controller.isLoading.value)
                                ? null
                                : () => controller.saveProfile(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: controller.isSaving.value
                                ? SizedBox(
                                    width: 24.r,
                                    height: 24.r,
                                    child: const CircularProgressIndicator(
                                      color: AppColor.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.lato(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.white,
                                    ),
                                  ),
                          ),
                        ),
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
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.lato(
            fontSize: 15.sp,
            color: readOnly ? const Color(0xFF64748B) : AppColor.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.lato(fontSize: 14.sp, color: AppColor.textHint),
            prefixIcon:
                Icon(prefixIcon, size: 20.r, color: AppColor.textSecondary),
            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    size: 18.r,
                    color: readOnly
                        ? const Color(0xFF94A3B8)
                        : AppColor.textSecondary,
                  )
                : null,
            filled: true,
            fillColor:
                readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8F9FA),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: readOnly ? const Color(0xFFCBD5E1) : AppColor.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (helperText != null && helperText.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              helperText,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderChip(String gender) {
    final isSelected = controller.selectedGender.value == gender;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setGender(gender),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFF7E6)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColor.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              gender,
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColor.primaryDark
                    : AppColor.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
