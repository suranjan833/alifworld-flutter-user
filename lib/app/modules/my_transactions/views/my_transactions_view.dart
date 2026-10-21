import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/my_transactions_controller.dart';

class MyTransactionsView extends GetView<MyTransactionsController> {
  const MyTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          'My Transactions',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Iconsax.refresh,
              color: AppColor.textPrimary,
              size: 20.r,
            ),
            onPressed: () => controller.fetchTransactions(refresh: true),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (!controller.hasAuth) {
          return _buildGuestPrompt();
        }

        return Column(
          children: [
            // Filter Chips Bar
            _buildFilterChips(),

            // Transactions List
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () => controller.fetchTransactions(refresh: true),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Padding(
                      padding: EdgeInsets.all(16.r),
                      child: const SkeletonList(itemCount: 6),
                    );
                  }

                  if (controller.transactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200 &&
                          !controller.isLoadingMore.value &&
                          controller.nextCursor.value != null) {
                        controller.fetchTransactions(refresh: false);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: controller.transactions.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.transactions.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }

                        final tx = controller.transactions[index];
                        return _buildTransactionCard(tx);
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGuestPrompt() {
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
                Iconsax.receipt_2,
                size: 48.r,
                color: AppColor.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Sign in to view transaction history',
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'View all debits, credits, refunds, and cashback transactions across your Alif wallets.',
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
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: SizedBox(
        height: 36.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.filterOptions.length,
          itemBuilder: (context, index) {
            final opt = controller.filterOptions[index];
            final label = opt['label']!;
            final kind = opt['kind']!;

            return Obx(() {
              final isSelected = controller.selectedWalletKind.value == kind;
              return GestureDetector(
                onTap: () => controller.selectFilter(kind),
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primary
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColor.primary
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.lato(
                        fontSize: 12.5.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColor.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400.h,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.receipt_item,
                size: 42.r,
                color: AppColor.textHint,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'No transactions found',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Transactions will appear here as you make purchases\nor earn wallet rewards.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
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
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayTitle,
                  style: GoogleFonts.lato(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      tx.formattedDate,
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
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
                      Text(
                        tx.walletTitle,
                        style: GoogleFonts.lato(
                          fontSize: 11.5.sp,
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            tx.formattedAmount(symbol: controller.currencySymbol.value),
            style: GoogleFonts.lato(
              fontSize: 14.5.sp,
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
}
