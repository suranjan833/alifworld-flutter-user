import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/support_controller.dart';

class SupportView extends GetView<SupportController> {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          'Help & Support',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Buttons Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.openLiveChat(),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.message_2,
                            color: AppColor.primaryDark,
                            size: 28.r,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Live Chat',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 40.h,
                    width: 1.w,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.call,
                          color: AppColor.primaryDark,
                          size: 28.r,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Call Us',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            Obx(
              () => Column(
                children: controller.faqs.map((faq) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        faq['question']!,
                        style: GoogleFonts.lato(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 16.w,
                            right: 16.w,
                            bottom: 14.h,
                          ),
                          child: Text(
                            faq['answer']!,
                            style: GoogleFonts.lato(
                              fontSize: 13.sp,
                              color: AppColor.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
