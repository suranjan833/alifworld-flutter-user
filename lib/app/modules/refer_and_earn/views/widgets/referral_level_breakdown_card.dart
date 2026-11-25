import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/models/referral_model.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/refer_and_earn_controller.dart';

class ReferralLevelBreakdownCard extends GetView<ReferAndEarnController> {
  final ReferralInfoModel info;

  const ReferralLevelBreakdownCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final currencySymbol = info.currencySymbol;
    final levels = info.levels;
    final regPcts = controller.registrationReferralPcts;
    final orderPcts = controller.orderReferralPcts;

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
              Icon(Iconsax.profile_add, color: AppColor.primary, size: 20.r),
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
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle,
                    size: 15.r, color: const Color(0xFF2563EB)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'When someone registers with your code, you and your uplines earn a % of the registration bonus — up to 3 levels.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '1. Registration Referral Rates (% of welcome bonus)',
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.primaryDark,
            ),
          ),
          SizedBox(height: 8.h),
          ...levels.map((lvl) {
            final regPct = regPcts.length >= lvl.level
                ? regPcts[lvl.level - 1]
                : lvl.ratePct;
            final earningsMajor = lvl.earningsMajor;
            final userCount = lvl.userCount;

            String countText = '';
            if (userCount != null) {
              countText = userCount == 1 ? '1 user' : '$userCount users';
            }

            return InkWell(
              onTap: () {
                Get.toNamed(
                  Routes.REFERRAL_LEVEL_HISTORY,
                  arguments: {
                    'level': lvl.level,
                    'userCount': lvl.userCount ?? 0,
                    'ratePct': regPct,
                  },
                );
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                            'Level ${lvl.level} · $regPct%',
                            style: GoogleFonts.lato(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          if (countText.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              '$countText  •  Tap to view',
                              style: GoogleFonts.lato(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColor.primary,
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
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20.r,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 12.h),
          Text(
            '2. Order Referral Rates (% of order points value)',
            style: GoogleFonts.lato(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD97706),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Level ${i + 1}',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${orderPcts.length > i ? orderPcts[i] : (3 - i)}%',
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'of order points',
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            color: const Color(0xFF92400E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle,
                    size: 15.r, color: AppColor.textSecondary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Referral rewards are ongoing — you earn on every order your referrals place, up to 3 levels.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
