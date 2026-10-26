// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../app_color.dart';

final getBox = GetStorage();

// Default API Endpoints
const String _defaultProdUrl = "https://alifworld.com.bd/api/v1/";
const String _defaultDebugUrl = "https://dev.alifworld.com.bd/api/v1/";

String resolveBaseUrl() {
  String url;
  if (kReleaseMode) {
    url = dotenv.env['PROD_BASE_URL']?.trim() ?? _defaultProdUrl;
  } else {
    url = dotenv.env['DEBUG_BASE_URL']?.trim() ?? _defaultDebugUrl;
  }
  if (!url.endsWith('/')) {
    url = '$url/';
  }
  return url;
}

var BASE_URL = resolveBaseUrl();
var isDebugMode = (!kReleaseMode).obs;

void initAppConfig() {
  BASE_URL = resolveBaseUrl();
  isDebugMode.value = !kReleaseMode;
}

/// Resolves full image URL for relative asset paths (e.g. '/category-icons/electronics.svg')
/// using the current active BASE_URL host root, while preserving absolute URLs.
String resolveImageUrl(String? path) {
  if (path == null) return '';
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    // If it points to an old dead Vercel deployment, rewrite to the active host root
    if (trimmed.contains('.vercel.app')) {
      try {
        final deadUri = Uri.parse(trimmed);
        final activeUri = Uri.parse(BASE_URL);
        final hostRoot =
            '${activeUri.scheme}://${activeUri.host}${activeUri.hasPort ? ':${activeUri.port}' : ''}';
        return '$hostRoot${deadUri.path}${deadUri.hasQuery ? '?${deadUri.query}' : ''}';
      } catch (_) {}
    }
    return trimmed;
  }
  try {
    final uri = Uri.parse(BASE_URL);
    final hostRoot =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    if (trimmed.startsWith('/')) {
      return '$hostRoot$trimmed';
    }
    return '$hostRoot/$trimmed';
  } catch (_) {
    return trimmed;
  }
}

const String USER_ID = "user_id";
const String IS_USER_LOGGED_IN = "IS_USER_LOGGED_IN";
const String USER_TOKEN = "TOKEN";
const String USER_ROLE_ID = "ROLE_ID";
const String USER_NAME = "user_name";
const String USER_EMAIL = "user_email";
const String USER_PASSWORD = "password";

const String USER_PHONE = "user_phone";
const String USER_GENDER = "user_gender";
const String USER_DOB = "user_dob";
const String USER_LOGIN = "login_true";
const String HIDEBUYNOW = "buy_now";
const String USER_OTP = "MY OTP";
const String REFERRAL_CODE = "referral_code";
const String PENDING_REFERRAL_CODE = "pending_referral_code";
const String INSTALL_REFERRER_CONSUMED = "install_referrer_consumed";
const String USER_REFRESH_TOKEN = "user_refresh_token";
const String APP_PACKAGE_NAME = "com.dream.alifbd";
const String FORGOTFIELD = "forgot-feild-data";

const String CUSTOMER_ORDER = "customer_order";

void SHOW_SNACKBAR({int? duration, String? message, bool? isSuccess}) {
  final snackbar = GetSnackBar(
    icon: Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      // child: Image(
      //   height: 50.h,
      //   width: 100.w,
      //   fit: BoxFit.contain,
      //   image: AssetImage(AppImage.logo),
      // ),
    ),
    backgroundColor: (isSuccess ?? true) ? AppColor.teal : AppColor.red,
    duration: Duration(milliseconds: duration ?? 2500),
    message: message ?? "No Message",
  );
  Get.showSnackbar(snackbar);
}

void showSnack(String title, String msg, {Color bg = AppColor.black}) {
  try {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  } catch (_) {}
  Get.snackbar(
    title,
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: bg,
    colorText: AppColor.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
    duration: const Duration(seconds: 3),
  );
}

// final snackbar
void showTopSnack(String msg, {bool isError = false}) {
  final context = Get.key.currentContext!;

  // Colors based on success or error
  final Color bgColor = isError ? AppColor.red.shade50 : AppColor.blue.shade50;
  final Color textColor = isError ? AppColor.red : AppColor.teal;
  final IconData icon = isError ? Icons.error : Icons.check_circle;

  ScaffoldMessenger.of(context).clearMaterialBanners();

  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      backgroundColor: bgColor,
      content: Text(
        msg,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Icon(icon, color: textColor),
      actions: const [SizedBox.shrink()],
    ),
  );

  Future.delayed(const Duration(seconds: 3), () {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).clearMaterialBanners();
  });
}
