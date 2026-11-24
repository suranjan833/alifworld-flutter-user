import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../controllers/wallet_pin_sheet_controller.dart';
import '../services/wallet_pin_service.dart';

export '../controllers/wallet_pin_sheet_controller.dart';

class WalletPinDialog {
  WalletPinDialog._();

  static Future<String?> promptPin(
    BuildContext context, {
    String title = 'Wallet PIN Required',
    String? subtitle,
    WalletPinSubmitCallback? onConfirm,
  }) async {
    final pinService = Get.isRegistered<WalletPinService>()
        ? Get.find<WalletPinService>()
        : Get.put(WalletPinService(), permanent: true);

    final status = await pinService.checkStatus();
    if (!context.mounted) return null;

    final sheetCtrl = Get.isRegistered<WalletPinSheetController>()
        ? Get.find<WalletPinSheetController>()
        : Get.put(WalletPinSheetController());

    sheetCtrl.initSheet(
      title: title,
      subtitle: subtitle,
      status: status,
      isManageMode: false,
      onConfirm: onConfirm,
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WalletPinSheet(),
    );

    return result;
  }

  static Future<void> showManagePinSheet(BuildContext context) async {
    final pinService = Get.isRegistered<WalletPinService>()
        ? Get.find<WalletPinService>()
        : Get.put(WalletPinService(), permanent: true);

    final status = await pinService.checkStatus();
    if (!context.mounted) return;

    final sheetCtrl = Get.isRegistered<WalletPinSheetController>()
        ? Get.find<WalletPinSheetController>()
        : Get.put(WalletPinSheetController());

    sheetCtrl.initSheet(
      isManageMode: true,
      status: status,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WalletPinSheet(),
    );
  }
}

class WalletPinSheet extends GetView<WalletPinSheetController> {
  const WalletPinSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final errorMessage = controller.errorMessage.value;
      final mode = controller.mode.value;

      return PopScope(
        canPop: !isLoading,
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
                _buildHeader(),
                if (errorMessage != null) ...[
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
                            errorMessage,
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
                if (mode == PinViewMode.enter) _buildEnterView(context),
                if (mode == PinViewMode.set) _buildSetView(context),
                if (mode == PinViewMode.change) _buildChangeView(context),
                if (mode == PinViewMode.resetConfirm) _buildResetConfirmView(context),
                if (mode == PinViewMode.locked) _buildLockedView(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    final info = controller.headerInfo;

    return Row(
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(color: info.iconBg, shape: BoxShape.circle),
          child: Icon(info.icon, color: info.iconColor, size: 22.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (info.subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  info.subtitle,
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
    required TextEditingController fieldController,
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
          controller: fieldController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          textInputAction: action,
          onSubmitted: (_) => onSubmitted?.call(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.lato(color: AppColor.textHint, fontSize: 13.sp),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColor.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColor.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          fieldController: controller.pinController,
          label: 'Enter 4-Digit PIN',
          hint: '••••',
          action: TextInputAction.done,
          onSubmitted: () => controller.handleEnterSubmit(context),
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.isLoading.value ? null : () => controller.handleStartReset(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(50.w, 30.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot PIN?',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildActionButton(
          label: 'Verify & Proceed',
          onPressed: () => controller.handleEnterSubmit(context),
        ),
      ],
    );
  }

  Widget _buildSetView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          fieldController: controller.pinController,
          label: 'New 4-Digit PIN',
          hint: 'Enter 4 digits',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          fieldController: controller.confirmPinController,
          label: 'Confirm PIN',
          hint: 'Re-enter 4 digits',
          action: TextInputAction.done,
          onSubmitted: () => controller.handleSetSubmit(context),
        ),
        SizedBox(height: 20.h),
        _buildActionButton(
          label: 'Set Wallet PIN',
          onPressed: () => controller.handleSetSubmit(context),
        ),
      ],
    );
  }

  Widget _buildChangeView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(
          fieldController: controller.currentPinController,
          label: 'Current PIN',
          hint: 'Enter current 4-digit PIN',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          fieldController: controller.pinController,
          label: 'New 4-Digit PIN',
          hint: 'Enter new 4-digit PIN',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          fieldController: controller.confirmPinController,
          label: 'Confirm New PIN',
          hint: 'Re-enter new 4 digits',
          action: TextInputAction.done,
          onSubmitted: () => controller.handleChangeSubmit(context),
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.isLoading.value ? null : () => controller.handleStartReset(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(50.w, 30.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot PIN?',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildActionButton(
          label: 'Update PIN',
          onPressed: () => controller.handleChangeSubmit(context),
        ),
      ],
    );
  }

  Widget _buildResetConfirmView(BuildContext context) {
    final mobileSent = controller.mobileSent.value;
    final emailSent = controller.emailSent.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobileSent) ...[
          _buildPinField(
            fieldController: controller.mobileCodeController,
            label: 'Mobile OTP Code',
            hint: 'Enter SMS OTP',
          ),
          SizedBox(height: 12.h),
        ],
        if (emailSent) ...[
          _buildPinField(
            fieldController: controller.emailCodeController,
            label: 'Email OTP Code',
            hint: 'Enter email OTP',
          ),
          SizedBox(height: 12.h),
        ],
        if (!mobileSent && !emailSent) ...[
          _buildPinField(
            fieldController: controller.mobileCodeController,
            label: 'Reset OTP Code',
            hint: 'Enter 6-digit OTP code',
          ),
          SizedBox(height: 12.h),
        ],
        _buildPinField(
          fieldController: controller.pinController,
          label: 'New 4-Digit PIN',
          hint: 'Enter 4 digits',
        ),
        SizedBox(height: 12.h),
        _buildPinField(
          fieldController: controller.confirmPinController,
          label: 'Confirm New PIN',
          hint: 'Re-enter 4 digits',
          action: TextInputAction.done,
          onSubmitted: () => controller.handleConfirmResetSubmit(context),
        ),
        SizedBox(height: 20.h),
        _buildActionButton(
          label: 'Reset & Set PIN',
          onPressed: () => controller.handleConfirmResetSubmit(context),
        ),
      ],
    );
  }

  Widget _buildLockedView() {
    return Column(
      children: [
        SizedBox(height: 10.h),
        Text(
          'Your wallet PIN is temporarily locked due to 5 consecutive incorrect attempts.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 14.sp, color: AppColor.textSecondary, height: 1.4),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColor.red.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColor.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.timer, color: AppColor.red, size: 20.r),
              SizedBox(width: 8.w),
              Obx(
                () => Text(
                  'Unlocks in ${controller.remainingLockText.value}',
                  style: GoogleFonts.lato(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColor.red),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        _buildActionButton(
          label: 'Reset PIN with OTP',
          onPressed: () => controller.handleStartReset(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final isLoading = controller.isLoading.value;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      child: isLoading
          ? SizedBox(
              height: 20.r,
              width: 20.r,
              child: const CircularProgressIndicator(color: AppColor.white, strokeWidth: 2),
            )
          : Text(
              label,
              style: GoogleFonts.lato(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColor.white),
            ),
    );
  }
}
