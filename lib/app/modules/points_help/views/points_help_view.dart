import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/points_help_controller.dart';

class PointsHelpView extends GetView<PointsHelpController> {
  const PointsHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PointsHelpController>()) {
      Get.put(PointsHelpController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          'Points',
          style: GoogleFonts.lato(
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        final ctrl = controller;
        final split = ctrl.customerSplit;
        final refPcts = ctrl.referralPct;
        final l1 = refPcts.isNotEmpty ? refPcts[0] : 3;
        final l2 = refPcts.length > 1 ? refPcts[1] : 2;
        final l3 = refPcts.length > 2 ? refPcts[2] : 1;
        final geo = ctrl.geoPct;

        return RefreshIndicator(
          onRefresh: ctrl.refreshInfo,
          color: AppColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Intro Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.black.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🪙', style: TextStyle(fontSize: 22)),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'How Points Work',
                              style: GoogleFonts.lato(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Points reward you on top of the price — you earn them on every order and keep earning after delivery.',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: const Color(0xFFE2E8F0),
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColor.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Value: ',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            Text(
                              '1 point = ${ctrl.pointValueFormatted}',
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 2. Selling Price & Worked Example
                _buildSectionCard(
                  icon: Iconsax.tag,
                  title: 'How the Selling Price Works',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selling price = MRP − discount. Points never cut the price — you earn them on top of it.',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Worked Example:',
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.primaryDark,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildExampleRow('MRP', '৳100'),
                            _buildExampleRow('Discount (10%)', '−৳10'),
                            _buildExampleRow('Selling Price', '৳90', isBold: true),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildExampleRow('You Save', '৳10 (discount only)', color: const Color(0xFF16A34A)),
                            _buildExampleRow('You Earn', '20 points (৳20 value)', color: const Color(0xFFD97706), isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 3. Cashback & Wallet Split
                _buildSectionCard(
                  icon: Iconsax.wallet_3,
                  title: 'Cashback & Wallet Split',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ctrl.cashbackPct}% of the points\' value comes back as cashback, split across your wallets:',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: AppColor.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _buildSplitChip('Main Wallet', '${split.main}%', const Color(0xFF0F172A)),
                          _buildSplitChip('Shopping Wallet', '${split.shopping}%', const Color(0xFF2563EB)),
                          _buildSplitChip('Good Luck Wallet', '${split.goodLuck}%', const Color(0xFF7C3AED)),
                          _buildSplitChip('Charity Wallet', '${split.charity}%', const Color(0xFF059669)),
                          _buildSplitChip('Service Charge', '${split.serviceCharge}%', const Color(0xFF64748B), isPlatform: true),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Cashback posts after the return window closes and lands directly in your wallets.',
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          fontStyle: FontStyle.italic,
                          color: AppColor.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 4. Referral Rewards
                _buildSectionCard(
                  icon: Iconsax.profile_2user,
                  title: 'Order Referral Rewards',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When someone buys through your referral link, you share $l1% / $l2% / $l3% of the order\'s points value (level 1 / 2 / 3):',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: AppColor.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          _buildLevelCard('Level 1', '$l1%', 'Direct Invite'),
                          SizedBox(width: 8.w),
                          _buildLevelCard('Level 2', '$l2%', 'Sub Invite'),
                          SizedBox(width: 8.w),
                          _buildLevelCard('Level 3', '$l3%', 'Tier 3 Invite'),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 5. Area Commissions
                _buildSectionCard(
                  icon: Iconsax.location,
                  title: 'Area Commissions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A share of every order\'s points value goes to the mapped beneficiary of the delivery area:',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: AppColor.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _buildAreaBadge('Division', '${geo.division}%'),
                          _buildAreaBadge('District', '${geo.district}%'),
                          _buildAreaBadge('Upazila', '${geo.upazila}%'),
                          if (geo.union > 0) _buildAreaBadge('Union', '${geo.union}%'),
                          if (geo.area > 0) _buildAreaBadge('Area', '${geo.area}%'),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 6. Clubs
                _buildSectionCard(
                  icon: Iconsax.crown,
                  title: 'Customer Clubs',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earn enough points in a period to reach a tier and get a bonus on your points (Bronze 1%, Silver 2%, Gold 3%):',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: AppColor.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildClubPeriodRow('Daily (24h)', '3,000 pts', '4,000 pts', '5,000 pts'),
                      _buildClubPeriodRow('Weekly (7d)', '25,000 pts', '30,000 pts', '40,000 pts'),
                      _buildClubPeriodRow('Monthly (30d)', '130,000 pts', '150,000 pts', '200,000 pts'),
                      _buildClubPeriodRow('Yearly (365d)', '1,600,000 pts', '2,000,000 pts', '2,500,000 pts'),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 7. Star Bands
                _buildSectionCard(
                  icon: Iconsax.star_1,
                  title: 'Customer Stars',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top customers each period earn a star bonus from the platform reward pool:',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          color: AppColor.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildStarBandTile('Mega Star', 'Ranks 1 – 10', '1% Pool', const Color(0xFFD97706)),
                      _buildStarBandTile('Super Star', 'Ranks 11 – 50', '1% Pool', const Color(0xFF2563EB)),
                      _buildStarBandTile('Star', 'Ranks 51 – 100', '1% Pool', const Color(0xFF059669)),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.r, color: AppColor.primaryDark),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildExampleRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: AppColor.textPrimary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
              color: color ?? AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitChip(String name, String pct, Color color, {bool isPlatform = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$name: ',
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            pct,
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(String level, String pct, String desc) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              pct,
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.primaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              desc,
              style: GoogleFonts.lato(
                fontSize: 10.sp,
                color: AppColor.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaBadge(String area, String pct) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$area: ',
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E40AF),
            ),
          ),
          Text(
            pct,
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubPeriodRow(String period, String bronze, String silver, String gold) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: _buildTierPill(
                  tier: 'Bronze',
                  pts: bronze,
                  color: const Color(0xFFB45309),
                  bg: const Color(0xFFFEF3C7),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildTierPill(
                  tier: 'Silver',
                  pts: silver,
                  color: const Color(0xFF475569),
                  bg: const Color(0xFFF1F5F9),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildTierPill(
                  tier: 'Gold',
                  pts: gold,
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFFFBEB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierPill({
    required String tier,
    required String pts,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tier,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            pts,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarBandTile(String name, String ranks, String poolShare, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            ranks,
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            poolShare,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
