import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../controllers/about_us_controller.dart';

class AboutUsView extends GetView<AboutUsController> {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
          'About Us',
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // App Branding Banner Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: GoogleFonts.lato(
                          fontSize: 38.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Alif Shopping App',
                    style: GoogleFonts.lato(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Obx(
                    () => Text(
                      'Version ${controller.appVersion.value}',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Alif is your premier one-stop e-commerce platform delivering groceries, electronics, fashion, home appliances, and daily essentials right to your doorstep.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      color: AppColor.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Core Values
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Our Core Values',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            Column(
              children: controller.coreValues.map((val) {
                return Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7E6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: AppColor.primaryDark,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              val['title']!,
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              val['description']!,
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                color: AppColor.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
