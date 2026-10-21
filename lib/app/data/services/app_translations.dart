import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    "refer_and_earn": "র��ফার এবং ইনকাম",
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
  };

  @override
  Map<String, Map<String, String>> get keys => {'en_US': en, 'bn_BD': bn};

  static void changeLanguage(String languageCode) {
    if (languageCode == 'bn') {
      Get.updateLocale(const Locale('bn', 'BD'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }
}
