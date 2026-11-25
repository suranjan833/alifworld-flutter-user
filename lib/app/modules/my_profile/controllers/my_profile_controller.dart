import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_pages.dart';
import '../../account/controllers/account_controller.dart';
import '../views/widgets/profile_confirm_dialog.dart';

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

  final isNameLocked = false.obs;
  final isEmailLocked = false.obs;
  final isDobLocked = false.obs;
  final isGenderLocked = false.obs;
  final isProfileDone = false.obs;

  DateTime? selectedDate;

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
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
      if (!_hasAuth) {
        Get.offNamed(Routes.LOGIN);
        return;
      }
      fetchProfile();
    });
  }

  void _loadCachedProfile() {
    final savedName = getBox.read(USER_NAME);
    if (savedName != null && savedName.toString().trim().isNotEmpty) {
      final n = savedName.toString().trim();
      userName.value = n;
      if (n.toLowerCase() != 'user') isNameLocked.value = true;
    }
    final savedEmail = getBox.read(USER_EMAIL);
    if (savedEmail != null && savedEmail.toString().trim().isNotEmpty) {
      final em = savedEmail.toString().trim();
      userEmail.value = em;
      if (em.contains('@')) isEmailLocked.value = true;
    }
    final savedPhone = getBox.read(USER_PHONE);
    if (savedPhone != null && savedPhone.toString().trim().isNotEmpty) {
      userPhone.value = savedPhone.toString().trim();
    }
    final savedGender = getBox.read(USER_GENDER);
    if (savedGender != null && savedGender.toString().trim().isNotEmpty) {
      selectedGender.value = savedGender.toString().trim();
      isGenderLocked.value = true;
    }
    final savedDob = getBox.read(USER_DOB);
    if (savedDob != null && savedDob.toString().trim().isNotEmpty) {
      userDob.value = savedDob.toString().trim();
      isDobLocked.value = true;
    }
    _updateProfileDoneState();
  }

  void _updateProfileDoneState() {
    isProfileDone.value = isNameLocked.value &&
        isEmailLocked.value &&
        isDobLocked.value &&
        isGenderLocked.value;
  }

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
        Map<String, dynamic>? userMap;
        if (rawData is Map && rawData.containsKey('user')) {
          userMap = Map<String, dynamic>.from(rawData['user']);
        } else if (rawData is Map<String, dynamic> &&
            (rawData.containsKey('id') || rawData.containsKey('phone'))) {
          userMap = rawData;
        }

        if (userMap != null) {
          final userModel = UserModel.fromJson(userMap);

          if (userModel.displayName.isNotEmpty) {
            userName.value = userModel.displayName;
            nameController.text = userModel.displayName;
            getBox.write(USER_NAME, userModel.displayName);
            if (userModel.displayName.toLowerCase() != 'user') {
              isNameLocked.value = true;
            }
          }
          if (userModel.email != null && userModel.email!.isNotEmpty) {
            userEmail.value = userModel.email!;
            emailController.text = userModel.email!;
            getBox.write(USER_EMAIL, userModel.email!);
            if (userModel.email!.contains('@')) {
              isEmailLocked.value = true;
            }
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
            isGenderLocked.value = true;
            getBox.write(USER_GENDER, selectedGender.value);
          }
          if (userModel.dateOfBirth != null &&
              userModel.dateOfBirth!.isNotEmpty) {
            isDobLocked.value = true;
            try {
              final parsed = DateTime.parse(userModel.dateOfBirth!);
              selectedDate = parsed;
              final formattedDate =
                  "${parsed.day} ${_getMonthName(parsed.month)} ${parsed.year}";
              dobController.text = formattedDate;
              userDob.value = formattedDate;
              getBox.write(USER_DOB, formattedDate);
            } catch (_) {
              dobController.text = userModel.dateOfBirth!;
              userDob.value = userModel.dateOfBirth!;
              getBox.write(USER_DOB, userModel.dateOfBirth!);
            }
          }
          _updateProfileDoneState();
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
    if (isGenderLocked.value) return;
    selectedGender.value = gender;
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    if (isDobLocked.value) return;
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Future<void> onSavePressed(BuildContext context) async {
    final enteredName = nameController.text.trim();
    if (enteredName.isEmpty) {
      Get.snackbar('Required', 'Please enter your full name',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white);
      return;
    }
    final email = emailController.text.trim();
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      Get.snackbar('Invalid Email', 'Please enter a valid email address',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white);
      return;
    }
    if (selectedDate != null && selectedDate!.isAfter(DateTime.now())) {
      Get.snackbar('Invalid Date', 'Date of birth cannot be in the future',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white);
      return;
    }

    final dobText = dobController.text.trim().isNotEmpty
        ? dobController.text.trim()
        : 'Not provided';
    final genderText = selectedGender.value;

    final isNewDobOrGender = !isDobLocked.value || !isGenderLocked.value;
    if (isNewDobOrGender) {
      final confirmed = await Get.dialog<bool>(
        ProfileConfirmDialog(dob: dobText, gender: genderText),
      );
      if (confirmed != true) return;
    }

    await saveProfile();
  }

  Future<void> saveProfile() async {
    final enteredName = nameController.text.trim();
    if (enteredName.isEmpty) return;
    final email = emailController.text.trim();

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
        };
        if (!isGenderLocked.value && selectedGender.value.isNotEmpty) {
          payload['gender'] = selectedGender.value.toLowerCase();
        }
        if (email.isNotEmpty) payload['email'] = email;
        if (!isDobLocked.value && dobIso != null) {
          payload['dateOfBirth'] = dobIso;
        }

        final response = await dioPut(
          endUrl: 'auth/me',
          data: payload,
          isJson: true,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _persistProfileLocally(enteredName, email, dobIso);
          await _syncAccountAndReload();
          Get.snackbar(
            'Success',
            'Profile updated successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.textPrimary,
            colorText: AppColor.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          _handleUpdateError(response.data);
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Something went wrong. Please check your connection and try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
      } finally {
        isSaving.value = false;
      }
    } else {
      isSaving.value = false;
      _persistProfileLocally(enteredName, email, dobIso);
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.textPrimary,
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _persistProfileLocally(String name, String email, String? dobIso) {
    userName.value = name;
    userEmail.value = email;
    userPhone.value = phoneController.text.trim();

    getBox.write(USER_NAME, userName.value);
    if (email.isNotEmpty) getBox.write(USER_EMAIL, userEmail.value);
    if (userPhone.value.isNotEmpty) getBox.write(USER_PHONE, userPhone.value);
    if (dobIso != null) getBox.write(USER_DOB, dobController.text);
    getBox.write(USER_GENDER, selectedGender.value);

    isNameLocked.value = true;
    if (email.isNotEmpty) isEmailLocked.value = true;
    if (dobIso != null || dobController.text.isNotEmpty) isDobLocked.value = true;
    isGenderLocked.value = true;
    _updateProfileDoneState();
  }

  Future<void> _syncAccountAndReload() async {
    if (Get.isRegistered<AccountController>()) {
      final accountCtrl = Get.find<AccountController>();
      accountCtrl.userName.value = userName.value;
      accountCtrl.userEmail.value = userEmail.value;
      accountCtrl.userPhone.value = userPhone.value;
      await accountCtrl.fetchUserProfile();
    }
    await fetchProfile();
  }

  void _handleUpdateError(dynamic rawData) {
    String msg = 'Could not update profile';
    if (rawData is Map) {
      if (rawData['error'] is Map) {
        final code = rawData['error']['code']?.toString();
        final rawMsg = rawData['error']['message']?.toString();
        if (code == 'DOB_LOCKED' ||
            (rawMsg != null &&
                (rawMsg.toLowerCase().contains("date of birth") ||
                    rawMsg.toLowerCase().contains("can't be changed")))) {
          isDobLocked.value = true;
          if (dobController.text.isNotEmpty) {
            getBox.write(USER_DOB, dobController.text);
          }
          _updateProfileDoneState();
          msg = "Date of birth is already set and cannot be changed.";
        } else if (code == 'EMAIL_TAKEN') {
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
      } else if (rawData['message'] != null) {
        msg = rawData['message'].toString();
      }
    }
    Get.snackbar(
      'Update Failed',
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.error,
      colorText: AppColor.white,
    );
  }
}
