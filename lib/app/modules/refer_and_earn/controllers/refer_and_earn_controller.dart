import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/referral_model.dart';

class ReferAndEarnController extends GetxController {
  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isLoadingMore = false.obs;

  final referralInfo = Rxn<ReferralInfoModel>();
  final historyItems = <ReferralHistoryItem>[].obs;
  final nextCursor = RxnString();

  String get referralCode => referralInfo.value?.code ?? '';
  String get shareUrl =>
      referralInfo.value?.shareUrl ??
      'https://alifworld.com.bd/register?ref=$referralCode';
  String get playStoreUrl =>
      referralInfo.value?.playStoreUrl ??
      'https://play.google.com/store/apps/details?id=$APP_PACKAGE_NAME&referrer=ref%3D$referralCode';

  @override
  void onInit() {
    super.onInit();
    fetchReferralData();
    fetchReferralHistory();
  }

  /// Fresh load from API - never cache referral data
  Future<void> fetchReferralData() async {
    isLoading.value = true;
    try {
      final response = await dioGet('referrals');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;

        referralInfo.value = ReferralInfoModel.fromJson(data);
      } else {
        log('Failed to fetch referral info: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching referral info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch recent referrals history
  Future<void> fetchReferralHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      nextCursor.value = null;
    }
    isHistoryLoading.value = true;

    try {
      final response = await dioGet('referrals/history?limit=20');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;

        final historyResp = ReferralHistoryResponse.fromJson(data);
        historyItems.assignAll(historyResp.items);
        nextCursor.value = historyResp.nextCursor;
      }
    } catch (e) {
      log('Error fetching referral history: $e');
    } finally {
      isHistoryLoading.value = false;
    }
  }

  /// Load more history items using cursor pagination
  Future<void> loadMoreHistory() async {
    if (isLoadingMore.value ||
        nextCursor.value == null ||
        nextCursor.value!.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final cursor = Uri.encodeComponent(nextCursor.value!);
      final response = await dioGet('referrals/history?limit=20&cursor=$cursor');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;

        final historyResp = ReferralHistoryResponse.fromJson(data);
        historyItems.addAll(historyResp.items);
        nextCursor.value = historyResp.nextCursor;
      }
    } catch (e) {
      log('Error loading more history: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Pull to refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchReferralData(),
      fetchReferralHistory(isRefresh: true),
    ]);
  }

  /// Copy Referral Code
  void copyCode() {
    if (referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: referralCode));
    showSnack('Copied!', 'Referral code copied to clipboard');
  }

  /// Copy Web Registration Link
  void copyLink() {
    if (shareUrl.isEmpty) return;
    Clipboard.setData(ClipboardData(text: shareUrl));
    showSnack('Copied!', 'Registration link copied to clipboard');
  }

  /// Share via System Share Sheet
  Future<void> shareInvite() async {
    if (referralCode.isEmpty) return;

    final bonusText = referralInfo.value?.registrationBonus.formattedAmount ?? '৳1,000';
    final shareText = '''
🎁 Join me on Alif World and get $bonusText welcome bonus!

Use my referral code: $referralCode

👉 Register here:
$shareUrl

📱 Download Android App:
$playStoreUrl
''';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Join Alif World - Get Welcome Bonus!',
        ),
      );
    } catch (e) {
      log('Error sharing: $e');
      copyLink();
    }
  }
}
