import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/config/app_color.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/country_model.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Login Mode: true = OTP Login (default), false = Password Login
  final isOtpLogin = true.obs;
  final isPasswordVisible = false.obs;
  final isOtpSent = false.obs;
  final isLoading = false.obs;

  // Controllers for Password Login
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  // Controllers for OTP Login
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final selectedCountry =
      CountryModel.defaultCountries.first.obs; // Default Bangladesh +880
  final phoneError = RxnString();
  final hasPhoneInput = false.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_onPhoneChanged);
    _checkExistingSession();
  }

  void _checkExistingSession() {
    final token = getBox.read(USER_TOKEN);
    final hasToken = token != null && token.toString().trim().isNotEmpty;
    final loggedInVal = getBox.read(IS_USER_LOGGED_IN);
    final isLoggedIn =
        (loggedInVal == true || loggedInVal == 'true' || hasToken);
    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(Routes.MAIN_NAVIGATION);
      });
    }
  }

  void _onPhoneChanged() {
    final hasInput = phoneController.text.trim().isNotEmpty;
    if (hasPhoneInput.value != hasInput) {
      hasPhoneInput.value = hasInput;
    }
  }

  @override
  void onClose() {
    phoneController.removeListener(_onPhoneChanged);
    identifierController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }

  void toggleLoginMode() {
    isOtpLogin.value = !isOtpLogin.value;
    isOtpSent.value = false;
    otpController.clear();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void selectCountry(CountryModel country) {
    selectedCountry.value = country;
    validatePhone();
  }

  String? validatePhoneInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final cleanDigits = value.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    return null;
  }

  void validatePhone() {
    phoneError.value = validatePhoneInput(phoneController.text);
  }

  String get serverPhoneNumber {
    String clean = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '${selectedCountry.value.dialCode}$clean';
  }

  String get normalizedIdentifier {
    final raw = identifierController.text.trim();
    final cleanDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length == 11 && cleanDigits.startsWith('0')) {
      return cleanDigits.substring(1);
    }
    return raw;
  }

  /// Combined login trigger called by Submit button
  void login() {
    if (isOtpLogin.value) {
      if (isOtpSent.value) {
        verifyOtp();
      } else {
        requestOtp();
      }
    } else {
      loginWithPassword();
    }
  }

  /// 1. Password Login (POST /auth/login)
  Future<void> loginWithPassword() async {
    if (formKey.currentState?.validate() ?? false) {
      isLoading.value = true;
      try {
        final response = await dioPost(
          endUrl: 'auth/login',
          data: {
            'identifier': normalizedIdentifier,
            'password': passwordController.text,
          },
          isJson: true,
        );

        isLoading.value = false;

        if (response.statusCode == 200 || response.statusCode == 201) {
          _handleAuthSuccess(response.data);
        } else {
          String msg = 'Invalid credentials. Please try again.';
          if (response.data is Map && response.data['message'] != null) {
            msg = response.data['message'].toString();
          } else if (response.data is Map &&
              response.data['error'] is Map &&
              response.data['error']['message'] != null) {
            msg = response.data['error']['message'].toString();
          }
          showSnack('Login Failed', msg, bg: AppColor.red);
        }
      } catch (e) {
        isLoading.value = false;
        showSnack(
          'Login Error',
          'Something went wrong. Please try again.',
          bg: AppColor.red,
        );
      }
    }
  }

  /// 2. Request OTP (POST /auth/otp/request)
  Future<void> requestOtp() async {
    final error = validatePhoneInput(phoneController.text);
    phoneError.value = error;
    if (error != null) {
      showSnack('Invalid Phone', error, bg: AppColor.red);
      return;
    }

    if (formKey.currentState?.validate() ?? false) {
      isLoading.value = true;

      final serverPhone = serverPhoneNumber;


      try {
        final response = await dioPost(
          endUrl: 'auth/otp/request',
          data: {'phone': serverPhone, 'purpose': 'login'},
          isJson: true,
        );

        isLoading.value = false;

        if (response.statusCode == 200 || response.statusCode == 201) {
          isOtpSent.value = true;

          String? devCode;
          if (response.data is Map<String, dynamic>) {
            final resData = response.data as Map<String, dynamic>;
            final payload = resData['data'] is Map<String, dynamic>
                ? resData['data'] as Map<String, dynamic>
                : resData;
            devCode = payload['devCode']?.toString();
          }

          if (devCode != null && devCode.isNotEmpty) {
            otpController.text = devCode;
          }

          showSnack(
            'OTP Sent',
            devCode != null
                ? 'Verification code ($devCode) copied to OTP section.'
                : 'An OTP has been sent to ${phoneController.text.trim()}',
            bg: AppColor.black87,
          );
        } else {
          String msg = 'Unable to send OTP. Please try again.';
          if (response.data is Map && response.data['message'] != null) {
            msg = response.data['message'].toString();
          }
          showSnack('OTP Error', msg, bg: AppColor.red);
        }
      } catch (e) {
        isLoading.value = false;
        showSnack(
          'OTP Error',
          'Something went wrong. Please try again.',
          bg: AppColor.red,
        );
      }
    }
  }

  /// 3. Verify OTP (POST /auth/otp/verify)
  Future<void> verifyOtp() async {
    if (otpController.text.trim().length < 4) {
      showSnack('Invalid OTP', 'Please enter a valid OTP code', bg: AppColor.red);
      return;
    }

    isLoading.value = true;
    final serverPhone = serverPhoneNumber;


    try {
      final response = await dioPost(
        endUrl: 'auth/otp/verify',
        data: {
          'phone': serverPhone,
          'code': otpController.text.trim(),
          'purpose': 'login',
        },
        isJson: true,
      );

      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic dataMap = response.data;
        if (dataMap is Map<String, dynamic> && dataMap.containsKey('data')) {
          dataMap = dataMap['data'];
        }

        final bool isLoggedIn =
            dataMap is Map<String, dynamic> &&
            (dataMap['loggedIn'] == true ||
                dataMap['loggedIn'] == 'true' ||
                dataMap['token'] != null ||
                dataMap['accessToken'] != null);

        final String? regToken = dataMap is Map<String, dynamic>
            ? dataMap['regToken']?.toString()
            : null;

        // If user is not yet registered (loggedIn: false and regToken present)
        if (!isLoggedIn && regToken != null && regToken.isNotEmpty) {
          // 1. Save verified phone number and regToken in storage
          getBox.write(USER_PHONE, phoneController.text.trim());
          getBox.write('reg_token', regToken);

          showSnack(
            'Phone Verified',
            'Phone verified successfully! Please complete your registration.',
            bg: AppColor.black87,
          );

          // 2. Redirect user to Sign Up page with verified phone and regToken
          Get.toNamed(
            Routes.SIGNUP,
            arguments: {
              'phone': phoneController.text.trim(),
              'fullPhoneNumber': phoneController.text.trim(),
              'country': selectedCountry.value,
              'dialCode': selectedCountry.value.dialCode,
              'regToken': regToken,
            },
          );
        } else {
          _handleAuthSuccess(response.data);
        }
      } else {
        String msg = 'Invalid OTP code. Please try again.';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        }
        showSnack('Verification Failed', msg, bg: AppColor.red);
      }
    } catch (e) {
      isLoading.value = false;
      showSnack(
        'Verification Error',
        'Something went wrong. Please try again.',
        bg: AppColor.red,
      );
    }
  }

  void _handleAuthSuccess(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final payload = responseData['data'] ?? responseData;
      if (payload is Map<String, dynamic>) {
        final token =
            payload['token'] ?? payload['accessToken'] ?? payload['authtoken'];
        if (token != null && token.toString().trim().isNotEmpty) {
          getBox.write(USER_TOKEN, token.toString().trim());
          getBox.write(IS_USER_LOGGED_IN, true);
        } else {
          getBox.write(IS_USER_LOGGED_IN, true);
        }
        final user = payload['user'];
        if (user is Map<String, dynamic>) {
          if (user['id'] != null) {
            getBox.write(USER_ID, user['id'].toString());
          }
          if (user['name'] != null) {
            getBox.write(USER_NAME, user['name'].toString());
          }
          if (user['email'] != null) {
            getBox.write(USER_EMAIL, user['email'].toString());
          }
          if (user['phone'] != null) {
            getBox.write(USER_PHONE, user['phone'].toString());
          }
        }
      } else {
        getBox.write(IS_USER_LOGGED_IN, true);
      }
    } else {
      getBox.write(IS_USER_LOGGED_IN, true);
    }

    showSnack('Success', 'Logged in successfully!', bg: AppColor.black87);
    Get.offAllNamed(Routes.MAIN_NAVIGATION);
  }

  void goToSignup() {
    Get.toNamed(Routes.SIGNUP);
  }
}
