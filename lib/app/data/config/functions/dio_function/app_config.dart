// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

final getBox = GetStorage();
var BASE_URL = "https://alifworld.vercel.app/api/v1/";
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
const String FORGOTFIELD = "forgot-feild-data";

const String CUSTOMER_ORDER = "customer_order";

var isDebugMode = true.obs;

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
    backgroundColor: (isSuccess ?? true) ? Colors.teal : Colors.red,
    duration: Duration(milliseconds: duration ?? 2500),
    message: message ?? "No Message",
  );
  Get.showSnackbar(snackbar);
}

void showSnack(String title, String msg, {Color bg = Colors.black}) {
  Get.showSnackbar(
    GetSnackBar(
      title: title,
      message: msg,
      duration: const Duration(seconds: 2),
      backgroundColor: bg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    ),
  );
}

// final snackbar
void showTopSnack(String msg, {bool isError = false}) {
  final context = Get.key.currentContext!;

  // Colors based on success or error
  final Color bgColor = isError ? Colors.red.shade50 : Colors.blue.shade50;
  final Color textColor = isError ? Colors.red : Colors.teal;
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
