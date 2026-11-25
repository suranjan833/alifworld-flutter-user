import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/models/referral_model.dart';
import '../../controllers/refer_and_earn_controller.dart';

class ReferralCodeCard extends GetView<ReferAndEarnController> {
  final ReferralInfoModel info;

  const ReferralCodeCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.3),
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      code.isNotEmpty ? () => controller.shareInvite() : null,
                  icon: Icon(Icons.share_rounded, size: 18.r),
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

  void _showQrModal(BuildContext context, String url, String code) {
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
