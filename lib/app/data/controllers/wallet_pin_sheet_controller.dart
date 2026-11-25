import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../services/wallet_pin_service.dart';
import 'package:iconsax/iconsax.dart';

enum PinViewMode { enter, set, change, resetConfirm, locked }

class PinHeaderInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  PinHeaderInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

typedef WalletPinSubmitCallback = Future<WalletPinActionResult> Function(String pin);

class WalletPinActionResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  const WalletPinActionResult.success()
      : success = true,
        errorCode = null,
        errorMessage = null;

  const WalletPinActionResult.failure({this.errorCode, this.errorMessage})
      : success = false;
}

class WalletPinSheetController extends GetxController {
  final mode = PinViewMode.enter.obs;

  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final currentPinController = TextEditingController();
  final mobileCodeController = TextEditingController();
  final emailCodeController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final mobileSent = false.obs;
  final emailSent = false.obs;
  final lockedUntil = Rxn<DateTime>();
  final remainingLockText = ''.obs;

  Timer? _lockCountdownTimer;

  String title = 'Wallet PIN';
  String? subtitle;
  bool isManageMode = false;
  WalletPinSubmitCallback? onConfirm;

  PinHeaderInfo get headerInfo {
    switch (mode.value) {
      case PinViewMode.enter:
        return PinHeaderInfo(
          title: title,
          subtitle: subtitle ?? 'Enter your 6-digit Wallet PIN to proceed',
          icon: Iconsax.lock,
          iconBg: AppColor.primary.withValues(alpha: 0.1),
          iconColor: AppColor.primary,
        );
      case PinViewMode.set:
        return PinHeaderInfo(
          title: 'Set Wallet PIN',
          subtitle: 'Create a secure 6-digit PIN for wallet transactions',
          icon: Iconsax.shield_security,
          iconBg: AppColor.green.shade50,
          iconColor: AppColor.green,
        );
      case PinViewMode.change:
        return PinHeaderInfo(
          title: 'Change Wallet PIN',
          subtitle: 'Enter your current PIN and choose a new 6-digit PIN',
          icon: Iconsax.key,
          iconBg: AppColor.primary.withValues(alpha: 0.1),
          iconColor: AppColor.primary,
        );
      case PinViewMode.resetConfirm:
        return PinHeaderInfo(
          title: 'Reset Wallet PIN',
          subtitle: 'Enter the OTP code sent to your verified channels',
          icon: Iconsax.refresh,
          iconBg: AppColor.blue.shade50,
          iconColor: AppColor.blue,
        );
      case PinViewMode.locked:
        return PinHeaderInfo(
          title: 'Wallet PIN Locked',
          subtitle: 'Too many failed attempts. Locked for 30 minutes.',
          icon: Iconsax.lock_slash,
          iconBg: AppColor.red.shade50,
          iconColor: AppColor.red,
        );
    }
  }

  void initSheet({
    String title = 'Wallet PIN',
    String? subtitle,
    WalletPinStatus? status,
    bool isManageMode = false,
    WalletPinSubmitCallback? onConfirm,
  }) {
    this.title = title;
    this.subtitle = subtitle;
    this.isManageMode = isManageMode;
    this.onConfirm = onConfirm;

    pinController.clear();
    confirmPinController.clear();
    currentPinController.clear();
    mobileCodeController.clear();
    emailCodeController.clear();

    isLoading.value = false;
    errorMessage.value = null;
    mobileSent.value = false;
    emailSent.value = false;

    lockedUntil.value = status?.lockedUntil;

    if (status?.isLocked == true) {
      mode.value = PinViewMode.locked;
      _startLockTimer();
    } else if (status?.isSet != true) {
      mode.value = PinViewMode.set;
    } else if (isManageMode) {
      mode.value = PinViewMode.change;
    } else {
      mode.value = PinViewMode.enter;
    }
  }

