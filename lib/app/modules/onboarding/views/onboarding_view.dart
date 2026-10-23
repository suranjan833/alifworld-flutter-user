import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Skip Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: controller.skipToHome,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.lato(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: controller.onPageChanged,
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Center Illustration
                        item.illustration,

                        SizedBox(height: 36.h),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // Description
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.normal,
                              color: AppColor.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Section: Indicators and Action Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(controller.items.length, (index) {
                        final isActive = controller.currentPage.value == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: isActive ? 26.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColor.primary
                                : AppColor.indicatorInactive,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Bottom Action Button (Next / Get Started)
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          controller.isLastPage ? 'Get Started' : 'Next',
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
