import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../config/functions/dio_function/app_config.dart';
import '../../modules/signup/controllers/signup_controller.dart';
import '../../modules/splash/controllers/splash_controller.dart';
import '../../routes/app_pages.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find<DeepLinkService>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  String? pendingProductSlug;
  String? pendingVariantId;
  String? _lastHandledUrl;
  DateTime? _lastHandledTime;

  void clearPendingProduct() {
    pendingProductSlug = null;
    pendingVariantId = null;
    getBox.remove('pending_deep_link_product');
    getBox.remove('pending_deep_link_variant');
  }

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
    log('DeepLink received URI: $uri');

    final urlStr = uri.toString();
    final now = DateTime.now();
    if (_lastHandledUrl == urlStr &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!).inMilliseconds < 1500) {
      log('DeepLink: Duplicate URI ignored ($urlStr)');
      return;
    }
    _lastHandledUrl = urlStr;
    _lastHandledTime = now;

    // 1. Check for product deep link (/product/:slug or alifworld://product/:slug)
    final productData = extractProductDetailsFromUri(uri);
    if (productData != null) {
      _handleProductDeepLink(productData);
      return;
    }

    // 2. Check for referral deep link (/register?ref=CODE or alifworld://register?ref=CODE)
    final code = extractReferralCodeFromUri(uri);
    if (code != null && code.isNotEmpty) {
      _handleReferralDeepLink(code);
    }
  }

  void _handleProductDeepLink(Map<String, String> productData) {
    final slug = productData['slug'];
    if (slug == null || slug.isEmpty) return;
    final variantId = productData['variantId'];

    log('DeepLink product detected: slug=$slug, variantId=$variantId');

    // Always persist so SplashController can detect it reliably
    pendingProductSlug = slug;
    pendingVariantId = variantId;
    getBox.write('pending_deep_link_product', slug);
    if (variantId != null && variantId.isNotEmpty) {
      getBox.write('pending_deep_link_variant', variantId);
    } else {
      getBox.remove('pending_deep_link_variant');
    }

    final current = Get.currentRoute.toLowerCase();
    final isSplash = Get.isRegistered<SplashController>() ||
        current.isEmpty ||
        current == '/' ||
        current.contains('splash');

    if (isSplash) {
      log('DeepLink: Splash active. Stored pending product for SplashController.');
      return;
    }

    // Navigate immediately if app is already active beyond splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        // If already on product details for the same product, don't re-push
        if (Get.currentRoute.toLowerCase().contains('product-details')) {
          final currentArgs = Get.arguments;
          final currentSlug =
              currentArgs is Map ? currentArgs['slug']?.toString() : null;
          if (currentSlug == slug) {
            log('DeepLink: Already on product details for $slug');
            return;
          }
        }

        Get.toNamed(
          Routes.PRODUCT_DETAILS,
          arguments: {
            'slug': slug,
            if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
          },
        );
      }
    });
  }

  void _handleReferralDeepLink(String code) {
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

    // If not already on Splash, Sign Up, or Register, navigate to Sign Up safely
    final current = Get.currentRoute.toLowerCase();
    final isAlreadyOnAuth = current.contains('signup') ||
        current.contains('register') ||
        current.contains('splash');

    if (!isAlreadyOnAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.toNamed(Routes.SIGNUP, arguments: {'referralCode': code});
        }
      });
    }
  }

  /// Extracts product slug and optional variantId from Uri
  static Map<String, String>? extractProductDetailsFromUri(Uri uri) {
    String? slug;
    final variantId = uri.queryParameters['variant'];

    // 1. Custom scheme: alifworld://product/SLUG or alifworld://products/SLUG
    if (uri.scheme == 'alifworld') {
      if (uri.host == 'product' || uri.host == 'products') {
        if (uri.pathSegments.isNotEmpty) {
          slug = uri.pathSegments.first;
        } else if (uri.path.isNotEmpty) {
          slug = uri.path.replaceAll('/', '').trim();
        }
      }
    }

    // 2. HTTPS / HTTP: https://domain/product/SLUG or /products/SLUG
    if (slug == null || slug.isEmpty) {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final first = segments[0].toLowerCase();
        if (first == 'product' || first == 'products') {
          slug = segments[1].trim();
        }
      } else if (segments.length == 1 &&
          (uri.path.startsWith('/product/') || uri.path.startsWith('/products/'))) {
        slug = uri.path.split('/').last.trim();
      }
    }

    // 3. Fallback: query parameters e.g. ?product=SLUG or ?slug=SLUG
    if (slug == null || slug.isEmpty) {
      slug = uri.queryParameters['slug'] ?? uri.queryParameters['product'];
    }

    if (slug != null && slug.isNotEmpty) {
      return {
        'slug': slug,
        if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      };
    }
    return null;
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
