import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../routes/app_pages.dart';
import '../controllers/wallet_transfer_controller.dart';

class WalletTransferSheet extends GetView<WalletTransferController> {
  const WalletTransferSheet({super.key});

  static Future<void> show(BuildContext context) {
    if (!Get.isRegistered<WalletTransferController>()) {
      Get.put(WalletTransferController());
    }
    Get.find<WalletTransferController>().resetForm();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletTransferSheet(),
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
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Obx(() {
            if (controller.transferResult.value != null) {
              return _buildSuccessView(context);
            }
            return _buildTransferForm(context);
          }),
        ),
      ),
    );
  }

  Widget _buildTransferForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),

        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Money',
                  style: GoogleFonts.lato(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Main wallet to Main wallet • No fee',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppColor.textSecondary,
                size: 22.r,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        SizedBox(height: 18.h),

        // Step 1: Find Account / Recipient
        _buildRecipientSection(context),

        SizedBox(height: 20.h),

        // Step 2: Amount Entry (Visible once recipient is found or always visible)
        if (controller.lookupResult.value != null) ...[
          _buildAmountSection(),
          SizedBox(height: 20.h),
        ],

        // Error message if any
        if (controller.transferError.value != null) ...[
          Container(
            padding: EdgeInsets.all(10.r),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                  size: 18.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    controller.transferError.value!,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Transfer Button
        if (controller.lookupResult.value != null)
          ElevatedButton(
            onPressed: controller.isTransferring.value
                ? null
                : () => controller.initiateTransfer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: AppColor.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: 0,
            ),
            child: controller.isTransferring.value
                ? SizedBox(
                    height: 20.r,
                    width: 20.r,
                    child: const CircularProgressIndicator(
                      color: AppColor.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 18.r,
                        color: AppColor.white,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Transfer Money',
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.white,
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildRecipientSection(BuildContext context) {
    final lookup = controller.lookupResult.value;

    if (lookup != null) {
      // Recipient Found Card
      return Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFF99F6E4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: lookup.isSeller
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          lookup.isSeller
                              ? Icons.store_rounded
                              : Icons.person_rounded,
                          color: lookup.isSeller
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0D9488),
                          size: 22.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lookup.name,
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: lookup.isSeller
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                lookup.sideBadgeLabel,
                                style: GoogleFonts.lato(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: lookup.isSeller
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          lookup.maskedPhone ?? controller.phoneController.text,
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: controller.changeRecipient,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0D9488),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: const Color(0xFFCCFBF1), height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recipient Main Balance',
                  style: GoogleFonts.lato(
                    fontSize: 11.5.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                Text(
                  '৳${lookup.toBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Phone Lookup Input
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient Phone Number',
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  if (val.isNotEmpty) controller.lookupError.value = null;
                },
                onSubmitted: (_) => controller.lookupRecipient(),
                decoration: InputDecoration(
                  hintText: 'e.g. 01700000000',
                  hintStyle: GoogleFonts.lato(
                    color: AppColor.textHint,
                    fontSize: 13.sp,
                  ),
                  prefixIcon: Icon(
                    Iconsax.call,
                    size: 18.r,
                    color: AppColor.textSecondary,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.phoneController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18.r,
                          color: AppColor.textSecondary,
                        ),
                        onPressed: () {
                          controller.phoneController.clear();
                          controller.lookupError.value = null;
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF0D9488),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: controller.isLookingUp.value
                  ? null
                  : () => controller.lookupRecipient(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: AppColor.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: controller.isLookingUp.value
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        color: AppColor.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Find',
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
            ),
          ],
        ),
        if (controller.lookupError.value != null) ...[
          SizedBox(height: 6.h),
          Text(
            controller.lookupError.value!,
            style: GoogleFonts.lato(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amount to Transfer',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              'Available: ৳${controller.senderMainBalance.toStringAsFixed(2)}',
              style: GoogleFonts.lato(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => controller.validateAmount(),
          style: GoogleFonts.lato(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: GoogleFonts.lato(
              color: AppColor.textHint,
              fontSize: 18.sp,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Text(
                '৳',
                style: GoogleFonts.lato(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF0D9488),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (controller.amountError.value != null) ...[
          SizedBox(height: 6.h),
          Text(
            controller.amountError.value!,
            style: GoogleFonts.lato(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],

        SizedBox(height: 10.h),

        // Quick amount chips
        Row(
          children: [
            _buildQuickChip('৳100', () => controller.setQuickAmount(100)),
            SizedBox(width: 8.w),
            _buildQuickChip('৳500', () => controller.setQuickAmount(500)),
            SizedBox(width: 8.w),
            _buildQuickChip('৳1,000', () => controller.setQuickAmount(1000)),
            SizedBox(width: 8.w),
            _buildQuickChip(
              'All',
              () => controller.setQuickAmount(controller.senderMainBalance),
            ),
          ],
        ),

        SizedBox(height: 10.h),

        // Zero fee note
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF0D9488),
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'No fee — recipient gets the full amount.',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final res = controller.transferResult.value!;
    final recipient = res.recipient ?? controller.lookupResult.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.h),
        Center(
          child: Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: const Color(0xFF16A34A),
              size: 36.r,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Transfer Successful!',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '৳${res.amount.toStringAsFixed(2)} has been transferred',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D9488),
          ),
        ),
        SizedBox(height: 20.h),

        // Recipient Summary Card
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              if (recipient != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recipient',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    Text(
                      '${recipient.name} (${recipient.sideBadgeLabel})',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (recipient.maskedPhone != null) ...[
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phone',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      Text(
                        recipient.maskedPhone!,
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                Divider(color: const Color(0xFFE2E8F0), height: 16.h),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your New Balance',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  Text(
                    '৳${res.fromBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recipient New Balance',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  Text(
                    '৳${res.toBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 24.h),

        // Action Buttons
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Get.toNamed(Routes.MY_TRANSACTIONS);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0D9488),
            side: const BorderSide(color: Color(0xFF0D9488)),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'View Transaction History',
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: AppColor.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Text(
            'Done',
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.white,
            ),
          ),
        ),
      ],
    );
  }
}
