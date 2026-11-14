import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
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
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColor.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Icon(Iconsax.wallet_2, color: AppColor.primary, size: 22.r),
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
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '৳${controller.totalBalance.value.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '10 Wallets',
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.r,
                        color: const Color(0xFFEA580C),
                      ),
                    ],
                  ),
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
      final isLoggedIn = controller.isLoggedIn.value;
      final myProg = controller.myProgress.value;
      final activePeriod = controller.selectedClubPeriod.value;
      final periodProg = myProg?.getPeriod(activePeriod) ??
          (myProg?.periods.isNotEmpty == true ? myProg!.periods.first : null);

      final club = periodProg?.club;
      final currentTier = club?.currentTier ?? 'NO TIER';
      final currentTierPct = club?.currentTierPct ?? 0;
      final nextTier = club?.nextTier ?? 'BRONZE';
      final points = periodProg?.points ?? 0;
      final pointsToNext = club?.pointsToNext ?? 3000;
      final progressVal = ((club?.progressPct ?? 0) / 100.0).clamp(0.0, 1.0);
      final pendingPoints = myProg?.pendingPoints ?? 0;

      final periods = [
        {'key': 'daily', 'label': 'Daily', 'icon': Iconsax.calendar_1},
        {'key': 'weekly', 'label': 'Weekly', 'icon': Iconsax.calendar},
        {'key': 'monthly', 'label': 'Monthly', 'icon': Iconsax.calendar_edit},
        {'key': 'yearly', 'label': 'Yearly', 'icon': Iconsax.chart_2},
      ];

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Medal Icon + Title on left, Leaderboards pill on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 20.r,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Club Achievements',
                      style: GoogleFonts.lato(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (isLoggedIn) {
                      Get.toNamed(Routes.LEADERBOARDS);
                    } else {
                      controller.requireLogin(() => Get.toNamed(Routes.LEADERBOARDS));
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.cup,
                          size: 13.r,
                          color: const Color(0xFFEA580C),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Leaderboards →',
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // 2. Period Filter Pills (Daily, Weekly, Monthly, Yearly)
            Row(
              children: periods.map((p) {
                final isSelected = activePeriod == p['key'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: GestureDetector(
                      onTap: () => controller.changeClubPeriod(p['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF7A18), Color(0xFFFF5200)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20.r),
                          border: isSelected
                              ? null
                              : Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF5200).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? Icons.check_rounded : (p['icon'] as IconData),
                              size: 13.r,
                              color: isSelected ? AppColor.white : const Color(0xFF64748B),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              p['label'] as String,
                              style: GoogleFonts.lato(
                                fontSize: 11.sp,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColor.white : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 12.h),

            // 3. Inner Dark Sleek Progress Card with Violet-Aurora Ambient Gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color(0xFF0F1123),
                      Color(0xFF151833),
                      Color(0xFF1D1B44),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F1123).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Top-right purple / violet luminous ambient wave aura
                    Positioned(
                      right: -30.w,
                      top: -30.h,
                      child: Container(
                        width: 170.w,
                        height: 130.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF818CF8).withValues(alpha: 0.30),
                              const Color(0xFF6366F1).withValues(alpha: 0.18),
                              const Color(0xFF4338CA).withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Subtle top-left warm glow near the DAILY badge
                    Positioned(
                      left: -15.w,
                      top: -15.h,
                      child: Container(
                        width: 90.w,
                        height: 90.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFF59E0B).withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Card Content
                    Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top: [DAILY badge] Your Progress   ⭐️ 0 pts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF451A03), Color(0xFF78350F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: const Color(0xFFFB923C).withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      activePeriod.toUpperCase(),
                                      style: GoogleFonts.lato(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFB923C),
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Your Progress',
                                    style: GoogleFonts.lato(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ],
                              ),
                              _GlowingPointsBadge(points: points),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // Middle: 👑 Club: NO TIER (0%)      3000 pts to BRONZE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.crown,
                                    size: 15.r,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Club: ${currentTier.toUpperCase()}${club?.currentTierPct != null ? " (${club!.currentTierPct}%)" : " ($currentTierPct%)"}',
                                    style: GoogleFonts.lato(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                nextTier.isNotEmpty
                                    ? '$pointsToNext pts to ${nextTier.toUpperCase()}'
                                    : 'Top Tier Held',
                                style: GoogleFonts.lato(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFB923C),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          // Bottom: Smooth Rounded Progress Bar with Gradient & Subtle Glow
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final maxW = constraints.maxWidth;
                              final fillW = (maxW * progressVal).clamp(0.0, maxW);
                              return Container(
                                width: maxW,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222646),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 0.5,
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: fillW,
                                  height: 6.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF8A00),
                                        Color(0xFFFF5200),
                                        Color(0xFFEA580C),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF5200).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Pending points note (if any)
                          if (pendingPoints > 0) ...[
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  color: const Color(0xFF94A3B8),
                                  size: 12.r,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'Pending: $pendingPoints pts (unsettled orders)',
                                  style: GoogleFonts.lato(
                                    fontSize: 10.5.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

/// Circular golden points token (`<circle cx="12" cy="12" r="10" fill="url(#pts-_r_0_)" stroke="#A85E00" stroke-width="1.4">`)
/// along with animated left-to-right glowing points text.
class _GlowingPointsBadge extends StatefulWidget {
  final int points;
  const _GlowingPointsBadge({required this.points});

  @override
  State<_GlowingPointsBadge> createState() => _GlowingPointsBadgeState();
}

class _GlowingPointsBadgeState extends State<_GlowingPointsBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value;
        // Sweeping highlight from left to right (-1.0 to 2.0)
        final slide = -1.0 + (progress * 3.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular golden coin token
            Container(
              width: 19.r,
              height: 19.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF3B0),
                    Color(0xFFFFD54F),
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                  stops: [0.0, 0.35, 0.7, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFA85E00),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.star_rounded,
                size: 11.r,
                color: const Color(0xFF78350F),
              ),
            ),
            SizedBox(width: 5.w),
            // Glowing Points text with left-to-right animated shimmer
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    (slide - 0.3).clamp(0.0, 1.0),
                    slide.clamp(0.0, 1.0),
                    (slide + 0.3).clamp(0.0, 1.0),
                  ],
                  colors: const [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFE082), // Golden radiant shimmer
                    Color(0xFFFFFFFF),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                '${widget.points} pts',
                style: GoogleFonts.lato(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
