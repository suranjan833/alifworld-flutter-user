import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/user_model.dart';
import '../../account/controllers/account_controller.dart';

class MyProfileController extends GetxController {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController dobController;

  final selectedGender = 'Male'.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  final userName = 'User'.obs;
  final userEmail = ''.obs;
  final userPhone = ''.obs;
  final userDob = ''.obs;

  DateTime? selectedDate;

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);
  }

  @override
  void onInit() {
    super.onInit();
    _loadCachedProfile();
    nameController = TextEditingController(text: userName.value);
    emailController = TextEditingController(text: userEmail.value);
    phoneController = TextEditingController(text: userPhone.value);
    dobController = TextEditingController(text: userDob.value);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasAuth) {
        fetchProfile();
      }
    });
  }

  void _loadCachedProfile() {
    final savedName = getBox.read(USER_NAME);
    if (savedName != null && savedName.toString().trim().isNotEmpty) {
      userName.value = savedName.toString().trim();
    }
    final savedEmail = getBox.read(USER_EMAIL);
    if (savedEmail != null && savedEmail.toString().trim().isNotEmpty) {
      userEmail.value = savedEmail.toString().trim();
    }
    final savedPhone = getBox.read(USER_PHONE);
    if (savedPhone != null && savedPhone.toString().trim().isNotEmpty) {
      userPhone.value = savedPhone.toString().trim();
    }
    final savedGender = getBox.read(USER_GENDER);
    if (savedGender != null && savedGender.toString().trim().isNotEmpty) {
      selectedGender.value = savedGender.toString().trim();
    }
    final savedDob = getBox.read(USER_DOB);
    if (savedDob != null && savedDob.toString().trim().isNotEmpty) {
      userDob.value = savedDob.toString().trim();
    }
  }

  /// 1. GET /auth/me - Fetch fresh profile from API
  Future<void> fetchProfile() async {
    if (!_hasAuth) return;

    isLoading.value = true;
    try {
      final response = await dioGet('auth/me');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData.containsKey('user')) {
          final userMap = Map<String, dynamic>.from(rawData['user']);
          final userModel = UserModel.fromJson(userMap);

          if (userModel.displayName.isNotEmpty) {
            userName.value = userModel.displayName;
            nameController.text = userModel.displayName;
            getBox.write(USER_NAME, userModel.displayName);
          }
          if (userModel.email != null && userModel.email!.isNotEmpty) {
            userEmail.value = userModel.email!;
            emailController.text = userModel.email!;
            getBox.write(USER_EMAIL, userModel.email!);
          }
          if (userModel.phone != null && userModel.phone!.isNotEmpty) {
            userPhone.value = userModel.phone!;
            phoneController.text = userModel.phone!;
            getBox.write(USER_PHONE, userModel.phone!);
          }
          if (userModel.id != null) {
            getBox.write(USER_ID, userModel.id!);
          }
          if (userModel.gender != null && userModel.gender!.isNotEmpty) {
            final g = userModel.gender!.toLowerCase();
            if (g == 'male') {
              selectedGender.value = 'Male';
            } else if (g == 'female') {
              selectedGender.value = 'Female';
            } else {
              selectedGender.value = 'Other';
            }
          }
          if (userModel.dateOfBirth != null &&
              userModel.dateOfBirth!.isNotEmpty) {
            try {
              final parsed = DateTime.parse(userModel.dateOfBirth!);
              selectedDate = parsed;
              final formattedDate =
                  "${parsed.day} ${_getMonthName(parsed.month)} ${parsed.year}";
              dobController.text = formattedDate;
              userDob.value = formattedDate;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.onClose();
  }

  void setGender(String gender) {
    selectedGender.value = gender;
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(1998, 6, 15),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: AppColor.black,
              onSurface: AppColor.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate = picked;
      final formattedDate =
          "${picked.day} ${_getMonthName(picked.month)} ${picked.year}";
      dobController.text = formattedDate;
      userDob.value = formattedDate;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// 2. PUT /auth/me - Update user profile
  Future<void> saveProfile() async {
    final enteredName = nameController.text.trim();
    if (enteredName.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your full name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    if (selectedDate != null && selectedDate!.isAfter(DateTime.now())) {
      Get.snackbar(
        'Invalid Date',
        'Date of birth cannot be in the future',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    isSaving.value = true;
    final nameParts = enteredName.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final dobIso = selectedDate != null
        ? "${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
        : null;

    if (_hasAuth) {
      try {
        final Map<String, dynamic> payload = {
          'firstName': firstName,
          'lastName': lastName,
          'gender': selectedGender.value.toLowerCase(),
        };
        if (email.isNotEmpty) {
          payload['email'] = email;
        }
        if (dobIso != null) {
          payload['dateOfBirth'] = dobIso;
        }

        final response = await dioPut(
          endUrl: 'auth/me',
          data: payload,
          isJson: true,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          userName.value = enteredName;
          userEmail.value = email;
          userPhone.value = phoneController.text.trim();

          getBox.write(USER_NAME, userName.value);
          if (email.isNotEmpty) getBox.write(USER_EMAIL, userEmail.value);
          if (userPhone.value.isNotEmpty) {
            getBox.write(USER_PHONE, userPhone.value);
          }
          if (dobIso != null) getBox.write(USER_DOB, dobController.text);
          getBox.write(USER_GENDER, selectedGender.value);

          // Synchronize with AccountController if registered
          if (Get.isRegistered<AccountController>()) {
            final accountCtrl = Get.find<AccountController>();
            accountCtrl.userName.value = userName.value;
            accountCtrl.userEmail.value = userEmail.value;
            accountCtrl.userPhone.value = userPhone.value;
            await accountCtrl.fetchUserProfile();
          }

          // Refresh fresh data from API
          await fetchProfile();

          Get.snackbar(
            'Success',
            'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.textPrimary,
            colorText: AppColor.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          String msg = 'Could not update profile';
          if (response.data is Map) {
            final data = response.data as Map;
            if (data['error'] is Map) {
              final code = data['error']['code']?.toString();
              final rawMsg = data['error']['message']?.toString();
              if (code == 'EMAIL_TAKEN') {
                msg = 'This email address is already registered to another account.';
              } else if (code == 'INVALID_DOB') {
                msg = 'Please provide a valid date of birth.';
              } else if (code == 'UNAUTHENTICATED') {
                msg = 'Your session has expired. Please log in again.';
              } else if (code == 'RATE_LIMITED') {
                msg = 'Too many requests. Please wait a moment and try again.';
              } else if (rawMsg != null && rawMsg.isNotEmpty) {
                msg = rawMsg;
              }
            } else if (data['message'] != null) {
              msg = data['message'].toString();
            }
          }
          Get.snackbar(
            'Update Failed',
            msg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Something went wrong. Please check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
      } finally {
        isSaving.value = false;
      }
    } else {
      isSaving.value = false;
      userName.value = enteredName;
      userEmail.value = email;
      userPhone.value = phoneController.text.trim();

      getBox.write(USER_NAME, userName.value);
      if (email.isNotEmpty) getBox.write(USER_EMAIL, userEmail.value);
      if (userPhone.value.isNotEmpty) getBox.write(USER_PHONE, userPhone.value);
      if (dobController.text.isNotEmpty) {
        getBox.write(USER_DOB, dobController.text);
      }
      getBox.write(USER_GENDER, selectedGender.value);

      if (Get.isRegistered<AccountController>()) {
        final accountCtrl = Get.find<AccountController>();
        accountCtrl.userName.value = userName.value;
        accountCtrl.userEmail.value = userEmail.value;
        accountCtrl.userPhone.value = userPhone.value;
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.textPrimary,
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
