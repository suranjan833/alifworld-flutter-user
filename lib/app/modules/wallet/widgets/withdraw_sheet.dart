import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/models/manual_payment_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import '../controllers/manual_payment_controller.dart';
import '../controllers/wallet_controller.dart';

class WithdrawSheet extends GetView<ManualPaymentController> {
  const WithdrawSheet({super.key});

  static Future<void> show(BuildContext context) {
    if (!Get.isRegistered<ManualPaymentController>()) {
      Get.put(ManualPaymentController());
    }
    Get.find<ManualPaymentController>().openWithdrawSheet();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WithdrawSheet(),
    );
  }

  WalletController get walletCtrl => Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());

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
                  'Withdrawal Unavailable',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Wallet withdrawals are temporarily disabled. Please check back later.',
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

        final selectedTab = controller.withdrawTab.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDragHandle(),

              // Title Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdraw Money',
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Payout from your Main wallet to saved bank account',
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

              SizedBox(height: 14.h),

              // Available Main Balance Banner
              _buildMainBalanceBanner(),

              SizedBox(height: 14.h),

              // Tab Selector: Withdraw / History
              _buildTabSelector(),

              SizedBox(height: 16.h),

              if (selectedTab == 0)
                _buildWithdrawSection(context, config)
              else
                _buildWithdrawalHistorySection(),

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

  Widget _buildMainBalanceBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.wallet_2, color: const Color(0xFF2563EB), size: 20.r),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Main Balance',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: AppColor.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Obx(
                    () => Text(
                      '৳${walletCtrl.mainBalance.value.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'customer_main',
              style: GoogleFonts.lato(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Obx(() {
      final currentTab = controller.withdrawTab.value;
      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'Withdraw Payout',
                icon: Iconsax.card_send,
                isSelected: currentTab == 0,
                onTap: () => controller.withdrawTab.value = 0,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'History',
                icon: Iconsax.clock,
                isSelected: currentTab == 1,
                onTap: () => controller.withdrawTab.value = 1,
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
              color: isSelected ? const Color(0xFF2563EB) : AppColor.textSecondary,
            ),
            SizedBox(width: 6.w),
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

  // §6 Withdraw Section
  Widget _buildWithdrawSection(BuildContext context, ManualPaymentConfigModel config) {
    return Obx(() {
      final accounts = controller.withdrawalAccounts;
      final isAccountsEmpty = accounts.isEmpty;
      final isAddingCard = controller.isAddingNewCard.value;
      final enteredAmount = controller.enteredWithdrawAmount.value;

      final amountMinor = (enteredAmount * 100).round();
      final feeMinor = config.withdrawFee.calculateFeeMinor(amountMinor);
      final fee = feeMinor / 100.0;
      final netMinor = amountMinor - feeMinor;
      final net = netMinor / 100.0;
      final mainBal = walletCtrl.mainBalance.value;
      final isOverBalance = enteredAmount > mainBal;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // §5.2 Flow rule: when card list is empty (first withdrawal), show setup form
          // instead of picker. Otherwise show picker with "Add new card" option.
          if (isAccountsEmpty || isAddingCard)
            _buildCardSetupForm(config, isInitial: isAccountsEmpty)
          else
            _buildCardPicker(config),

          SizedBox(height: 14.h),

          // Informative banner: Held at submit, refunded on reject
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 16.r,
                  color: const Color(0xFF1D4ED8),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'The requested amount leaves your Main wallet as soon as you submit and is held while pending. If your request is rejected by the admin, the full amount is refunded to your Main wallet immediately.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // Amount Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Withdrawal Amount (৳)',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (mainBal > 0)
                InkWell(
                  onTap: () {
                    controller.withdrawAmountCtrl.text = mainBal.toStringAsFixed(0);
                  },
                  child: Text(
                    'Withdraw All',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.withdrawAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 1000',
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
                borderSide: BorderSide(
                  color: isOverBalance ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isOverBalance ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isOverBalance ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Inline Error: Over balance (§8 INSUFFICIENT_BALANCE)
          if (isOverBalance) ...[
            SizedBox(height: 4.h),
            Text(
              'Amount exceeds your available Main wallet balance (৳${mainBal.toStringAsFixed(2)})',
              style: GoogleFonts.lato(
                fontSize: 11.5.sp,
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Fee Preview (§7): Breakdown matching specification
          if (feeMinor > 0 && !isOverBalance) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Withdrawal Amount',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '৳${enteredAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Charge (${config.withdrawFee.pct}%)',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        '-৳${fee.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'You Will Receive',
                        style: GoogleFonts.lato(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '৳${net.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20.h),

          // Withdraw Button (§6.1: Disabled if no card picked or in flight or over balance)
          Builder(builder: (_) {
            final isSubmitting = controller.isSubmittingWithdrawal.value;
            final hasCard = controller.selectedAccountId.value != null &&
                controller.selectedAccountId.value!.isNotEmpty;
            final canSubmit = !isSubmitting &&
                hasCard &&
                enteredAmount > 0 &&
                !isOverBalance &&
                !isAddingCard;

            return SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () => _handleWithdrawSubmit(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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
                            'Processing...',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Withdraw Money',
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
            'Amount is deducted from Main wallet upon submission and refunded in full if rejected. Authorized with your 6-digit PIN and verified by admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              color: const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      );
    });
  }

  // Card Picker (§5.1)
  Widget _buildCardPicker(ManualPaymentConfigModel config) {
    return Obx(() {
      final accounts = controller.withdrawalAccounts;
      final selectedId = controller.selectedAccountId.value;
      final armedId = controller.pendingDeleteCardId.value;
      final deletingId = controller.isDeletingAccountId.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Payout Card / Account',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  controller.isAddingNewCard.value = true;
                },
                child: Row(
                  children: [
                    Icon(Icons.add_rounded,
                        size: 16.r, color: const Color(0xFF2563EB)),
                    SizedBox(width: 2.w),
                    Text(
                      'Add New Card',
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...accounts.map((card) {
            final isSelected = card.id == selectedId;
            final isDeleting = deletingId == card.id;
            final isArmed = armedId == card.id;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.selectedAccountId.value = card.id;
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Row(
                          children: [
                            // Radio indicator
                            Container(
                              width: 18.r,
                              height: 18.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8.r,
                                        height: 8.r,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12.w),

                            // Label & masked subtitle (§5.1: bank name · ••••last4)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.label,
                                    style: GoogleFonts.lato(
                                      fontSize: 13.5.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    card.maskedSubtitle,
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
                      ),
                    ),

                    // Delete button (§5.3: 2-tap confirm)
                    if (isDeleting)
                      SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (isArmed)
                      InkWell(
                        onTap: () => controller.deleteWithdrawalAccount(card.id),
                        borderRadius: BorderRadius.circular(6.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Confirm Delete',
                            style: GoogleFonts.lato(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () {
                          // Tap once to arm (§5.3)
                          controller.pendingDeleteCardId.value = card.id;
                          Future.delayed(const Duration(seconds: 4), () {
                            if (controller.pendingDeleteCardId.value == card.id) {
                              controller.pendingDeleteCardId.value = null;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Icon(Iconsax.trash,
                              size: 18.r, color: const Color(0xFF94A3B8)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  // Dynamic Card Setup Form (§5.2)
  Widget _buildCardSetupForm(
    ManualPaymentConfigModel config, {
    required bool isInitial,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isInitial ? 'Set up your bank card' : 'Add new bank card',
                style: GoogleFonts.lato(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (!isInitial)
                TextButton(
                  onPressed: () {
                    controller.isAddingNewCard.value = false;
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Label Input
          Text(
            'Card / Account Nickname (Required)',
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          TextField(
            controller: controller.cardLabelCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. My DBBL account',
              filled: true,
              fillColor: AppColor.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Dynamic fields from config (§2 & §5.2)
          ...config.withdrawalFields.map((f) {
            final ctrl = controller.getWithdrawFieldCtrl(f.id);
            final isNumeric = f.fieldType.toLowerCase() == 'numeric';

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${f.label}${f.required ? ' (Required)' : ''}',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  TextField(
                    controller: ctrl,
                    keyboardType:
                        isNumeric ? TextInputType.number : TextInputType.text,
                    inputFormatters: isNumeric
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(
                      hintText: f.label,
                      helperText: f.helpHint,
                      helperStyle: GoogleFonts.lato(
                        fontSize: 10.5.sp,
                        color: const Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: AppColor.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 10.h),

          ElevatedButton(
            onPressed: () async {
              final label = controller.cardLabelCtrl.text.trim();
              if (label.isEmpty) {
                showSnack('Validation Error', 'Please enter a card nickname');
                return;
              }

              final details = <String, dynamic>{};
              for (var f in config.withdrawalFields) {
                final val = controller.getWithdrawFieldCtrl(f.id).text.trim();
                if (f.required && val.isEmpty) {
                  showSnack('Validation Error', '${f.label} is required');
                  return;
                }
                if (val.isNotEmpty) {
                  details[f.id] = val;
                }
              }

              final success = await controller.createWithdrawalAccount(
                label: label,
                details: details,
              );

              if (success) {
                controller.cardLabelCtrl.clear();
                for (var c in controller.dynamicFieldCtrls.values) {
                  c.clear();
                }
                controller.isAddingNewCard.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: AppColor.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Save Bank Card',
              style: GoogleFonts.lato(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // §6 PIN Prompt and Withdrawal Flow
  Future<void> _handleWithdrawSubmit(BuildContext context) async {
    final amount = controller.enteredWithdrawAmount.value;
    if (amount <= 0) return;

    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Authorize Withdrawal',
      subtitle: 'Enter your 6-digit wallet PIN to authorize payout of ৳${amount.toStringAsFixed(2)}',
      onConfirm: (enteredPin) async {
        return await controller.executeWithdrawal(
          amount: amount,
          walletPin: enteredPin,
        );
      },
    );

    if (pin != null && pin.isNotEmpty) {
      controller.withdrawAmountCtrl.clear();
      controller.withdrawTab.value = 1; // switch to history tab
      walletCtrl.fetchWallets();
    }
  }

  // §6.2 Withdrawal History Tab
  Widget _buildWithdrawalHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Withdrawal Requests',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18.r, color: const Color(0xFF2563EB)),
              onPressed: () => controller.fetchWithdrawals(refresh: true),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          if (controller.isLoadingWithdrawals.value) {
            return SizedBox(
              height: 180.h,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }

          final list = controller.withdrawals;
          if (list.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(Iconsax.empty_wallet, size: 36.r, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 8.h),
                  Text(
                    'No withdrawal requests yet',
                    style: GoogleFonts.lato(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Your submitted withdrawals will appear here with payout status.',
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
            children: list.map((w) {
              Color statusBg = const Color(0xFFFEF3C7);
              Color statusColor = const Color(0xFFB45309);
              String statusLabel = 'Pending Approval';

              if (w.isPaid) {
                statusBg = const Color(0xFFDCFCE7);
                statusColor = const Color(0xFF15803D);
                statusLabel = 'Paid';
              } else if (w.isApproved) {
                statusBg = const Color(0xFFEFF6FF);
                statusColor = const Color(0xFF1D4ED8);
                statusLabel = 'Approved';
              } else if (w.isRejected) {
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
                          '৳${w.amount.toStringAsFixed(2)}',
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
                        if (w.fee > 0)
                          Text(
                            'Fee: ৳${w.fee.toStringAsFixed(2)} · Net: ৳${w.net.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'Net payout: ৳${w.net.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              color: AppColor.textSecondary,
                            ),
                          ),
                      ],
                    ),

                    // Admin Paid Message (§6.1)
                    if (w.paidMessage != null && w.paidMessage!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Message: ${w.paidMessage}',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: const Color(0xFF15803D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    // Reject Reason (§6.1)
                    if (w.rejectReason != null && w.rejectReason!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Reason: ${w.rejectReason}',
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