  void _startLockTimer() {
    _updateLockText();
    _lockCountdownTimer?.cancel();
    _lockCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLockText();
    });
  }

  void _updateLockText() {
    if (lockedUntil.value == null) {
      remainingLockText.value = '';
      return;
    }
    final diff = lockedUntil.value!.difference(DateTime.now());
    if (diff.isNegative) {
      _lockCountdownTimer?.cancel();
      mode.value = PinViewMode.enter;
      errorMessage.value = null;
    } else {
      final mins = diff.inMinutes;
      final secs = diff.inSeconds % 60;
      remainingLockText.value =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> handleEnterSubmit(BuildContext context) async {
    final pin = pinController.text.trim();
    if ((pin.length != 6 && pin.length != 4) || !RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      errorMessage.value = 'Please enter a valid 6-digit PIN';
      return;
    }
    if (onConfirm != null) {
      await executeActionWithPin(context, pin);
    } else {
      Navigator.of(context).pop(pin);
    }
  }

  Future<void> executeActionWithPin(BuildContext context, String pin) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await onConfirm!(pin);

      if (result.success) {
        isLoading.value = false;
        Get.back(result: pin);
      } else {
        final code = result.errorCode ?? '';
        final msg = result.errorMessage ?? 'Action failed';

        if (code == 'WALLET_PIN_LOCKED') {
          isLoading.value = false;
          lockedUntil.value = DateTime.now().add(const Duration(minutes: 30));
          mode.value = PinViewMode.locked;
          errorMessage.value = null;
          _startLockTimer();
        } else if (code.startsWith('WALLET_PIN_')) {
          isLoading.value = false;
          pinController.clear();
          errorMessage.value = msg;
        } else {
          isLoading.value = false;
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred: $e';
    }
  }

  Future<void> handleSetSubmit(BuildContext context) async {
    final pin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();

    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      errorMessage.value = 'PIN must be exactly 6 digits';
      return;
    }
    if (pin != confirm) {
      errorMessage.value = 'PINs do not match';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    final service = Get.find<WalletPinService>();
    final result = await service.setOrChangePin(pin: pin);

    isLoading.value = false;

    if (result['success'] == true) {
      showSnack('Success', 'Wallet PIN set successfully', bg: AppColor.green);
      if (isManageMode) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Immediately dismiss the PIN dialog without holding, returning the newly set PIN
        if (context.mounted) {
          Navigator.of(context).pop(pin);
        }
      }
    } else {
      errorMessage.value =
          result['message']?.toString() ?? 'Failed to set PIN';
    }
  }

  Future<void> handleChangeSubmit(BuildContext context) async {
    final current = currentPinController.text.trim();
    final newPin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();

    if (current.length != 6 && current.length != 4) {
      errorMessage.value = 'Current PIN must be 6 digits';
      return;
    }
    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
      errorMessage.value = 'New PIN must be 6 digits';
      return;
    }
    if (newPin != confirm) {
      errorMessage.value = 'New PINs do not match';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    final service = Get.find<WalletPinService>();
    final result =
        await service.setOrChangePin(pin: newPin, currentPin: current);

    isLoading.value = false;

    if (result['success'] == true) {
      showSnack('Success', 'Wallet PIN updated successfully', bg: AppColor.green);
      Get.back();
    } else {
      final code = result['code']?.toString() ?? '';
      if (code == 'WALLET_PIN_LOCKED') {
        lockedUntil.value = DateTime.now().add(const Duration(minutes: 30));
        mode.value = PinViewMode.locked;
        _startLockTimer();
      } else {
        errorMessage.value =
            result['message']?.toString() ?? 'Failed to change PIN';
      }
    }
  }

  Future<void> handleStartReset() async {
    isLoading.value = true;
    errorMessage.value = null;

    final service = Get.find<WalletPinService>();
    final res = await service.requestReset();

    isLoading.value = false;

    if (res['success'] == true) {
      mobileSent.value = res['mobileSent'] == true;
      emailSent.value = res['emailSent'] == true;
      mode.value = PinViewMode.resetConfirm;
      pinController.clear();
      confirmPinController.clear();
    } else {
      errorMessage.value =
          res['message']?.toString() ?? 'Failed to send reset code';
    }
  }

  Future<void> handleConfirmResetSubmit(BuildContext context) async {
    final newPin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();
    final mCode = mobileCodeController.text.trim();
    final eCode = emailCodeController.text.trim();

    if (mobileSent.value && mCode.isEmpty) {
      errorMessage.value = 'Please enter mobile OTP code';
      return;
    }
    if (emailSent.value && eCode.isEmpty) {
      errorMessage.value = 'Please enter email OTP code';
      return;
    }
    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
      errorMessage.value = 'New PIN must be 6 digits';
      return;
    }
    if (newPin != confirm) {
      errorMessage.value = 'PINs do not match';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    final service = Get.find<WalletPinService>();
    final res = await service.confirmReset(
      code: (!mobileSent.value && !emailSent.value) ? mCode : null,
      mobileCode: mobileSent.value ? mCode : null,
      emailCode: emailSent.value ? eCode : null,
      newPin: newPin,
    );

    isLoading.value = false;

    if (res['success'] == true) {
      showSnack('Success', 'Wallet PIN reset successfully', bg: AppColor.green);
      if (isManageMode) {
        Get.back();
      } else if (onConfirm != null) {
        if (context.mounted) {
          await executeActionWithPin(context, newPin);
        }
      } else {
        Get.back(result: newPin);
      }
    } else {
      errorMessage.value = res['message']?.toString() ?? 'Reset failed';
    }
  }

  @override
  void onClose() {
    _lockCountdownTimer?.cancel();
    pinController.dispose();
    confirmPinController.dispose();
    currentPinController.dispose();
    mobileCodeController.dispose();
    emailCodeController.dispose();
    super.onClose();
  }
}
