import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/app_image.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: [
          // Background ambient gradient circles
          Positioned(
            top: -80.h,
            right: -80.w,
            child: Container(
              width: 240.w,
              height: 240.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColor.primary.withValues(alpha: 0.18),
                    AppColor.primaryLight.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90.h,
            left: -90.w,
            child: Container(
              width: 260.w,
              height: 260.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColor.primary.withValues(alpha: 0.15),
                    AppColor.primaryLight.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Center Logo and Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Transparent Logo Image
                FadeTransition(
                  opacity: controller.logoFadeAnimation,
                  child: SlideTransition(
                    position: controller.logoSlideAnimation,
                    child: ScaleTransition(
                      scale: controller.logoScaleAnimation,
                      child: Image.asset(
                        AppImage.logo,
                        width: 240.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Animated Tagline
                SlideTransition(
                  position: controller.taglineSlideAnimation,
                  child: FadeTransition(
                    opacity: controller.taglineFadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Smart Shopping & Instant Delivery',
                          style: GoogleFonts.lato(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 36.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading / Branding
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: controller.bottomFadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 26.w,
                    height: 26.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'v1.1.8',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
