import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/country_model.dart';
import '../../../routes/app_pages.dart';
import '../../../data/config/app_color.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final referralCodeController = TextEditingController();

  // Verification controllers & states
  final phoneOtpController = TextEditingController();
  final emailOtpController = TextEditingController();

  final isPhoneOtpSent = false.obs;
  final isPhoneVerified = false.obs;
  final isSendingPhoneOtp = false.obs;
  final isVerifyingPhoneOtp = false.obs;
  final regToken = ''.obs;

  final isEmailOtpSent = false.obs;
  final isEmailVerified = false.obs;
  final isSendingEmailOtp = false.obs;
  final isVerifyingEmailOtp = false.obs;
  final emailToken = ''.obs;

  // Track whether user has entered phone & email
  final hasEmailInput = false.obs;
  final hasPhoneInput = false.obs;

  final selectedCountry = CountryModel.defaultCountries.first.obs; // Bangladesh (+880)
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  String _initialVerifiedPhone = '';

  @override
  void onInit() {
    super.onInit();
    _handleIncomingArguments();
    emailController.addListener(_onEmailChanged);
    phoneController.addListener(_onPhoneChanged);
  }

  @override
  void onReady() {
    super.onReady();
    _handleIncomingArguments();
  }

  void _handleIncomingArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final phone = args['phone']?.toString() ?? '';
      final token = args['regToken']?.toString() ?? '';
      final country = args['country'];

      if (country is CountryModel) {
        selectedCountry.value = country;
      }

      if (phone.isNotEmpty) {
        _initialVerifiedPhone = phone;
        if (phoneController.text != phone) {
          phoneController.text = phone;
        }
        hasPhoneInput.value = true;
      }

      if (token.isNotEmpty) {
        regToken.value = token;
        isPhoneVerified.value = true;
        isPhoneOtpSent.value = true;
      }
    }
  }

  void _onEmailChanged() {
    final text = emailController.text.trim();
    final hasInput = text.isNotEmpty;
    if (hasEmailInput.value != hasInput) {
      hasEmailInput.value = hasInput;
    }
    // If email changes after verification, reset state
    if (isEmailVerified.value) {
      isEmailVerified.value = false;
      isEmailOtpSent.value = false;
      emailToken.value = '';
    }
  }

  void _onPhoneChanged() {
    final text = phoneController.text.trim();
    final hasInput = text.isNotEmpty;
    if (hasPhoneInput.value != hasInput) {
      hasPhoneInput.value = hasInput;
    }
    // If phone changes after verification, reset state
    if (isPhoneVerified.value &&
        _initialVerifiedPhone.isNotEmpty &&
        text != _initialVerifiedPhone) {
      isPhoneVerified.value = false;
      isPhoneOtpSent.value = false;
      regToken.value = '';
      _initialVerifiedPhone = '';
    } else if (isPhoneVerified.value && _initialVerifiedPhone.isEmpty) {
      isPhoneVerified.value = false;
      isPhoneOtpSent.value = false;
      regToken.value = '';
    }
  }

  @override
  void onClose() {
    emailController.removeListener(_onEmailChanged);
    phoneController.removeListener(_onPhoneChanged);
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralCodeController.dispose();
    phoneOtpController.dispose();
    emailOtpController.dispose();
    super.onClose();
  }

  void selectCountry(CountryModel country) {
    if (selectedCountry.value.dialCode != country.dialCode) {
      selectedCountry.value = country;
      if (isPhoneVerified.value) {
        isPhoneVerified.value = false;
        isPhoneOtpSent.value = false;
        regToken.value = '';
        _initialVerifiedPhone = '';
      }
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final cleanDigits = value.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length < 10 || cleanDigits.length > 15) {
      return 'Please enter a valid phone number (at least 10 digits)';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String get serverPhoneNumber {
    String clean = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final dialDigits = selectedCountry.value.dialCode.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith(dialDigits)) {
      clean = clean.substring(dialDigits.length);
    }
    while (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '${selectedCountry.value.dialCode}$clean';
  }

  /// 1. Request Phone OTP (POST /auth/otp/request)
  Future<void> sendPhoneOtp() async {
    final error = validatePhone(phoneController.text);
    if (error != null) {
      showSnack('Invalid Phone', error, bg: AppColor.red);
      return;
    }

    final serverPhone = serverPhoneNumber;


    isSendingPhoneOtp.value = true;
    try {
      final response = await dioPost(
        endUrl: 'auth/otp/request',
        data: {
          'phone': serverPhone,
          'purpose': 'register',
        },
        isJson: true,
      );

      isSendingPhoneOtp.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        isPhoneOtpSent.value = true;

        String? devCode;
        if (response.data is Map<String, dynamic>) {
          final resData = response.data as Map<String, dynamic>;
          final payload = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : resData;
          devCode = payload['devCode']?.toString();
        }

        if (devCode != null && devCode.isNotEmpty) {
          phoneOtpController.text = devCode;
        }

        showSnack(
          'OTP Sent',
          devCode != null
              ? 'Verification code ($devCode) copied to OTP section.'
              : 'Verification code sent to ${phoneController.text.trim()}',
          bg: AppColor.black87,
        );
      } else {
        String msg = 'Failed to send phone OTP.';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        } else if (response.data is Map &&
            response.data['error'] is Map &&
            response.data['error']['message'] != null) {
          msg = response.data['error']['message'].toString();
        }
        showSnack('Phone OTP Error', msg, bg: AppColor.red);
      }
    } catch (_) {
      isSendingPhoneOtp.value = false;
      showSnack('Error', 'Could not send phone OTP. Try again.', bg: AppColor.red);
    }
  }

  /// 2. Verify Phone OTP (POST /auth/otp/verify)
  Future<void> verifyPhoneOtp() async {
    final code = phoneOtpController.text.trim();
    if (code.length < 4) {
      showSnack('Invalid OTP', 'Please enter a valid OTP code', bg: AppColor.red);
      return;
    }

    final serverPhone = serverPhoneNumber;


    isVerifyingPhoneOtp.value = true;
    try {
      final response = await dioPost(
        endUrl: 'auth/otp/verify',
        data: {
          'phone': serverPhone,
          'purpose': 'register',
          'code': code,
        },
        isJson: true,
      );

      isVerifyingPhoneOtp.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic dataMap = response.data;
        if (dataMap is Map<String, dynamic> && dataMap.containsKey('data')) {
          dataMap = dataMap['data'];
        }
        if (dataMap is Map<String, dynamic>) {
          regToken.value = dataMap['regToken']?.toString() ??
              dataMap['token']?.toString() ??
              dataMap['accessToken']?.toString() ??
              'verified';
        } else {
          regToken.value = 'verified';
        }
        _initialVerifiedPhone = phoneController.text.trim();
        isPhoneVerified.value = true;
        showSnack('Phone Verified', 'Phone number verified successfully!', bg: AppColor.green);
      } else {
        String msg = 'Invalid phone verification code.';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        } else if (response.data is Map &&
            response.data['error'] is Map &&
            response.data['error']['message'] != null) {
          msg = response.data['error']['message'].toString();
        }
        showSnack('Verification Failed', msg, bg: AppColor.red);
      }
    } catch (_) {
      isVerifyingPhoneOtp.value = false;
      showSnack('Error', 'Could not verify phone OTP. Try again.', bg: AppColor.red);
    }
  }

  /// 3. Request Email OTP (POST /auth/email-otp/request)
  Future<void> sendEmailOtp() async {
    final error = validateEmail(emailController.text);
    if (error != null) {
      showSnack('Invalid Email', error, bg: AppColor.red);
      return;
    }

    final email = emailController.text.trim();
    isSendingEmailOtp.value = true;
    try {
      final response = await dioPost(
        endUrl: 'auth/email-otp/request',
        data: {'email': email},
        isJson: true,
      );

      isSendingEmailOtp.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        isEmailOtpSent.value = true;

        String? devCode;
        if (response.data is Map<String, dynamic>) {
          final resData = response.data as Map<String, dynamic>;
          final payload = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : resData;
          devCode = payload['devCode']?.toString();
        }

        if (devCode != null && devCode.isNotEmpty) {
          emailOtpController.text = devCode;
        }

        showSnack(
          'OTP Sent',
          devCode != null
              ? 'Verification code ($devCode) copied to OTP section.'
              : 'Verification code sent to $email',
          bg: AppColor.black87,
        );
      } else {
        String msg = 'Failed to send email OTP.';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        } else if (response.data is Map &&
            response.data['error'] is Map &&
            response.data['error']['message'] != null) {
          msg = response.data['error']['message'].toString();
        }
        showSnack('Email OTP Error', msg, bg: AppColor.red);
      }
    } catch (_) {
      isSendingEmailOtp.value = false;
      showSnack('Error', 'Could not send email OTP. Try again.', bg: AppColor.red);
    }
  }

  /// 4. Verify Email OTP (POST /auth/email-otp/verify)
  Future<void> verifyEmailOtp() async {
    final code = emailOtpController.text.trim();
    if (code.length < 4) {
      showSnack('Invalid OTP', 'Please enter a valid OTP code', bg: AppColor.red);
      return;
    }

    final email = emailController.text.trim();
    isVerifyingEmailOtp.value = true;
    try {
      final response = await dioPost(
        endUrl: 'auth/email-otp/verify',
        data: {
          'email': email,
          'code': code,
        },
        isJson: true,
      );

      isVerifyingEmailOtp.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic dataMap = response.data;
        if (dataMap is Map<String, dynamic> && dataMap.containsKey('data')) {
          dataMap = dataMap['data'];
        }
        if (dataMap is Map<String, dynamic>) {
          emailToken.value = dataMap['emailToken']?.toString() ??
              dataMap['token']?.toString() ??
              dataMap['accessToken']?.toString() ??
              'verified';
        } else {
          emailToken.value = 'verified';
        }
        isEmailVerified.value = true;
        showSnack('Email Verified', 'Email address verified successfully!', bg: AppColor.green);
      } else {
        String msg = 'Invalid email verification code.';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        } else if (response.data is Map &&
            response.data['error'] is Map &&
            response.data['error']['message'] != null) {
          msg = response.data['error']['message'].toString();
        }
        showSnack('Verification Failed', msg, bg: AppColor.red);
      }
    } catch (_) {
      isVerifyingEmailOtp.value = false;
      showSnack('Error', 'Could not verify email OTP. Try again.', bg: AppColor.red);
    }
  }

  /// 5. Complete Registration (POST /auth/register/complete)
  void signup() async {
    if (formKey.currentState?.validate() ?? false) {
      if (!isPhoneVerified.value) {
        showSnack(
          'Phone Not Verified',
          'Please verify your phone number via OTP before completing signup.',
          bg: AppColor.red,
        );
        return;
      }

      if (!isEmailVerified.value) {
        showSnack(
          'Email Not Verified',
          'Please verify your email address via OTP before completing signup.',
          bg: AppColor.red,
        );
        return;
      }

      isLoading.value = true;

      final nameParts = nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : firstName;

      try {
        final response = await dioPost(
          endUrl: 'auth/register/complete',
          data: {
            'regToken': regToken.value,
            if (emailToken.value.isNotEmpty) 'emailToken': emailToken.value,
            'firstName': firstName,
            'lastName': lastName,
            'email': emailController.text.trim(),
            'password': passwordController.text,
            if (referralCodeController.text.trim().isNotEmpty)
              'referralCode': referralCodeController.text.trim(),
          },
          isJson: true,
        );

        isLoading.value = false;

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data is Map<String, dynamic>) {
            final dataMap = response.data as Map<String, dynamic>;
            final payload = dataMap['data'] ?? dataMap;
            if (payload is Map<String, dynamic>) {
              final token = payload['token'] ??
                  payload['accessToken'] ??
                  payload['authtoken'];
              if (token != null) {
                getBox.write(USER_TOKEN, token.toString());
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
            }
          }
          showSnack(
            'Account Created',
            'Welcome, ${nameController.text.trim()}! Account created successfully.',
            bg: AppColor.black87,
          );
          Get.offAllNamed(Routes.MAIN_NAVIGATION);
        } else {
          String msg = 'Could not create account. Please try again.';
          if (response.data is Map && response.data['message'] != null) {
            msg = response.data['message'].toString();
          } else if (response.data is Map &&
              response.data['error'] is Map &&
              response.data['error']['message'] != null) {
            msg = response.data['error']['message'].toString();
          }
          showSnack('Registration Failed', msg, bg: AppColor.red);
        }
      } catch (e) {
        isLoading.value = false;
        showSnack(
          'Registration Error',
          'Something went wrong. Please try again.',
          bg: AppColor.red,
        );
      }
    }
  }

  void goToLogin() {
    Get.back();
  }
}
