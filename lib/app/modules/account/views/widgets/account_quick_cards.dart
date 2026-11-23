import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/account_controller.dart';

class AccountQuickCards extends GetView<AccountController> {
  const AccountQuickCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
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
            child: _buildActionCard(
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
            child: _buildActionCard(
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

  Widget _buildActionCard({
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
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(height: 10.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                maxLines: 1,
                style: GoogleFonts.lato(
                  fontSize: 10.5.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
