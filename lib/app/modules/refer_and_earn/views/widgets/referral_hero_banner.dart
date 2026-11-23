import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/models/referral_model.dart';
import '../../controllers/refer_and_earn_controller.dart';

class ReferralHeroBanner extends GetView<ReferAndEarnController> {
  final ReferralInfoModel info;

  const ReferralHeroBanner({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
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
                      'Earn up to ${controller.formattedRegistrationBonus}',
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
}
