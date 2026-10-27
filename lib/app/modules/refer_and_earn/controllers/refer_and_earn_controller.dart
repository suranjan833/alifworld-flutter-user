import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/referral_model.dart';
import '../../../routes/app_pages.dart';

class ReferAndEarnController extends GetxController {
  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isLoadingMore = false.obs;

  final referralInfo = Rxn<ReferralInfoModel>();
  final historyItems = <ReferralHistoryItem>[].obs;
  final nextCursor = RxnString();

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
  }

  String get referralCode => referralInfo.value?.code ?? '';
  String get shareUrl =>
      referralInfo.value?.link ??
      'https://alifworld.com.bd/register?ref=$referralCode';

  @override
  void onInit() {
    super.onInit();
    if (!hasAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.LOGIN);
      });
      return;
    }
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

  /// Share via System Share Sheet per refer.md §4
  Future<void> shareInvite() async {
    if (referralCode.isEmpty) return;

    final info = referralInfo.value;
    final bonusMinor = info?.registrationBonus.amountMinor ?? 0;
    final code = info?.code ?? referralCode;
    final link = info?.link ?? shareUrl;
    final symbol = info?.currencySymbol ?? '৳';

    String shareText;
    if (bonusMinor > 0) {
      final bonusTaka = (bonusMinor / 100).round();
      shareText =
          '🎁 Join me on Alif World and get $symbol$bonusTaka welcome bonus!\n\nUse my referral code: $code\n\n👉 Register here:\n$link';
    } else {
      shareText =
          '🎁 Join me on Alif World!\n\nUse my referral code: $code\n\n👉 Register here:\n$link';
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Join me on Alif World!',
        ),
      );

      // Per refer.md §4:
      // "If the user cancels the share sheet, stop — do not silently copy."
      // "If sharing is unavailable, copy the whole message."
      if (result.status == ShareResultStatus.unavailable) {
        Clipboard.setData(ClipboardData(text: shareText));
        showSnack('Copied!', 'Invite message copied to clipboard');
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: shareText));
      showSnack('Copied!', 'Invite message copied to clipboard');
    }
  }
}
