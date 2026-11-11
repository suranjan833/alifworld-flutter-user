import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../../leaderboards/views/widgets/my_progress_card.dart';
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
                    onTap: () => controller.isLoggedIn.value
                        ? controller.openMyProfile()
                        : Get.toNamed(Routes.LOGIN),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      child: Obx(() {
                        final isLoggedIn = controller.isLoggedIn.value;
                        final name = controller.userName.value.trim();
                        final phone = controller.userPhone.value.trim();
                        final email = controller.userEmail.value.trim();
                        final member = controller.memberSince.value.trim();

                        final displayName = isLoggedIn
                            ? (name.isNotEmpty ? name : 'My Account')
                            : 'Welcome Guest';

                        String subtitle = 'Sign in to access orders, wallet & rewards';
                        if (isLoggedIn) {
                          if (phone.isNotEmpty) {
                            subtitle = phone.startsWith('+') ? phone : '+$phone';
                          } else if (email.isNotEmpty) {
                            subtitle = email;
                          } else if (member.isNotEmpty) {
                            subtitle = member;
                          } else {
                            subtitle = 'View & edit profile';
                          }
                        }

                        return Row(
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
                                  isLoggedIn ? Icons.person : Icons.person_outline,
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
                                  Text(
                                    displayName,
                                    style: GoogleFonts.lato(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColor.textSecondary,
                                    ),
                                  ),
                                  if (isLoggedIn && member.isNotEmpty && (phone.isNotEmpty || email.isNotEmpty)) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      member,
                                      style: GoogleFonts.lato(
                                        fontSize: 11.5.sp,
                                        color: AppColor.textHint,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isLoggedIn)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 24.r,
                                color: const Color(0xFFA0A7B5),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // 1.1 Total Balance Banner (ONLY when logged in)
              _buildTotalBalanceBanner(context),

              // 1.2 Quick Feature Cards (Leaderboard, Lottery, Wallets - ONLY when logged in)
              Obx(() => controller.isLoggedIn.value
                  ? _buildAccountQuickCards(context)
                  : const SizedBox.shrink()),

              // 1.3 Achievements Section (Club progress only - ONLY when logged in)
              _buildAchievementsSection(context),

              // 2. Sections (Manage, Settings, Others)
              Obx(
                () => Column(
                  children: controller.sections
                      .map((section) => _buildSectionGroup(context, section))
                      .toList(),
                ),
              ),

              // 3. Logout / Log In Button Card
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 20.h),
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
                                : AppColor.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLoggedIn ? Iconsax.logout : Iconsax.login,
                              size: 20.r,
                              color: isLoggedIn ? AppColor.error : AppColor.primary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              isLoggedIn
                                  ? (isBn ? 'লগআউট' : 'Logout')
                                  : (isBn ? 'লগ ইন / সাইন আপ' : 'Log In / Register'),
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: isLoggedIn ? AppColor.error : AppColor.primary,
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

  Widget _buildTotalBalanceBanner(BuildContext context) {
    return Obx(() {
      if (!controller.isLoggedIn.value) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        child: InkWell(
          onTap: () => Get.toNamed(Routes.WALLET),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Iconsax.wallet_2, color: AppColor.primary, size: 24.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Wallet Balance',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '৳${controller.totalBalance.value.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '10 Wallets',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13.r,
                      color: AppColor.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return Obx(() {
      if (!controller.isLoggedIn.value) return const SizedBox.shrink();

      final myProg = controller.myProgress.value;
      if (myProg == null || myProg.periods.isEmpty) {
        return const SizedBox.shrink();
      }

      final activePeriod = controller.selectedClubPeriod.value;
      final periodProg = myProg.getPeriod(activePeriod) ?? myProg.periods.first;

      const periods = [
        {'key': 'daily', 'label': 'Daily'},
        {'key': 'weekly', 'label': 'Weekly'},
        {'key': 'monthly', 'label': 'Monthly'},
        {'key': 'yearly', 'label': 'Yearly'},
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Club Achievements',
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.LEADERBOARDS),
                  child: Text(
                    'Leaderboards →',
                    style: GoogleFonts.lato(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Period Switcher Chips (Daily, Weekly, Monthly, Yearly)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: periods.map((p) {
                  final isSelected = activePeriod == p['key'];
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(p['label']!),
                      selected: isSelected,
                      onSelected: (_) => controller.changeClubPeriod(p['key']!),
                      selectedColor: AppColor.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSelected ? AppColor.primary : AppColor.border,
                      ),
                      labelStyle: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColor.white : AppColor.textSecondary,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          MyProgressCard(
            progress: periodProg,
            pendingPoints: myProg.pendingPoints,
            showStar: false, // Club only on account view per §1.2
          ),
        ],
      );
    });
  }

  Widget _buildAccountQuickCards(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _buildAccountActionCard(
              title: 'Leaderboard',
              subtitle: 'Top 100 & Pool',
              icon: Iconsax.cup,
              bgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              onTap: () => Get.toNamed(Routes.LEADERBOARDS),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildAccountActionCard(
              title: 'Lottery',
              subtitle: 'Good-Luck Draws',
              icon: Iconsax.ticket,
              bgColor: const Color(0xFFFCE7F3),
              iconColor: const Color(0xFFDB2777),
              onTap: () => Get.toNamed(Routes.LOTTERY),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildAccountActionCard(
              title: 'My Wallets',
              subtitle: '10 Balances',
              icon: Iconsax.wallet_2,
              bgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              onTap: () => controller.isLoggedIn.value
                  ? Get.toNamed(Routes.WALLET)
                  : Get.toNamed(Routes.LOGIN),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColor.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 10.5.sp,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
