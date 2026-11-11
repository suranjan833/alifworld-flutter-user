import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/my_transactions_controller.dart';

class MyTransactionsView extends GetView<MyTransactionsController> {
  const MyTransactionsView({super.key});

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

                  final pendingOrders = (controller.selectedWalletKind.value == 'customer_cashback' &&
                          controller.pendingPoints.value != null)
                      ? controller.pendingPoints.value!.orders
                      : <WalletPendingOrderModel>[];

                  if (controller.transactions.isEmpty && pendingOrders.isEmpty) {
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
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      children: [
                        // Pending cashback orders banner & items (shown above posted history)
                        if (pendingOrders.isNotEmpty) ...[
                          _buildPendingCashbackSection(pendingOrders),
                          SizedBox(height: 16.h),
                          Text(
                            'Posted History',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],

                        ...controller.transactions.map((tx) => _buildTransactionCard(tx)),

                        if (controller.isLoadingMore.value)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                      ],
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
                  color: AppColor.white,
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
      color: AppColor.white,
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
                            ? AppColor.white
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

  Widget _buildPendingCashbackSection(List<WalletPendingOrderModel> pendingOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Iconsax.clock, color: const Color(0xFFD97706), size: 18.r),
                SizedBox(width: 6.w),
                Text(
                  'Pending Cashback Orders',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${pendingOrders.length} Pending',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...pendingOrders.map((order) {
          return InkWell(
            onTap: () {
              if (order.orderId.isNotEmpty) {
                Get.toNamed(Routes.ORDER_DETAILS, arguments: order.orderId);
              }
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.box_time,
                      color: const Color(0xFFD97706),
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber.isNotEmpty
                              ? order.orderNumber
                              : 'Order #${order.orderId}',
                          style: GoogleFonts.lato(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${order.points} pending pts • Est: ৳${order.estimatedCashback.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        if (order.returnWindowEndsAt != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            'Return window closes: ${order.returnWindowEndsAt!.day}/${order.returnWindowEndsAt!.month}/${order.returnWindowEndsAt!.year}',
                            style: GoogleFonts.lato(
                              fontSize: 10.5.sp,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.r,
                    color: const Color(0xFFB45309),
                  ),
                ],
              ),
            ),
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
          // Direction arrow: green down-left for money in, red up-right for money out
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: tx.isCredit
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                tx.isCredit
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: tx.isCredit
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      Flexible(
                        child: Text(
                          tx.walletTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Balance after: ${tx.formattedBalanceAfter}',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: AppColor.textHint,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            tx.formattedAmount(symbol: controller.currencySymbol.value),
            style: GoogleFonts.lato(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.bold,
              color: tx.isCredit
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
