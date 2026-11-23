import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/models/referral_model.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/refer_and_earn_controller.dart';

class ReferralEarningsCard extends GetView<ReferAndEarnController> {
  final ReferralInfoModel info;

  const ReferralEarningsCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
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
          if (info.hasUserCounts) ...[
            Row(
              children: [
                _buildCountBadge('Total Users', info.totalUserCount.toString()),
                SizedBox(width: 8.w),
                ...info.levels.map((lvl) {
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(
                          Routes.REFERRAL_LEVEL_HISTORY,
                          arguments: {
                            'level': lvl.level,
                            'userCount': lvl.userCount ?? 0,
                            'ratePct': lvl.ratePct,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        margin: EdgeInsets.only(
                          left: lvl.level > 1 ? 8.w : 0,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              (lvl.userCount ?? 0).toString(),
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                            ),
                            Text(
                              'Level ${lvl.level} >',
                              style: GoogleFonts.lato(
                                fontSize: 10.sp,
                                color: AppColor.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ] else ...[
            Row(
              children: [
                _buildCountBadge(
                  'Direct Referrals',
                  info.referredCount.toString(),
                ),
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
}
