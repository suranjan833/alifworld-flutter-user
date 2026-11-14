import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../services/wallet_pin_service.dart';

typedef WalletPinSubmitCallback = Future<WalletPinActionResult> Function(String pin);

class WalletPinActionResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final dynamic data;

  const WalletPinActionResult.success([this.data])
      : success = true,
        errorCode = null,
        errorMessage = null;

  const WalletPinActionResult.failure({
    this.errorCode,
    this.errorMessage,
  })  : success = false,
        data = null;
}

class WalletPinDialog {
  WalletPinDialog._();

  /// Prompts user to enter or set their 6-digit wallet PIN.
  /// If no PIN is set, guides the user through setting one and returns the new PIN.
  /// If [onConfirm] is provided, executes the action directly while keeping the sheet
  /// open on `WALLET_PIN_*` errors (such as wrong attempts left or lock).
  /// Returns the 6-digit PIN if successfully entered/set, or `null` if dismissed.
  static Future<String?> promptPin(
    BuildContext context, {
    String title = 'Wallet PIN Required',
    String? subtitle,
    WalletPinSubmitCallback? onConfirm,
  }) async {
    final pinService = Get.isRegistered<WalletPinService>()
        ? Get.find<WalletPinService>()
        : Get.put(WalletPinService(), permanent: true);

    // Check current PIN status per §3.1
    final status = await pinService.checkStatus();
    if (!context.mounted) return null;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (ctx) => _WalletPinSheet(
        title: title,
        subtitle: subtitle,
        status: status,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Opens management flow (Set / Change / Reset PIN)
  static Future<void> showManagePinSheet(BuildContext context) async {
    final pinService = Get.isRegistered<WalletPinService>()
        ? Get.find<WalletPinService>()
        : Get.put(WalletPinService(), permanent: true);

    final status = await pinService.checkStatus();
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WalletPinSheet(
        isManageMode: true,
        status: status,
      ),
    );
  }
}

class _WalletPinSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final WalletPinStatus? status;
  final bool isManageMode;
  final WalletPinSubmitCallback? onConfirm;

  const _WalletPinSheet({
    this.title = 'Wallet PIN',
    this.subtitle,
    this.status,
    this.isManageMode = false,
    this.onConfirm,
  });

  @override
  State<_WalletPinSheet> createState() => _WalletPinSheetState();
}

enum _PinViewMode { enter, set, change, resetConfirm, locked }

class _WalletPinSheetState extends State<_WalletPinSheet> {
  late _PinViewMode _mode;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _mobileCodeController = TextEditingController();
  final _emailCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _mobileSent = false;
  bool _emailSent = false;
  DateTime? _lockedUntil;
  Timer? _lockCountdownTimer;
  String _remainingLockText = '';

  @override
  void initState() {
    super.initState();
    _lockedUntil = widget.status?.lockedUntil;

    if (widget.status?.isLocked == true) {
      _mode = _PinViewMode.locked;
      _startLockTimer();
    } else if (widget.status?.isSet != true) {
      _mode = _PinViewMode.set;
    } else if (widget.isManageMode) {
      _mode = _PinViewMode.change;
    } else {
      _mode = _PinViewMode.enter;
    }
  }

