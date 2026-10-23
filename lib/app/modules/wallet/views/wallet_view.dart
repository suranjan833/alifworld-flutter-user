import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColor.textPrimary,
            size: 24.r,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Wallet',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'All Transactions',
            icon: Icon(
              Iconsax.receipt_item,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => Get.toNamed(Routes.MY_TRANSACTIONS),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Iconsax.refresh,
              color: AppColor.textPrimary,
              size: 20.r,
            ),
            onPressed: () => controller.refreshAll(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (!controller.hasAuth) {
          return _buildGuestLoginPrompt();
        }

        if (controller.isLoading.value && controller.wallets.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: const SkeletonList(itemCount: 4),
          );
        }

        return RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () => controller.refreshAll(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(bottom: 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Balance Card
                _buildHeroBalanceCard(context),

                SizedBox(height: 20.h),

                // 2. Wallets Grid Section Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Wallets',
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        '${controller.wallets.length} Wallets',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Multi-Wallet Cards Carousel
                _buildWalletsHorizontalList(context),

                SizedBox(height: 20.h),

                // 3. Advance Shopping Promotion Banner
                _buildAdvanceShoppingBanner(context),

                SizedBox(height: 24.h),

                // 4. Transactions Section
                _buildTransactionsSection(),

                SizedBox(height: 24.h),

                // 5. Benefits & Perks
                _buildWalletBenefitsSection(),

                SizedBox(height: 24.h),

                // 6. Wallet Security & FAQs
                _buildWalletFaqSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGuestLoginPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.wallet_2,
                size: 48.r,
                color: AppColor.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Sign in to access your wallet',
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'View balances across your 10 specialized customer wallets, track transactions, and manage checkout credits.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => controller.navigateToLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Log In / Register',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
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
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Iconsax.wallet_2,
                        color: AppColor.primary,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Alif Main Wallet',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        color: const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.MY_TRANSACTIONS),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'History',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16.r,
                          color: AppColor.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Obx(
              () => Text(
                '${controller.currencySymbol.value} ${controller.mainBalance.value.toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Across All Wallets',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Obx(
                    () => Text(
                      '${controller.currencySymbol.value} ${controller.totalBalance.value.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDepositSheet(context),
                    icon: Icon(Iconsax.add_circle, size: 16.r, color: AppColor.white),
                    label: Text(
                      'Deposit',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWithdrawSheet(context),
                    icon: Icon(Iconsax.export_1, size: 16.r, color: AppColor.white),
                    label: Text(
                      'Withdraw',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.white,
                      side: BorderSide(color: AppColor.white.withValues(alpha: 0.3)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsHorizontalList(BuildContext context) {
    return SizedBox(
      height: 136.h,
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemCount: controller.wallets.length,
          itemBuilder: (context, index) {
            final w = controller.wallets[index];
            final isSelected = controller.selectedWalletKind.value == w.kind;

            return GestureDetector(
              onTap: () => controller.selectWalletFilter(w.kind),
              onLongPress: () => _showWalletDetailsSheet(context, w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 148.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: w.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: isSelected
                      ? Border.all(color: AppColor.primary, width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColor.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            w.icon,
                            color: AppColor.white,
                            size: 16.r,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'FILTERED',
                              style: GoogleFonts.lato(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.white.withValues(alpha: 0.85),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${controller.currencySymbol.value} ${w.balance.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(Routes.MY_TRANSACTIONS),
                child: Text(
                  'View All',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Wallet filter indicator if active
        Obx(() {
          if (controller.selectedWalletKind.value.isEmpty) {
            return const SizedBox.shrink();
          }
          final kind = controller.selectedWalletKind.value;
          final w = controller.wallets.firstWhereOrNull((e) => e.kind == kind);
          return Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 10.h),
            child: Row(
              children: [
                Text(
                  'Showing transactions for: ',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        w?.title ?? kind,
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryDark,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () => controller.selectWalletFilter(''),
                        child: Icon(
                          Icons.close,
                          size: 14.r,
                          color: AppColor.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Transactions list or empty state
        Obx(() {
          if (controller.isTransactionsLoading.value) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const SkeletonList(itemCount: 3),
            );
          }

          if (controller.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.receipt_2,
                      size: 40.r,
                      color: AppColor.textHint,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'No transactions found',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        color: AppColor.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: controller.transactions.length,
            itemBuilder: (context, index) {
              final tx = controller.transactions[index];
              return _buildTransactionCard(tx);
            },
          );
        }),
      ],
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: tx.isCredit
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                tx.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: tx.isCredit
                    ? const Color(0xFF16A34A)
                    : AppColor.textPrimary,
                size: 20.r,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Text(
                      tx.formattedDate,
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    if (tx.walletKind.isNotEmpty) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          tx.walletTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            tx.formattedAmount(symbol: controller.currencySymbol.value),
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: tx.isCredit
                  ? const Color(0xFF16A34A)
                  : AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositSheet(BuildContext context) {
    final amountController = TextEditingController();
    final presets = [100.0, 500.0, 1000.0, 5000.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColor.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deposit Funds',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Advance Shopping',
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Add advance shopping funds for guaranteed discounts and fast checkout.',
              style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.textSecondary),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.lato(fontSize: 22.sp, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${controller.currencySymbol.value} ',
                prefixStyle: GoogleFonts.lato(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
                hintText: '0.00',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColor.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColor.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: presets.map((p) {
                return ActionChip(
                  label: Text('+${controller.currencySymbol.value}${p.toInt()}'),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                  onPressed: () {
                    amountController.text = p.toStringAsFixed(0);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isSubmittingAction.value
                      ? null
                      : () async {
                          final val = double.tryParse(amountController.text.trim()) ?? 0.0;
                          final ok = await controller.depositAdvanceShopping(val);
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: controller.isSubmittingAction.value
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(color: AppColor.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm Deposit',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final amountController = TextEditingController();
    final advWallet = controller.wallets.firstWhereOrNull((w) => w.kind == 'customer_advanced_shopping');
    final availableBal = advWallet?.balance ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColor.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdraw Funds',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Advance Shopping',
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  'Available to withdraw: ',
                  style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.textSecondary),
                ),
                Text(
                  '${controller.currencySymbol.value} ${availableBal.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.lato(fontSize: 22.sp, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${controller.currencySymbol.value} ',
                prefixStyle: GoogleFonts.lato(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
                hintText: '0.00',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColor.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColor.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (availableBal > 0)
                  ActionChip(
                    label: const Text('All Balance'),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                    onPressed: () {
                      amountController.text = availableBal.toStringAsFixed(2);
                    },
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isSubmittingAction.value
                      ? null
                      : () async {
                          final val = double.tryParse(amountController.text.trim()) ?? 0.0;
                          final ok = await controller.withdrawAdvanceShopping(val);
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: controller.isSubmittingAction.value
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(color: AppColor.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm Withdrawal',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDetailsSheet(BuildContext context, WalletItemModel wallet) {
    controller.fetchSingleWallet(wallet.kind);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColor.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: wallet.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(wallet.icon, color: AppColor.white, size: 24.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.title,
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Category: ${wallet.shortTitle}',
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColor.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Available Balance',
                    style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.textSecondary),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${controller.currencySymbol.value} ${wallet.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'About this Wallet',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              wallet.description,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            if (wallet.kind == 'customer_advanced_shopping') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showDepositSheet(context);
                      },
                      icon: Icon(Iconsax.add_circle, size: 16.r, color: AppColor.white),
                      label: Text(
                        'Deposit',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showWithdrawSheet(context);
                      },
                      icon: Icon(Iconsax.export_1, size: 16.r, color: AppColor.textPrimary),
                      label: Text(
                        'Withdraw',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: AppColor.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  'Last 3 Entries',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(() {
              if (controller.isSingleWalletLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (controller.activeSingleTransactions.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'No transaction history for this wallet',
                    style: GoogleFonts.lato(fontSize: 12.sp, color: AppColor.textHint),
                  ),
                );
              }
              return Column(
                children: controller.activeSingleTransactions.take(3).map((tx) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tx.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          tx.formattedAmount(symbol: controller.currencySymbol.value),
                          style: GoogleFonts.lato(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: tx.isCredit ? const Color(0xFF16A34A) : AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  controller.selectWalletFilter(wallet.kind);
                },
                icon: const Icon(Iconsax.filter, size: 16),
                label: Text(
                  'Filter Transactions by this Wallet',
                  style: GoogleFonts.lato(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceShoppingBanner(BuildContext context) {
    final advWallet = controller.wallets.firstWhereOrNull((w) => w.kind == 'customer_advanced_shopping');
    final bal = advWallet?.balance ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.discount_shape, color: AppColor.white, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advance Shopping Balance',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${controller.currencySymbol.value} ${bal.toStringAsFixed(2)} available with exclusive discounts.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: () => _showDepositSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: AppColor.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(
                'Top Up',
                style: GoogleFonts.lato(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletBenefitsSection() {
    final benefits = [
      {
        'title': 'Instant Zero-Fee Checkout',
        'desc': 'Skip OTPs and gateway processing by paying directly from your Alif Wallets.',
        'icon': Iconsax.flash_1,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Guaranteed Advance Discounts',
        'desc': 'Deposit funds in Advance Shopping to unlock exclusive tier savings.',
        'icon': Iconsax.percentage_circle,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Instant Refund Protection',
        'desc': 'Cancelled or returned orders are refunded immediately back into your wallet balance.',
        'icon': Iconsax.shield_tick,
        'color': const Color(0xFF10B981),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Use Alif Wallet?',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          ...benefits.map((b) {
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColor.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: (b['color'] as Color).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      b['icon'] as IconData,
                      size: 18.r,
                      color: b['color'] as Color,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['title'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          b['desc'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            color: AppColor.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWalletFaqSection() {
    final faqs = [
      {
        'q': 'How does Advance Shopping work?',
        'a': 'Advance Shopping lets you pre-fund your purchases in exchange for special pricing. You can also withdraw funds at any time.',
      },
      {
        'q': 'Can I withdraw my Cashback or Bonus balances?',
        'a': 'Cashback and club bonuses are designated for shopping discounts across the platform and apply automatically at checkout.',
      },
      {
        'q': 'Are my wallet balances safe?',
        'a': 'Yes, all wallet transactions are secured with end-to-end encryption, transactional audits, and bank-grade data security.',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.info_circle, size: 20.r, color: AppColor.primary),
                SizedBox(width: 8.w),
                Text(
                  'Wallet Help & FAQs',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...faqs.map((f) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['q']!,
                      style: GoogleFonts.lato(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      f['a']!,
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        color: AppColor.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
