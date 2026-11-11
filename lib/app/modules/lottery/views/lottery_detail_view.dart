import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/lottery_controller.dart';
import '../models/lottery_model.dart';

class LotteryDetailView extends StatefulWidget {
  const LotteryDetailView({super.key});

  @override
  State<LotteryDetailView> createState() => _LotteryDetailViewState();
}

class _LotteryDetailViewState extends State<LotteryDetailView> {
  final controller = Get.find<LotteryController>();
  late String _lotteryId;

  @override
  void initState() {
    super.initState();
    _lotteryId = Get.arguments?.toString() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lotteryId.isNotEmpty) {
        controller.fetchLotteryDetail(_lotteryId);
      }
    });
  }

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
          'Draw Details',
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
            onPressed: () => controller.fetchLotteryDetail(_lotteryId),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value &&
            controller.activeLotteryDetail.value == null) {
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: const SkeletonList(itemCount: 4),
          );
        }

        final detail = controller.activeLotteryDetail.value;
        if (detail == null) {
          return Center(
            child: Text(
              'Lottery draw details not available',
              style: GoogleFonts.lato(fontSize: 14.sp, color: AppColor.textSecondary),
            ),
          );
        }

        final lottery = detail.lottery;
        final isDrawnOrEnded = lottery.status.toLowerCase() == 'drawn' ||
            lottery.status.toLowerCase() == 'ended';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 36.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Prize Header Card
              _buildPrizeHeroCard(lottery),

              // 2. Results button if drawn
              if (isDrawnOrEnded)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(Routes.LOTTERY_RESULTS, arguments: lottery.id);
                    },
                    icon: Icon(Iconsax.cup, size: 18.r, color: AppColor.white),
                    label: Text(
                      'View Draw Results & Winners',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: AppColor.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),

              // 3. Stats Grid
              _buildStatsGrid(lottery),

              SizedBox(height: 14.h),

              // 4. Ticket Purchase Section (Active draws)
              if (lottery.status.toLowerCase() == 'active')
                lottery.isSeller
                    ? _buildSellerLotteryNotice()
                    : _buildBuyTicketSection(detail),

              SizedBox(height: 18.h),

              // 5. My Tickets in this draw
              _buildMyTicketsSection(detail),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPrizeHeroCard(LotteryItemModel lottery) {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lottery.prizeImageUrl != null && lottery.prizeImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Image.network(
                lottery.prizeImageUrl!,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'PRIZE POOL: ৳${lottery.poolAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                        if (lottery.isSeller) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'SELLER DRAW',
                              style: GoogleFonts.lato(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      lottery.statusLine,
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  lottery.title,
                  style: GoogleFonts.lato(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                if (lottery.prizeTitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    lottery.prizeTitle!,
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ],
                if (lottery.description != null && lottery.description!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    lottery.description!,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      color: AppColor.textSecondary,
                      height: 1.4,
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

  Widget _buildStatsGrid(LotteryItemModel lottery) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              label: 'Ticket Price',
              value: '৳${lottery.ticketPrice.toStringAsFixed(2)}',
              icon: Iconsax.ticket,
              iconColor: AppColor.primary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildStatTile(
              label: 'Total Winners',
              value: lottery.winnerCountText,
              icon: Iconsax.crown,
              iconColor: const Color(0xFFF59E0B),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildStatTile(
              label: 'Tickets Sold',
              value: '${lottery.ticketCount}',
              icon: Iconsax.chart_2,
              iconColor: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20.r),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyTicketSection(LotteryDetailResponseModel detail) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Good-Luck Wallet Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buy Tickets',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.gift, color: const Color(0xFFBE185D), size: 14.r),
                    SizedBox(width: 4.w),
                    Text(
                      'Good-Luck: ৳${detail.goodLuckBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFBE185D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),
          Text(
            'Paid exclusively with Good-Luck bonus wallet balance.',
            style: GoogleFonts.lato(
              fontSize: 11.5.sp,
              color: AppColor.textSecondary,
            ),
          ),

          SizedBox(height: 16.h),

          // Quantity controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Quantity',
                style: GoogleFonts.lato(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => controller.decrementQty(),
                    ),
                    Obx(
                      () => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          '${controller.buyQty.value}',
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => controller.incrementQty(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Total Price Display
          Obx(() {
            final totalTaka = controller.buyTotalAmount;
            final hasBalance = controller.hasSufficientGoodLuck;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    Text(
                      '৳${totalTaka.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: (!hasBalance || controller.isBuying.value)
                        ? null
                        : () => controller.buyTickets(
                              context: context,
                              lotteryId: detail.lottery.id,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                    ),
                    child: controller.isBuying.value
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColor.white,
                            ),
                          )
                        : Text(
                            hasBalance
                                ? 'Buy Ticket(s) with PIN'
                                : 'Insufficient Good-Luck Balance',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: hasBalance ? AppColor.white : const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSellerLotteryNotice() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.shop, color: Colors.white, size: 22),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This lottery is for sellers.',
                  style: GoogleFonts.lato(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Tickets for this draw can only be purchased by approved sellers using seller Good-Luck balance.',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: const Color(0xFFB45309),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsSection(LotteryDetailResponseModel detail) {
    final tickets = detail.myTickets;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Tickets in this Draw',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              if (tickets != null && tickets.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${tickets.length} Bought',
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          if (!controller.hasAuth)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: TextButton(
                  onPressed: () => Get.toNamed(Routes.LOGIN),
                  child: const Text('Sign in to view your tickets'),
                ),
              ),
            )
          else if (tickets == null || tickets.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: Text(
                  'No tickets purchased for this draw yet.',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...tickets.map((t) => _buildTicketRow(t)),
        ],
      ),
    );
  }

  Widget _buildTicketRow(LotteryTicketModel ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ticket.isWinner ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: ticket.isWinner ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.ticket,
                color: ticket.isWinner ? const Color(0xFFD97706) : AppColor.primary,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                'Ticket #${ticket.ticketNumber}',
                style: GoogleFonts.lato(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          if (ticket.isWinner)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'WINNER #${ticket.winPosition ?? 1}${ticket.winPrize != null ? " • ৳${ticket.winPrize!.toStringAsFixed(0)}" : ""}',
                style: GoogleFonts.lato(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                ),
              ),
            )
          else
            Text(
              'Active',
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
        ],
      ),
    );
  }
}
