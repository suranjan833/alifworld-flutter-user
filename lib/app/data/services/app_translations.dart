import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../../modules/account/controllers/account_controller.dart';

class AppTranslations extends Translations {
  static const Map<String, String> en = {
    "app_title": "ALIF",
    "my_account": "My account",
    "manage": "Manage",
    "settings": "Settings",
    "others": "Others",
    "my_profile": "My Profile",
    "my_orders": "My Orders",
    "manage_addresses": "Manage addresses",
    "my_transactions": "My transactions",
    "my_wishlist": "My Wishlist",
    "wallet": "Wallet",
    "shopping_list": "Shopping List",
    "refer_and_earn": "Refer and Earn",
    "account_settings": "Account settings",
    "notifications": "Notifications",
    "support": "Support",
    "language": "Language",
    "about_us": "About us",
    "terms_and_conditions": "Terms & Condition",
    "privacy_policy": "Privacy Policy",
    "refund_policy": "Refund Policy",
    "shipping_policy": "Shipping Policy",
    "logout": "Logout",
    "cancel": "Cancel",
    "save_changes": "Save Changes",
    "select_language": "Select Language",
    "english": "English",
    "bangla": "Bangla (বাংলা)",
    "current_language": "Current Language: English",

    // Navigation
    "nav_home": "Home",
    "nav_categories": "Categories",
    "nav_discover": "Discover",
    "nav_bag": "Bag",
    "nav_account": "Account",

    // Auth & Login
    "welcome_back": "Welcome Back!",
    "login_otp_subtitle": "Enter your phone number to receive an OTP.",
    "login_password_subtitle": "Sign in with your phone number and password.",
    "phone_number": "Phone Number",
    "enter_phone_hint": "Enter phone number (e.g. 01XXXXXXXXX)",
    "please_enter_phone": "Please enter your phone number",
    "phone_max_length": "Phone number cannot exceed 11 digits",
    "please_enter_valid_phone": "Please enter a valid 11-digit phone number",
    "password": "Password",
    "enter_password_hint": "Enter password",
    "please_enter_password": "Please enter your password",
    "edit_number": "Edit Number",
    "otp_code": "OTP Code",
    "enter_otp_hint": "Enter OTP code",
    "enter_6_digit_otp": "Enter 6-digit verification code",
    "resend_otp": "Resend OTP",
    "sign_in": "Sign In",
    "verify_and_sign_in": "Verify & Sign In",
    "verify_phone": "Verify Phone",
    "login_with_password": "Login with Password instead",
    "login_with_otp": "Login with OTP",
    "dont_have_account": "Don't have an account? ",
    "sign_up": "Sign Up",
    "login_failed": "Login Failed",
    "login_error": "Login Error",
    "something_went_wrong": "Something went wrong. Please try again.",
    "invalid_phone": "Invalid Phone",
    "otp_sent": "OTP Sent",
    "otp_error": "OTP Error",
    "invalid_otp": "Invalid OTP",
    "enter_valid_otp": "Please enter a valid OTP code",

    // Signup
    "create_account": "Create Account",
    "signup_subtitle": "Sign up to start shopping on Alifworld",
    "full_name": "Full Name",
    "enter_full_name": "Enter your full name",
    "already_have_account": "Already have an account? ",
    "referral_code": "Referral Code (Optional)",
    "enter_referral_code": "Enter referral code",

    // General
    "wallet_pin_settings": "Wallet PIN Settings",
    "search_hint": "Search products, brands and categories...",
    "view_all": "View All",
  };

