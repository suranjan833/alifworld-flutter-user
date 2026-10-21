import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';

/// Checks if device currently has active internet connectivity
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } on TimeoutException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}

/// Global helper to show the No Internet Dialog with GIF and Retry action
void showNoInternetDialog({
  Future<void> Function()? onRetry,
  String? title,
  String? message,
}) {
  // If already open, do not open multiple duplicate dialogs
  if (Get.isDialogOpen == true) return;

  final isRetrying = false.obs;

  Get.dialog(
    Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // No Internet Animated GIF
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/images/no_internet.gif',
                width: 150.r,
                height: 150.r,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 50.r,
                    color: AppColor.error,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Title
            Text(
              title ?? 'No Internet Connection',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),

            // Description
            Text(
              message ??
                  'Please check your internet settings and connection, then try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),

            // Retry Button
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: Obx(
                () => ElevatedButton(
                  onPressed: isRetrying.value
                      ? null
                      : () async {
                          isRetrying.value = true;
                          final isOnline = await hasInternetConnection();
                          isRetrying.value = false;

                          if (isOnline) {
                            Get.back(); // Close dialog on restored internet
                            if (onRetry != null) {
                              await onRetry();
                            }
                          } else {
                            Get.snackbar(
                              'Still Offline',
                              'No active internet detected. Please check Wi-Fi / Mobile Data.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColor.error,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: isRetrying.value
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Try Again',
                          style: GoogleFonts.inter(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Dismiss Button
            TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

/// Standalone Full-screen or Container Widget for No Internet State
class NoInternetWidget extends StatelessWidget {
  final Future<void> Function()? onRetry;
  final String? message;

  const NoInternetWidget({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no_internet.gif',
              width: 160.r,
              height: 160.r,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100.r,
                height: 100.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 50.r,
                  color: AppColor.error,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Internet Connection',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message ??
                  'You seem to be offline. Please verify your internet connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: () async {
                  await onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

