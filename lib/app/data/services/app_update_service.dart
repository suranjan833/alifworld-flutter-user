import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_color.dart';

class AppUpdateService extends GetxService with WidgetsBindingObserver {
  static AppUpdateService get to => Get.find<AppUpdateService>();

  static const String playStorePackage = 'com.dream.alifbd';
  static const String playStoreMarketUri =
      'market://details?id=$playStorePackage';
  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=$playStorePackage';

  final isChecking = false.obs;
  final isUpdateAvailable = false.obs;
  final isDialogOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify update availability when user returns to foreground
      if (!isDialogOpen.value) {
        checkForUpdate(isBackground: true);
      }
    }
  }

  /// Checks Google Play Store for new updates.
  /// Returns `true` if an update is available and the mandatory dialog is shown.
  Future<bool> checkForUpdate({
    bool isBackground = false,
    bool showToastIfNoUpdate = false,
  }) async {
    // In-app update API only operates on Android signed/installed builds
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (showToastIfNoUpdate) {
        _showToast('App is up to date');
      }
      return false;
    }

    try {
      isChecking.value = true;
      final info = await InAppUpdate.checkForUpdate();
      isChecking.value = false;

      log(
        'InAppUpdate check: availability=${info.updateAvailability}, '
        'immediateAllowed=${info.immediateUpdateAllowed}, '
        'availableVersionCode=${info.availableVersionCode}',
      );

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        isUpdateAvailable.value = true;
        showForceUpdateDialog(info: info);
        return true;
      } else {
        isUpdateAvailable.value = false;
        if (showToastIfNoUpdate) {
          _showToast('You are using the latest version of Alif World');
        }
        return false;
      }
    } catch (e) {
      isChecking.value = false;
      log('InAppUpdate check non-fatal error: $e');
      if (showToastIfNoUpdate) {
        _showToast('Could not check for updates. Please try again later.');
      }
      return false;
    }
  }

  /// Displays the professional, non-dismissible force update popup dialog.
  void showForceUpdateDialog({AppUpdateInfo? info, bool isPreview = false}) {
    if (isDialogOpen.value && !isPreview) return;
    isDialogOpen.value = true;

    Get.dialog(
      PopScope(
        canPop: isPreview, // Non-dismissible in production
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
          child: _ForceUpdateDialogContent(
            info: info,
            onUpdatePressed: () => triggerUpdate(info),
            isPreview: isPreview,
          ),
        ),
      ),
      barrierDismissible: isPreview,
    ).then((_) {
      isDialogOpen.value = false;
    });
  }

  /// Triggers update: tries Google Play In-App immediate update first;
  /// gracefully falls back to opening the Play Store app listing.
  Future<void> triggerUpdate(AppUpdateInfo? info) async {
    bool immediateSucceeded = false;

    if (info != null && info.immediateUpdateAllowed) {
      try {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.success) {
          immediateSucceeded = true;
        }
      } catch (e) {
        log('InAppUpdate.performImmediateUpdate error: $e');
      }
    }

    if (!immediateSucceeded) {
      await openPlayStore();
    }
  }

  /// Direct launch to Google Play Store
  Future<void> openPlayStore() async {
    final marketUri = Uri.parse(playStoreMarketUri);
    final webUri = Uri.parse(playStoreWebUrl);

    try {
      final launched = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log('Error opening Play Store market link, falling back to web: $e');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (webErr) {
        log('Error launching Play Store web URL: $webErr');
      }
    }
  }

  void _showToast(String message) {
    Get.snackbar(
      'App Update',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.textPrimary,
      colorText: AppColor.white,
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      duration: const Duration(seconds: 3),
    );
  }
}

class _ForceUpdateDialogContent extends StatelessWidget {
  final AppUpdateInfo? info;
  final VoidCallback onUpdatePressed;
  final bool isPreview;

  const _ForceUpdateDialogContent({
    required this.info,
    required this.onUpdatePressed,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icon Header
                Container(
                  width: 82.r,
                  height: 82.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.primary.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Container(
                      width: 60.r,
                      height: 60.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.primary,
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: AppColor.white,
                        size: 32.r,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // 2. High-priority Chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EB),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColor.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primary,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'UPDATE REQUIRED',
                        style: GoogleFonts.lato(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // 3. Title
                Text(
                  'Update Your App',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(height: 8.h),

                // 4. Description
                Text(
                  'A new version of Alif World is available on Google Play. Please update now to continue shopping with the latest features, security updates, and performance improvements.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                    height: 1.45,
                  ),
                ),

                SizedBox(height: 18.h),

                // 5. Highlights Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow('Important bug & stability fixes'),
                      SizedBox(height: 8.h),
                      _buildFeatureRow('Faster product browsing & checkout'),
                      SizedBox(height: 8.h),
                      _buildFeatureRow('Enhanced security for your account'),
                    ],
                  ),
                ),

                SizedBox(height: 22.h),

                // 6. Primary Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: onUpdatePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 22.r,
                          color: AppColor.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Update on Play Store',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                // 7. Footer note
                Text(
                  'You must update to the latest version to proceed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: AppColor.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Optional close button only for preview/testing mode
          if (isPreview)
            Positioned(
              top: 10.h,
              right: 10.w,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.r,
                  color: AppColor.textSecondary,
                ),
                onPressed: () => Get.back(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Container(
          width: 18.r,
          height: 18.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD1FAE5),
          ),
          child: Icon(
            Icons.check_rounded,
            color: Color(0xFF059669),
            size: 13.r,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