  static const Map<String, String> bn = {
    "app_title": "আলিফ",
    "my_account": "আমার অ্যাকাউন্ট",
    "manage": "ব্যবস্থাপনা",
    "settings": "সেটিংস",
    "others": "অন্যান্য",
    "my_profile": "আমার প্রোফাইল",
    "my_orders": "আমার অর্ডারসমূহ",
    "manage_addresses": "ঠিকানা পরিচালনা",
    "my_transactions": "আমার লেনদেন",
    "my_wishlist": "আমার উইশলিস্ট",
    "wallet": "ওয়ালেট",
    "shopping_list": "কেনাকাটার তালিকা",
    "refer_and_earn": "রেফার এবং ইনকাম",
    "account_settings": "অ্যাকাউন্ট সেটিংস",
    "notifications": "বিজ্ঞপ্তি",
    "support": "সাহায্য ও সাপোর্ট",
    "language": "ভাষা",
    "about_us": "আমাদের সম্পর্কে",
    "terms_and_conditions": "শর্তাবলী",
    "privacy_policy": "গোপনীয়তা নীতি",
    "refund_policy": "রিফান্ড নীতি",
    "shipping_policy": "শিপিং নীতি",
    "logout": "লগআউট",
    "cancel": "বাতিল",
    "save_changes": "পরিবর্তন সংরক্ষণ করুন",
    "select_language": "ভাষা নির্বাচন করুন",
    "english": "ইংরেজি (English)",
    "bangla": "বাংলা (Bangla)",
    "current_language": "বর্তমান ভাষা: বাংলা",

    // Navigation
    "nav_home": "হোম",
    "nav_categories": "ক্যাটাগরি",
    "nav_discover": "ডিসকভার",
    "nav_bag": "ব্যাগ",
    "nav_account": "অ্যাকাউন্ট",

    // Auth & Login
    "welcome_back": "স্বাগতম!",
    "login_otp_subtitle": "ওটিপি পেতে আপনার ফোন নম্বর লিখুন।",
    "login_password_subtitle": "আপনার ফোন নম্বর ও পাসওয়ার্ড দিয়ে সাইন ইন করুন।",
    "phone_number": "ফোন নম্বর",
    "enter_phone_hint": "ফোন নম্বর লিখুন (যেমন: 01XXXXXXXXX)",
    "please_enter_phone": "অনুগ্রহ করে আপনার ফোন নম্বর লিখুন",
    "phone_max_length": "ফোন নম্বর ১১ ডিজিটের বেশি হতে পারবে না",
    "please_enter_valid_phone": "সঠিক ১১ ডিজিটের ফোন নম্বর লিখুন",
    "password": "পাসওয়ার্ড",
    "enter_password_hint": "পাসওয়ার্ড লিখুন",
    "please_enter_password": "অনুগ্রহ করে আপনার পাসওয়ার্ড লিখুন",
    "edit_number": "নম্বর পরিবর্তন",
    "otp_code": "ওটিপি কোড",
    "enter_otp_hint": "ওটিপি কোড লিখুন",
    "enter_6_digit_otp": "৬ ডিজিটের ভেরিফিকেশন কোড লিখুন",
    "resend_otp": "আবার ওটিপি পাঠান",
    "sign_in": "সাইন ইন",
    "verify_and_sign_in": "যাচাই ও সাইন ইন",
    "verify_phone": "ফোন যাচাই করুন",
    "login_with_password": "পাসওয়ার্ড দিয়ে লগইন করুন",
    "login_with_otp": "ওটিপি দিয়ে লগইন করুন",
    "dont_have_account": "কোনো অ্যাকাউন্ট নেই? ",
    "sign_up": "নিবন্ধন করুন",
    "login_failed": "লগইন ব্যর্থ হয়েছে",
    "login_error": "লগইন ত্রুটি",
    "something_went_wrong": "কিছু ভুল হয়েছে। আবার চেষ্টা করুন।",
    "invalid_phone": "ভুল ফোন নম্বর",
    "otp_sent": "ওটিপি পাঠানো হয়েছে",
    "otp_error": "ওটিপি ত্রুটি",
    "invalid_otp": "ভুল ওটিপি",
    "enter_valid_otp": "অনুগ্রহ করে সঠিক ওটিপি কোড লিখুন",

    // Signup
    "create_account": "নতুন অ্যাকাউন্ট তৈরি করুন",
    "signup_subtitle": "আলিমওয়ার্ল্ডে কেনাকাটা শুরু করতে নিবন্ধন করুন",
    "full_name": "পুরো নাম",
    "enter_full_name": "আপনার পুরো নাম লিখুন",
    "already_have_account": "ইতিমধ্যে অ্যাকাউন্ট আছে? ",
    "referral_code": "রেফারেল কোড (ঐচ্ছিক)",
    "enter_referral_code": "রেফারেল কোড লিখুন",

    // General
    "wallet_pin_settings": "ওয়ালেট পিন সেটিংস",
    "search_hint": "পণ্য, ব্র্যান্ড ও ক্যাটাগরি অনুসন্ধান করুন...",
    "view_all": "সবগুলো দেখুন",
  };

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'en': en,
        'bn_BD': bn,
        'bn': bn,
      };

  static String get currentLanguageCode {
    try {
      final saved = getBox.read('app_language');
      if (saved == 'bn') return 'bn';
    } catch (_) {}
    return 'en';
  }

  static Locale get currentLocale {
    return currentLanguageCode == 'bn'
        ? const Locale('bn', 'BD')
        : const Locale('en', 'US');
  }

  static void changeLanguage(String languageCode) {
    try {
      getBox.write('app_language', languageCode);
    } catch (_) {}

    if (Get.isRegistered<AccountController>()) {
      final acc = Get.find<AccountController>();
      acc.currentLangCode.value = languageCode;
      acc.currentLanguage.value =
          languageCode == 'bn' ? 'Bangla (বাংলা)' : 'English';
      acc.update();
    }

    if (languageCode == 'bn') {
      Get.updateLocale(const Locale('bn', 'BD'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  /// Show standard bottom sheet for language selection
  static void openLanguageSelectionSheet({BuildContext? context}) {
    final currentCode = currentLanguageCode.obs;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'select_language'.tr,
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => Column(
                children: [
                  _buildLanguageOption(
                    code: 'en',
                    title: 'english'.tr,
                    isSelected: currentCode.value == 'en',
                    onTap: () {
                      currentCode.value = 'en';
                      changeLanguage('en');
                      Get.back();
                    },
                  ),
                  SizedBox(height: 10.h),
                  _buildLanguageOption(
                    code: 'bn',
                    title: 'bangla'.tr,
                    isSelected: currentCode.value == 'bn',
                    onTap: () {
                      currentCode.value = 'bn';
                      changeLanguage('bn');
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildLanguageOption({
    required String code,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? AppColor.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: 0.15)
                      : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    code == 'bn' ? 'বা' : 'EN',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColor.primaryDark : AppColor.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColor.primaryDark : AppColor.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Iconsax.tick_circle5,
                  color: AppColor.primary,
                  size: 20.r,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