  @override
  void dispose() {
    _lockCountdownTimer?.cancel();
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    _mobileCodeController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  void _startLockTimer() {
    _updateLockText();
    _lockCountdownTimer?.cancel();
    _lockCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateLockText();
    });
  }

  void _updateLockText() {
    if (_lockedUntil == null) {
      _remainingLockText = '';
      return;
    }
    final diff = _lockedUntil!.difference(DateTime.now());
    if (diff.isNegative) {
      _lockCountdownTimer?.cancel();
      setState(() {
        _mode = _PinViewMode.enter;
        _errorMessage = null;
      });
    } else {
      final mins = diff.inMinutes;
      final secs = diff.inSeconds % 60;
      setState(() {
        _remainingLockText = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleEnterSubmit() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit PIN');
      return;
    }
    if (widget.onConfirm != null) {
      await _executeActionWithPin(pin);
    } else {
      // Return the entered pin to the caller
      Navigator.of(context).pop(pin);
    }
  }

  Future<void> _executeActionWithPin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onConfirm!(pin);
      if (!mounted) return;

      if (result.success) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop(pin);
      } else {
        final code = result.errorCode ?? '';
        final msg = result.errorMessage ?? 'Action failed';

        if (code == 'WALLET_PIN_LOCKED') {
          setState(() {
            _isLoading = false;
            _lockedUntil = DateTime.now().add(const Duration(minutes: 30));
            _mode = _PinViewMode.locked;
            _errorMessage = null;
          });
          _startLockTimer();
        } else if (code.startsWith('WALLET_PIN_')) {
          // Keep sheet open, show server message (e.g., attempts left)
          setState(() {
            _isLoading = false;
            _pinController.clear();
            _errorMessage = msg;
          });
        } else {
          // Other failures close sheet so underlying screen displays the error
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  Future<void> _handleSetSubmit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _errorMessage = 'PIN must be exactly 6 digits');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = Get.find<WalletPinService>();
    final result = await service.setOrChangePin(pin: pin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showSnack('Success', 'Wallet PIN set successfully', bg: AppColor.green);
      if (widget.isManageMode) {
        Navigator.of(context).pop();
      } else if (widget.onConfirm != null) {
        // Immediately run the pending action with the new PIN!
        await _executeActionWithPin(pin);
      } else {
        // Return newly set pin so caller can proceed with action immediately
        Navigator.of(context).pop(pin);
      }
    } else {
      setState(() => _errorMessage = result['message']?.toString() ?? 'Failed to set PIN');
    }
  }

  Future<void> _handleChangeSubmit() async {
    final current = _currentPinController.text.trim();
    final newPin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (current.length != 6) {
      setState(() => _errorMessage = 'Current PIN must be 6 digits');
      return;
    }
    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
      setState(() => _errorMessage = 'New PIN must be 6 digits');
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorMessage = 'New PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = Get.find<WalletPinService>();
    final result = await service.setOrChangePin(pin: newPin, currentPin: current);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showSnack('Success', 'Wallet PIN updated successfully', bg: AppColor.green);
      Navigator.of(context).pop();
    } else {
      final code = result['code']?.toString() ?? '';
      if (code == 'WALLET_PIN_LOCKED') {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 30));
        _mode = _PinViewMode.locked;
        _startLockTimer();
      } else {
        setState(() => _errorMessage = result['message']?.toString() ?? 'Failed to change PIN');
      }
    }
  }

  Future<void> _handleStartReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = Get.find<WalletPinService>();
    final res = await service.requestReset();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _mobileSent = res['mobileSent'] == true;
        _emailSent = res['emailSent'] == true;
        _mode = _PinViewMode.resetConfirm;
        _pinController.clear();
        _confirmPinController.clear();
      });
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'Failed to send reset code');
    }
  }

  Future<void> _handleConfirmResetSubmit() async {
    final newPin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final mCode = _mobileCodeController.text.trim();
    final eCode = _emailCodeController.text.trim();

    if (_mobileSent && mCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter mobile OTP code');
      return;
    }
    if (_emailSent && eCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter email OTP code');
      return;
    }
    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
      setState(() => _errorMessage = 'New PIN must be 6 digits');
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = Get.find<WalletPinService>();
    final res = await service.confirmReset(
      mobileCode: _mobileSent ? mCode : null,
      emailCode: _emailSent ? eCode : null,
      newPin: newPin,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      showSnack('Success', 'Wallet PIN reset successfully', bg: AppColor.green);
      if (widget.isManageMode) {
        Navigator.of(context).pop();
      } else if (widget.onConfirm != null) {
        // Immediately run the pending action with the new PIN!
        await _executeActionWithPin(newPin);
      } else {
        // Return new PIN
        Navigator.of(context).pop(newPin);
      }
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'Reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_isLoading,
      child: Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 16.h,
          bottom: bottomInset + 24.h,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColor.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Title and icon
              _buildHeader(),

              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColor.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColor.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColor.red, size: 18.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            color: AppColor.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              // View body depending on mode
              if (_mode == _PinViewMode.enter) _buildEnterView(),
              if (_mode == _PinViewMode.set) _buildSetView(),
              if (_mode == _PinViewMode.change) _buildChangeView(),
              if (_mode == _PinViewMode.resetConfirm) _buildResetConfirmView(),
              if (_mode == _PinViewMode.locked) _buildLockedView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String titleText;
    String subtitleText;
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (_mode) {
      case _PinViewMode.enter:
        titleText = widget.title;
        subtitleText = widget.subtitle ?? 'Enter your 6-digit Wallet PIN to proceed';
        icon = Iconsax.lock;
        iconBg = AppColor.primary.withValues(alpha: 0.1);
        iconColor = AppColor.primary;
        break;
      case _PinViewMode.set:
        titleText = 'Set Wallet PIN';
        subtitleText = 'Create a secure 6-digit PIN for wallet transactions';
        icon = Iconsax.shield_security;
        iconBg = AppColor.green.shade50;
        iconColor = AppColor.green;
        break;
      case _PinViewMode.change:
        titleText = 'Change Wallet PIN';
        subtitleText = 'Enter your current PIN and choose a new 6-digit PIN';
        icon = Iconsax.key;
        iconBg = AppColor.primary.withValues(alpha: 0.1);
        iconColor = AppColor.primary;
        break;
      case _PinViewMode.resetConfirm:
        titleText = 'Reset Wallet PIN';
        subtitleText = 'Enter the OTP code sent to your verified channels';
        icon = Iconsax.refresh;
        iconBg = AppColor.blue.shade50;
        iconColor = AppColor.blue;
        break;
      case _PinViewMode.locked:
        titleText = 'Wallet PIN Locked';
        subtitleText = 'Too many failed attempts. Locked for 30 minutes.';
        icon = Iconsax.lock_slash;
        iconBg = AppColor.red.shade50;
        iconColor = AppColor.red;
        break;
    }

    return Row(
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (subtitleText.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitleText,
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          textInputAction: action,
          onSubmitted: (_) => onSubmitted?.call(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.lato(
              fontSize: 14.sp,
              color: AppColor.textHint,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColor.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColor.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          controller: _pinController,
          label: 'Enter 6-Digit PIN',
          hint: '••••••',
          action: TextInputAction.done,
          onSubmitted: _handleEnterSubmit,
        ),
        SizedBox(height: 6.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleStartReset,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot PIN?',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        _buildActionButton(
          label: 'Confirm PIN',
          onPressed: _handleEnterSubmit,
        ),
      ],
    );
  }

  Widget _buildSetView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          controller: _pinController,
          label: 'New 6-Digit PIN',
          hint: 'Enter 6 digits',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          controller: _confirmPinController,
          label: 'Confirm PIN',
          hint: 'Re-enter 6 digits',
          action: TextInputAction.done,
          onSubmitted: _handleSetSubmit,
        ),
        SizedBox(height: 20.h),
        _buildActionButton(
          label: 'Set PIN & Continue',
          onPressed: _handleSetSubmit,
        ),
      ],
    );
  }

  Widget _buildChangeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          controller: _currentPinController,
          label: 'Current PIN',
          hint: 'Enter current 6-digit PIN',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          controller: _pinController,
          label: 'New 6-Digit PIN',
          hint: 'Enter new 6-digit PIN',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          controller: _confirmPinController,
          label: 'Confirm New PIN',
          hint: 'Re-enter new 6 digits',
          action: TextInputAction.done,
          onSubmitted: _handleChangeSubmit,
        ),
        SizedBox(height: 6.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleStartReset,
            child: Text(
              'Forgot Current PIN?',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        _buildActionButton(
          label: 'Change PIN',
          onPressed: _handleChangeSubmit,
        ),
      ],
    );
  }

  Widget _buildResetConfirmView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mobileSent) ...[
          _buildPinField(
            controller: _mobileCodeController,
            label: 'Mobile OTP Code',
            hint: 'Enter code sent via SMS',
          ),
          SizedBox(height: 12.h),
        ],
        if (_emailSent) ...[
          _buildPinField(
            controller: _emailCodeController,
            label: 'Email OTP Code',
            hint: 'Enter code sent via Email',
          ),
          SizedBox(height: 12.h),
        ],
        _buildPinField(
          controller: _pinController,
          label: 'New 6-Digit PIN',
          hint: 'Enter 6 digits',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          controller: _confirmPinController,
          label: 'Confirm New PIN',
          hint: 'Re-enter 6 digits',
          action: TextInputAction.done,
          onSubmitted: _handleConfirmResetSubmit,
        ),
        SizedBox(height: 20.h),
        _buildActionButton(
          label: 'Reset & Set PIN',
          onPressed: _handleConfirmResetSubmit,
        ),
      ],
    );
  }

  Widget _buildLockedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Your wallet PIN is temporarily locked due to 5 consecutive wrong attempts.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        if (_remainingLockText.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColor.red.shade50,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Unlocks in $_remainingLockText',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.red,
              ),
            ),
          ),
        SizedBox(height: 24.h),
        _buildActionButton(
          label: 'Reset PIN via OTP Now',
          onPressed: _handleStartReset,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.6),
        ),
        child: _isLoading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
