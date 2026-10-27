import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/config/app_color.dart';
import '../../../data/models/referral_model.dart';
import '../controllers/refer_and_earn_controller.dart';

class ReferAndEarnView extends GetView<ReferAndEarnController> {
  const ReferAndEarnView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
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
          'Refer and Earn',
          style: GoogleFonts.lato(
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.refreshAll(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.referralInfo.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = controller.referralInfo.value;
        if (info == null) {
          return Center(
            child: Text(
              'Failed to load referral details.',
              style: GoogleFonts.lato(color: AppColor.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          color: AppColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Promo Card
                _buildHeroBanner(info),
                SizedBox(height: 16.h),

                // 2. Share Code & Actions
                _buildReferralCodeCard(context, info),
                SizedBox(height: 16.h),

                // 3. Stats & Earnings (Separated Registration vs Order per §1)
                _buildEarningsCard(info),
                SizedBox(height: 16.h),

                // 4. 3-Level Rates Card (with userCount under level label per §2 & §5)
                _buildLevelBreakdownCard(info),
                SizedBox(height: 20.h),

                // 5. Recent Referral History (Level under name, date on right per §3 & §5)
                _buildHistorySection(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 1. Hero Banner
  Widget _buildHeroBanner(ReferralInfoModel info) {
    final bonus = info.registrationBonus;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryDark,
            AppColor.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.gift, color: AppColor.white, size: 28.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'REGISTRATION BONUS',
                        style: GoogleFonts.lato(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFD700),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      bonus.amountMinor > 0
                          ? 'Earn up to ${bonus.formattedAmount}'
                          : 'Refer & Earn',
                      style: GoogleFonts.lato(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Invite friends to join Alif World! You get paid across 3 referral tiers directly credited to your Customer Referral Wallet upon registration.',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              color: AppColor.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Code and Sharing Hub
  Widget _buildReferralCodeCard(BuildContext context, ReferralInfoModel info) {
    final code = info.code;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Code',
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 10.h),

          // Code display box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.3),
                style: BorderStyle.solid,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code.isNotEmpty ? code : '--------',
                  style: GoogleFonts.spaceMono(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                    letterSpacing: 3,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: code.isNotEmpty ? controller.copyCode : null,
                  icon: Icon(Iconsax.copy, size: 16.r),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Action Buttons: Share Invite, Copy Link, QR Code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      code.isNotEmpty ? () => controller.shareInvite() : null,
                  icon: Icon(Iconsax.share, size: 18.r),
                  label: Text(
                    'Share Invite',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: code.isNotEmpty ? controller.copyLink : null,
                  icon: Icon(Iconsax.link, size: 16.r),
                  label: Text(
                    'Link',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.textPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              IconButton.outlined(
                onPressed: code.isNotEmpty
                    ? () => _showQrModal(context, controller.shareUrl, code)
                    : null,
                icon: Icon(Iconsax.scan_barcode, size: 20.r),
                style: IconButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: BorderSide(
                    color: AppColor.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                tooltip: 'View QR Code',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Stats and Earnings (Strictly separated per §1 & §2)
  Widget _buildEarningsCard(ReferralInfoModel info) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Referral Summary',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Total: ${info.formattedTotalEarnings}',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Two separate earnings rows
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _buildEarningsRow(
                  icon: Iconsax.user_add,
                  label: 'Registration Referral',
                  amount: info.formattedRegistrationEarnings,
                  subtitle: 'Earned from signup welcome bonuses',
                  iconColor: AppColor.primary,
                ),
                Divider(height: 18.h, color: const Color(0xFFE2E8F0)),
                _buildEarningsRow(
                  icon: Iconsax.shopping_bag,
                  label: 'Order Referral',
                  amount: info.formattedOrderEarnings,
                  subtitle: 'Earned on referred users\' order points',
                  iconColor: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Users count breakdown
          if (info.hasUserCounts) ...[
            Row(
              children: [
                _buildCountBadge('Total Users', info.totalUserCount.toString()),
                SizedBox(width: 8.w),
                ...info.levels.map((lvl) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: lvl.level > 1 ? 8.w : 0,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            (lvl.userCount ?? 0).toString(),
                            style: GoogleFonts.lato(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          Text(
                            'Level ${lvl.level}',
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
                              color: AppColor.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ] else ...[
            Row(
              children: [
                _buildCountBadge('Direct Referrals', info.referredCount.toString()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsRow({
    required IconData icon,
    required String label,
    required String amount,
    required String subtitle,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20.r),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.lato(
                  fontSize: 11.5.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: AppColor.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(String label, String count) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.lato(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 10.sp,
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. 3-Level Rates Card (with userCount under level label per refer.md §2 & §5)
  Widget _buildLevelBreakdownCard(ReferralInfoModel info) {
    final currencySymbol = info.currencySymbol;
    final levels = info.levels;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.hierarchy_2, color: AppColor.primary, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                '3-Level Referral Rates',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          ...levels.map((lvl) {
            final rate = lvl.ratePct;
            final earningsMajor = lvl.earningsMajor;
            final userCount = lvl.userCount;

            String countText = '';
            if (userCount != null) {
              countText = userCount == 1 ? '1 user' : '$userCount users';
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'L${lvl.level}',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${lvl.level} · $rate%',
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        if (countText.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            countText,
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '$currencySymbol${earningsMajor.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 5. Recent Referrals Section (per refer.md §3: level under name, date on right)
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Referrals',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            if (controller.isHistoryLoading.value)
              SizedBox(
                width: 16.r,
                height: 16.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.r,
                  color: AppColor.primary,
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),

        if (controller.historyItems.isEmpty &&
            !controller.isHistoryLoading.value)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.user_search,
                  size: 42.r,
                  color: const Color(0xFF94A3B8),
                ),
                SizedBox(height: 12.h),
                Text(
                  'No referrals yet',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Share your referral code or link with friends to start earning bonuses!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 12.5.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.historyItems.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final item = controller.historyItems[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          item.name.isNotEmpty
                              ? item.name[0].toUpperCase()
                              : 'F',
                          style: GoogleFonts.lato(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Level ${item.level}',
                            style: GoogleFonts.lato(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.formattedJoinedDate.isNotEmpty)
                      Text(
                        item.formattedJoinedDate,
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: AppColor.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

        if (controller.nextCursor.value != null &&
            controller.nextCursor.value!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Center(
              child: TextButton(
                onPressed: controller.isLoadingMore.value
                    ? null
                    : controller.loadMoreHistory,
                child: controller.isLoadingMore.value
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Load More',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  /// QR Code Modal
  void _showQrModal(BuildContext context, String url, String code) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan & Register',
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Friends can scan this QR code to register with your referral',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200.r,
                  backgroundColor: AppColor.white,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Code: $code',
                style: GoogleFonts.spaceMono(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primary,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
