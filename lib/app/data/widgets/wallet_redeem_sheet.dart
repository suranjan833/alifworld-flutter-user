import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../controllers/wallet_redeem_controller.dart';
import '../models/redeem_model.dart';
import '../models/wallet_model.dart';

export '../controllers/wallet_redeem_controller.dart';

class WalletRedeemSheet extends GetView<WalletRedeemController> {
  const WalletRedeemSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required List<WalletItemModel> wallets,
    String? initialWalletKind,
    required VoidCallback onRedeemSuccess,
  }) async {
    final ctrl = Get.isRegistered<WalletRedeemController>()
        ? Get.find<WalletRedeemController>()
        : Get.put(WalletRedeemController());

    ctrl.initSheet(
      wallets: wallets,
      initialWalletKind: initialWalletKind,
      onRedeemSuccess: onRedeemSuccess,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WalletRedeemSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Obx(() {
      final wallet = controller.currentWallet;
      final selectedKind = controller.selectedKind.value;
      final validWallets = controller.validWallets;
      final errorMessage = controller.errorMessage.value;
      final isPreviewLoading = controller.isPreviewLoading.value;
      final isSubmitting = controller.isSubmitting.value;
      final preview = controller.preview.value;

      return Container(
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

              Row(
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.repeat, color: AppColor.primary, size: 22.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Redeem Bonus Balance',
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        Text(
                          'Convert bonus balances into Main, Shopping & Good-Luck',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              Text(
                'Select Bonus Wallet',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColor.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedKind,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: validWallets.map((w) {
                      return DropdownMenuItem<String>(
                        value: w.kind,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(w.icon, size: 18.r, color: AppColor.primary),
                                SizedBox(width: 10.w),
                                Text(
                                  w.title,
                                  style: GoogleFonts.lato(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '৳${w.balance.toStringAsFixed(2)}',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newKind) {
                      if (newKind != null) {
                        controller.selectWallet(newKind);
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount to Redeem (৳)',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  Text(
                    'Available: ৳${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                    style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.textSecondary),
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
                decoration: InputDecoration(
                  hintText: 'Enter amount in taka',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Center(
                      widthFactor: 1.0,
                      child: Text(
                        '৳',
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  suffixIcon: TextButton(
                    onPressed: controller.fillMaxAmount,
                    child: Text(
                      'MAX',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColor.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColor.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
                ),
              ),

              if (errorMessage != null) ...[
                SizedBox(height: 10.h),
                Text(
                  errorMessage,
                  style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.red, fontWeight: FontWeight.w500),
                ),
              ],

              SizedBox(height: 16.h),

              if (isPreviewLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(child: CircularProgressIndicator(color: AppColor.primary)),
                )
              else if (preview != null) ...[
                _buildPreviewDetails(preview),
                SizedBox(height: 18.h),
              ],

              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : (preview == null
                          ? controller.fetchPreview
                          : () => controller.executeRedeem(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColor.white),
                          ),
                        )
                      : Text(
                          preview == null ? 'Preview Breakdown' : 'Confirm & Redeem with PIN',
                          style: GoogleFonts.lato(fontSize: 15.sp, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPreviewDetails(RedeemPreviewResponseModel preview) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeem Amount',
                style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textSecondary),
              ),
              Text(
                '৳${preview.amount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColor.textPrimary),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFCBD5E1)),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColor.green, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                'You will receive:',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...preview.receiveShares.map((s) => Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.displayName, style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textPrimary)),
                    Text('+ ৳${s.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColor.green.shade700)),
                  ],
                ),
              )),
          if (preview.deductedShares.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.remove_circle_outline, color: const Color(0xFFE11D48), size: 16.r),
                SizedBox(width: 6.w),
                Text(
                  'Deducted:',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ...preview.deductedShares.map((s) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.displayName, style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textPrimary)),
                      Text('- ৳${s.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
