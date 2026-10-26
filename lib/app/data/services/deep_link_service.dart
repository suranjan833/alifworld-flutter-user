import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../config/functions/dio_function/app_config.dart';
import '../../modules/signup/controllers/signup_controller.dart';
import '../../routes/app_pages.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find<DeepLinkService>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  Future<DeepLinkService> init() async {
    _appLinks = AppLinks();

    // 1. Check Google Play Install Referrer on first launch
    _checkInstallReferrerOnce();

    // 2. Handle cold start deep link
    _initInitialLink();

    // 3. Listen to warm start deep links
    _initLinkStream();

    return this;
  }

  /// First-launch Google Play Install Referrer query (Android only)
  Future<void> _checkInstallReferrerOnce() async {
    final alreadyConsumed = getBox.read(INSTALL_REFERRER_CONSUMED) == true;
    if (alreadyConsumed) return;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      getBox.write(INSTALL_REFERRER_CONSUMED, true);
      return;
    }

    try {
      final details = await PlayInstallReferrer.installReferrer
          .timeout(const Duration(seconds: 4));
      final rawReferrer = details.installReferrer;
      if (rawReferrer != null && rawReferrer.isNotEmpty) {
        log('PlayInstallReferrer raw: $rawReferrer');
        final code = extractReferralCodeFromRaw(rawReferrer);
        if (code != null && code.isNotEmpty) {
          // Persist pending code unless tapped link has already set one
          final existingCode = getBox.read(PENDING_REFERRAL_CODE);
          if (existingCode == null || existingCode.toString().trim().isEmpty) {
            getBox.write(PENDING_REFERRAL_CODE, code);
            log('PlayInstallReferrer saved referral code: $code');
          }
        }
      }
    } catch (e) {
      log('PlayInstallReferrer check non-fatal error: $e');
    } finally {
      // Always mark as consumed so we never query again
      getBox.write(INSTALL_REFERRER_CONSUMED, true);
    }
  }

  /// Cold start link check
  Future<void> _initInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        log('DeepLink initialUri: $initialUri');
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      log('DeepLink initial link error: $e');
    }
  }

  /// Warm start link stream
  void _initLinkStream() {
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        log('DeepLink incoming uri: $uri');
        _handleIncomingUri(uri);
      },
      onError: (err) {
        log('DeepLink stream error: $err');
      },
    );
  }

  void _handleIncomingUri(Uri uri) {
    final code = extractReferralCodeFromUri(uri);
    if (code == null || code.isEmpty) return;

    // Tapped link always updates the pending code
    getBox.write(PENDING_REFERRAL_CODE, code);
    log('DeepLink saved referral code: $code');

    // Check if user is already signed in
    final token = getBox.read(USER_TOKEN);
    final hasToken = token != null && token.toString().trim().isNotEmpty;
    final loggedInVal = getBox.read(IS_USER_LOGGED_IN);
    final isLoggedIn = (loggedInVal == true || loggedInVal == 'true' || hasToken);

    if (isLoggedIn) {
      // Case A: User signed in -> ignore link, stay on current screen
      log('User is already logged in. Ignoring deep link navigation.');
      return;
    }

    // If SignupController is active, update the controller's field immediately
    if (Get.isRegistered<SignupController>()) {
      try {
        final signupCtrl = Get.find<SignupController>();
        signupCtrl.referralCodeController.text = code;
      } catch (_) {}
    }

    // If not on Sign Up page, navigate to Sign Up
    if (Get.currentRoute != Routes.SIGNUP) {
      Get.toNamed(Routes.SIGNUP, arguments: {'referralCode': code});
    }
  }

  /// Extracts and sanitizes referral code from Uri
  static String? extractReferralCodeFromUri(Uri uri) {
    String? code = uri.queryParameters['ref'];
    if (code != null && code.isNotEmpty) {
      return sanitizeReferralCode(code);
    }

    // Check if encoded in raw query
    return extractReferralCodeFromRaw(uri.query);
  }

  /// Extracts and sanitizes referral code from raw query string or referrer string
  static String? extractReferralCodeFromRaw(String raw) {
    if (raw.isEmpty) return null;

    try {
      String decoded = raw;
      if (raw.contains('%')) {
        try {
          decoded = Uri.decodeFull(raw);
        } catch (_) {
          decoded = raw;
        }
      }

      // 1. Direct query parameter check
      final refMatch = RegExp(r'(?:^|[?&])ref=([A-Za-z0-9]+)').firstMatch(decoded);
      if (refMatch != null && refMatch.group(1) != null) {
        return sanitizeReferralCode(refMatch.group(1)!);
      }

      // 2. Play store referrer parameter: referrer=ref%3DCODE or referrer=ref=CODE
      final referrerMatch =
          RegExp(r'referrer=([^&]+)').firstMatch(decoded);
      if (referrerMatch != null && referrerMatch.group(1) != null) {
        final inner = Uri.decodeComponent(referrerMatch.group(1)!);
        final innerMatch =
            RegExp(r'(?:^|[?&])ref=([A-Za-z0-9]+)').firstMatch(inner);
        if (innerMatch != null && innerMatch.group(1) != null) {
          return sanitizeReferralCode(innerMatch.group(1)!);
        }
      }
    } catch (e) {
      log('Error extracting referral code: $e');
    }
    return null;
  }

  static String sanitizeReferralCode(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  @override
  void onClose() {
    _linkSub?.cancel();
    super.onClose();
  }
}
