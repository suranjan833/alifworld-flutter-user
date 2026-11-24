import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/models/manual_payment_model.dart';
import '../controllers/manual_payment_controller.dart';

class AddMoneySheet extends GetView<ManualPaymentController> {
  const AddMoneySheet({super.key});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    if (!Get.isRegistered<ManualPaymentController>()) {
      Get.put(ManualPaymentController());
    }
    final ctrl = Get.find<ManualPaymentController>();
    ctrl.openDepositSheet();
    if (initialTab != 0) {
      ctrl.depositTab.value = initialTab;
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMoneySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Obx(() {
        if (controller.isLoadingConfig.value && controller.config.value == null) {
          return SizedBox(
            height: 300.h,
            child: const Center(
              child: CircularProgressIndicator(color: AppColor.primary),
            ),
          );
        }

        final config = controller.config.value ?? ManualPaymentConfigModel();

        // §2 Rule: If enabled == false, show not available and hide options
        if (!config.enabled) {
          return Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                Icon(Iconsax.info_circle, size: 48.r, color: const Color(0xFF94A3B8)),
                SizedBox(height: 16.h),
                Text(
                  '${config.name} Unavailable',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Add money is temporarily disabled. Please check back later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          );
        }

        final bankAvailable = config.bankTransferAvailable;
        final selectedTab = controller.depositTab.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDragHandle(),

              // Title & Tagline (§2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5200).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFFF5200),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name.isNotEmpty ? config.name : 'Alif Pay',
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          config.tagline.isNotEmpty
                              ? config.tagline
                              : 'Add money to your Main wallet',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Tab Selector: Bank Transfer (if available) / Service Point / History
              _buildTabSelector(bankAvailable),

              SizedBox(height: 16.h),

              if (selectedTab == 0 && bankAvailable)
                _buildBankTransferSection(config)
              else if (selectedTab == 1 || (!bankAvailable && selectedTab == 0))
                _buildServicePointSection()
              else
                _buildDepositHistorySection(),

              SizedBox(height: 16.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColor.border,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  Widget _buildTabSelector(bool bankAvailable) {
    return Obx(() {
      final selectedTab = controller.depositTab.value;
      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            if (bankAvailable)
              Expanded(
                child: _buildTabButton(
                  title: 'Bank Transfer',
                  icon: Iconsax.card_send,
                  isSelected: selectedTab == 0,
                  onTap: () => controller.depositTab.value = 0,
                ),
              ),
            Expanded(
              child: _buildTabButton(
                title: 'Service Point',
                icon: Iconsax.shop,
                isSelected: bankAvailable ? selectedTab == 1 : selectedTab == 0,
                onTap: () => controller.depositTab.value = bankAvailable ? 1 : 0,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'History',
                icon: Iconsax.clock,
                isSelected: bankAvailable ? selectedTab == 2 : selectedTab == 1,
                onTap: () => controller.depositTab.value = bankAvailable ? 2 : 1,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15.r,
              color: isSelected ? AppColor.primary : AppColor.textSecondary,
            ),
            SizedBox(width: 5.w),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // §3 Bank Transfer Card & Form
  Widget _buildBankTransferSection(ManualPaymentConfigModel config) {
    return Obx(() {
      final enteredAmount = controller.enteredDepositAmount.value;
      final amountMinor = (enteredAmount * 100).round();
      final feeMinor = config.depositFee.calculateFeeMinor(amountMinor);
      final fee = feeMinor / 100.0;
      final netMinor = amountMinor - feeMinor;
      final net = netMinor / 100.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Admin Bank Details Card (§2 & §3)
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.bank, size: 18.r, color: const Color(0xFF1E293B)),
                    SizedBox(width: 8.w),
                    Text(
                      'Admin Bank Account Details',
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  'Please transfer funds to the following account and submit the transaction reference and receipt below.',
                  style: GoogleFonts.lato(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 12.h),

                // Each bank detail row with a Copy button (§2)
                ...config.bankDetails.map(
                  (b) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFEEF2F6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.label,
                                  style: GoogleFonts.lato(
                                    fontSize: 10.5.sp,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                                Text(
                                  b.value,
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: b.value));
                              showSnack('Copied', '${b.label} copied to clipboard');
                            },
                            borderRadius: BorderRadius.circular(6.r),
                            child: Padding(
                              padding: EdgeInsets.all(6.r),
                              child: Row(
                                children: [
                                  Icon(Iconsax.copy, size: 14.r, color: AppColor.primary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Copy',
                                    style: GoogleFonts.lato(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 2. Deposit Amount Input
          Text(
            'Deposit Amount (৳)',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.depositAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 5000',
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.r),
                child: Text(
                  '৳',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
              ),
            ),
          ),

          // Fee preview (§7): Hide when fee == 0! Never show "Fee: ৳0".
          if (feeMinor > 0) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, size: 14.r, color: const Color(0xFFB45309)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Fee ৳${fee.toStringAsFixed(2)} — you receive ৳${net.toStringAsFixed(2)} in Main wallet',
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 14.h),

          // 3. Bank Transaction Reference Input
          Text(
            'Transaction Reference / ID',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.depositRefCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. TXN123456789',
              prefixIcon: const Icon(Iconsax.receipt, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // 4. Receipt / Proof Upload (§3.1)
          Text(
            'Receipt Proof (Required)',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),

          Obx(() {
            final isUploading = controller.isUploadingReceipt.value;
            final proofUrl = controller.uploadedReceiptUrl.value;
            final fileName = controller.uploadedReceiptName.value;
            final localPath = controller.localReceiptPath.value;

            // If an image is selected locally (or uploaded), show preview immediately!
            if (localPath != null && localPath.isNotEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: proofUrl != null
                        ? const Color(0xFF86EFAC)
                        : (isUploading
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12.r)),
                          child: Image.file(
                            File(localPath),
                            height: 160.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120.h,
                              color: const Color(0xFFF1F5F9),
                              child: Center(
                                child: Icon(Iconsax.image,
                                    size: 36.r, color: AppColor.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        if (isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12.r)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColor.white,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Uploading receipt...',
                                      style: GoogleFonts.lato(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8.r,
                          right: 8.r,
                          child: InkWell(
                            onTap: isUploading
                                ? null
                                : () => controller.clearUploadedReceipt(),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 16.r, color: AppColor.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            proofUrl != null
                                ? Icons.check_circle_rounded
                                : (isUploading
                                    ? Icons.hourglass_top_rounded
                                    : Icons.info_outline_rounded),
                            color: proofUrl != null
                                ? const Color(0xFF16A34A)
                                : (isUploading
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF64748B)),
                            size: 18.r,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName ?? 'Receipt Screenshot',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: proofUrl != null
                                        ? const Color(0xFF15803D)
                                        : AppColor.textPrimary,
                                  ),
                                ),
                                Text(
                                  proofUrl != null
                                      ? 'Ready to submit'
                                      : (isUploading
                                          ? 'Uploading proof...'
                                          : 'Selected'),
                                  style: GoogleFonts.lato(
                                    fontSize: 11.sp,
                                    color: proofUrl != null
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isUploading) ...[
                            TextButton(
                              onPressed: () => controller
                                  .pickAndUploadReceipt(ImageSource.gallery),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Change',
                                style: GoogleFonts.lato(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            TextButton(
                              onPressed: () =>
                                  controller.clearUploadedReceipt(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Remove',
                                style: GoogleFonts.lato(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        controller.pickAndUploadReceipt(ImageSource.gallery),
                    icon: const Icon(Iconsax.gallery, size: 16),
                    label: Text(
                      'Pick from Gallery',
                      style: GoogleFonts.lato(
                          fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textPrimary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        controller.pickAndUploadReceipt(ImageSource.camera),
                    icon: const Icon(Iconsax.camera, size: 16),
                    label: Text(
                      'Take Photo',
                      style: GoogleFonts.lato(
                          fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textPrimary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          SizedBox(height: 20.h),

          // 5. Submit Button (§0: Disabled while in flight, no idempotency keys)
          Obx(() {
            final isSubmitting = controller.isSubmittingDeposit.value;
            final isUploading = controller.isUploadingReceipt.value;
            final hasProof =
                controller.uploadedReceiptUrl.value?.isNotEmpty ?? false;
            final canSubmit = !isSubmitting && !isUploading && hasProof && enteredAmount > 0;

            return SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () async {
                        final success = await controller.createDeposit(
                          amount: enteredAmount,
                          reference: controller.depositRefCtrl.text,
                        );
                        if (success) {
                          controller.depositAmountCtrl.clear();
                          controller.depositRefCtrl.clear();
                          controller.depositTab.value = 2; // switch to history tab
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5200),
                  foregroundColor: AppColor.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColor.white,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Submitting...',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Submit Deposit',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          }),

          SizedBox(height: 8.h),
          Text(
            'Your deposit request will be verified by an admin and credited to your Main wallet once approved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11.5.sp,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      );
    });
  }

  // §4 Service Point Tab
  Widget _buildServicePointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header card
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.info_circle, color: const Color(0xFFB45309), size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Pay cash at the Service Point — the money is credited to your Main wallet when you pay. (1% cash deposit fee applies).',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: const Color(0xFF92400E),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        Obx(() {
          if (controller.isLoadingServicePoints.value) {
            return SizedBox(
              height: 180.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
            );
          }

          final points = controller.servicePoints;
          if (points.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(Iconsax.shop, size: 36.r, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 8.h),
                  Text(
                    'No Service Points found',
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Service Points will appear here once configured in your area.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: points.map((p) {
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: p.suggested ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
                    width: p.suggested ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: p.suggested
                            ? const Color(0xFFFF5200).withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.shop,
                        color: p.suggested ? const Color(0xFFFF5200) : const Color(0xFF475569),
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.lato(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              // §4: suggested: true marks the single nearest point
                              if (p.suggested) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5200),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Nearest to you',
                                    style: GoogleFonts.lato(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            p.fullLocationText,
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // §3.3 Deposits History Tab
  Widget _buildDepositHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Deposit Requests',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18.r, color: AppColor.primary),
              onPressed: () => controller.fetchDeposits(refresh: true),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          if (controller.isLoadingDeposits.value) {
            return SizedBox(
              height: 180.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
            );
          }

          final list = controller.deposits;
          if (list.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(Iconsax.receipt, size: 36.r, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 8.h),
                  Text(
                    'No deposit requests yet',
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Your submitted deposits will appear here with verification status.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: list.map((d) {
              Color statusBg = const Color(0xFFFEF3C7);
              Color statusColor = const Color(0xFFB45309);
              String statusLabel = 'Waiting for verification';

              if (d.isApproved) {
                statusBg = const Color(0xFFDCFCE7);
                statusColor = const Color(0xFF15803D);
                statusLabel = 'Approved';
              } else if (d.isRejected) {
                statusBg = const Color(0xFFFEE2E2);
                statusColor = const Color(0xFFB91C1C);
                statusLabel = 'Rejected';
              }

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '৳${d.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.lato(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          'Ref: ${d.reference}',
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            color: AppColor.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (d.fee > 0) ...[
                          Text(
                            ' · Net: ৳${d.net.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (d.rejectReason != null && d.rejectReason!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Reason: ${d.rejectReason}',
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
