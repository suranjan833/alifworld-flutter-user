import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';

class ReferAndEarnController extends GetxController
    with SkeletonLoadingMixin {
  final referralCode = 'ALIF2026'.obs;
  final totalEarned = '₹500.00'.obs;
  final friendsReferred = 5.obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
  }

  void copyCode() {
    Clipboard.setData(ClipboardData(text: referralCode.value));
    Get.snackbar(
      'Copied!',
      'Referral code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.textPrimary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
