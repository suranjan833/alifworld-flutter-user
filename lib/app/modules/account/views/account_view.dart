import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/account_controller.dart';
import 'widgets/account_balance_banner.dart';
import 'widgets/account_quick_cards.dart';
import 'widgets/account_user_card.dart';
import 'widgets/achievements_timeline_card.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16.w,
        title: Obx(
          () => Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: const Color(0xFF0F172A),
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                controller.currentLangCode.value == 'bn'
                    ? 'আমার অ্যাকাউন্ট'
                    : 'My Account',
                style: GoogleFonts.lato(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const SkeletonProfile()
            : Container(
                color: const Color(0xFFF8FAFC),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. User Profile Card Header
                      const AccountUserCard(),

                      // 1.1 Total Balance Banner (ONLY when logged in)
                      const AccountBalanceBanner(),

                      // 1.2 Quick Feature Cards (Leaderboard, Lottery, Wallets - ONLY when logged in)
                      Obx(
                        () => controller.isLoggedIn.value
                            ? const AccountQuickCards()
                            : const SizedBox.shrink(),
                      ),

                      // 1.3 Achievements Section (Club progress timeline - ONLY when logged in)
                      Obx(
                        () => controller.isLoggedIn.value
                            ? const AchievementsTimelineCard()
                            : const SizedBox.shrink(),
                      ),

                      // 2. Sections (Manage, Settings, Others)
                      Obx(
                        () => Column(
                          children: controller.sections
                              .map(
                                (section) =>
                                    _buildSectionGroup(context, section),
                              )
                              .toList(),
                        ),
                      ),

                      // 3. Logout / Log In Button Card
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          top: 20.h,
                        ),
                        child: Obx(() {
                          final isLoggedIn = controller.isLoggedIn.value;
                          final isBn = controller.currentLangCode.value == 'bn';

                          return Material(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(16.r),
                            child: InkWell(
                              onTap: () => isLoggedIn
                                  ? controller.logout()
                                  : Get.toNamed(Routes.LOGIN),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isLoggedIn
                                        ? AppColor.error.withValues(alpha: 0.15)
                                        : AppColor.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isLoggedIn
                                          ? Iconsax.logout
                                          : Iconsax.login,
                                      size: 20.r,
                                      color: isLoggedIn
                                          ? AppColor.error
                                          : AppColor.primary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      isLoggedIn
                                          ? (isBn ? 'লগআউট' : 'Logout')
                                          : (isBn
                                              ? 'লগ ইন / সাইন আপ'
                                              : 'Log In / Register'),
                                      style: GoogleFonts.lato(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isLoggedIn
                                            ? AppColor.error
                                            : AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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
