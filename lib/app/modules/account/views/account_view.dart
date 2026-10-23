import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/account_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20.w,
        title: Obx(
          () => Text(
            controller.currentLangCode.value == 'bn'
                ? 'আমার অ্যাকাউন্ট'
                : 'My account',
            style: GoogleFonts.lato(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const SkeletonProfile()
            : Container(
                color: const Color(0xFFF4F5F7),
                child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Card Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Material(
                  color: AppColor.transparent,
                  child: InkWell(
                    onTap: () => controller.openMyProfile(),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54.r,
                            height: 54.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                color: AppColor.white,
                                size: 30.r,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(
                                  () => Text(
                                    controller.userName.value,
                                    style: GoogleFonts.lato(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Obx(
                                  () {
                                    final phone = controller.userPhone.value;
                                    final email = controller.userEmail.value;
                                    final subtitle = phone.isNotEmpty &&
                                            phone != '+91 98765 43210'
                                        ? (phone.startsWith('+') ? phone : '+$phone')
                                        : (email.isNotEmpty &&
                                                email != 'user@example.com'
                                            ? email
                                            : controller.memberSince.value);
                                    return Text(
                                      subtitle,
                                      style: GoogleFonts.lato(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w400,
                                        color: AppColor.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 24.r,
                            color: const Color(0xFFA0A7B5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Sections (Manage, Settings, Others)
              Obx(
                () => Column(
                  children: controller.sections
                      .map((section) => _buildSectionGroup(context, section))
                      .toList(),
                ),
              ),

              // 3. Logout Button Card
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 20.h),
                child: Material(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    onTap: () => controller.logout(),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColor.error.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.logout,
                            size: 20.r,
                            color: AppColor.error,
                          ),
                          SizedBox(width: 8.w),
                          Obx(
                            () => Text(
                              controller.currentLangCode.value == 'bn'
                                  ? 'লগআউট'
                                  : 'Logout',
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  Widget _buildSectionGroup(BuildContext context, AccountSectionData section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title Header
        Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 16.h,
            bottom: 10.h,
          ),
          child: Text(
            section.title,
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
            ),
          ),
        ),

        // Section Items Card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColor.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(section.items.length, (index) {
                final item = section.items[index];
                final isLast = index == section.items.length - 1;

                return Column(
                  children: [
                    Material(
                      color: AppColor.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        borderRadius: BorderRadius.vertical(
                          top: index == 0 ? Radius.circular(16.r) : Radius.zero,
                          bottom: isLast ? Radius.circular(16.r) : Radius.zero,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 22.r,
                                color: AppColor.textPrimary,
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: GoogleFonts.lato(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      SizedBox(height: 3.h),
                                      Text(
                                        item.subtitle!,
                                        style: GoogleFonts.lato(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20.r,
                                color: const Color(0xFFA0A7B5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color: const Color(0xFFF2F4F7),
                        indent: 16.w,
                        endIndent: 16.w,
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
