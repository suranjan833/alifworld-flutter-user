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

class LotteryListView extends GetView<LotteryController> {
  const LotteryListView({super.key});

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
          'Good-Luck Lottery',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'My Tickets',
            icon: Icon(
              Iconsax.ticket,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => Get.toNamed(Routes.MY_LOTTERY_TICKETS),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Iconsax.refresh,
              color: AppColor.textPrimary,
              size: 20.r,
            ),
            onPressed: () => controller.fetchLotteries(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Active / Drawn)
          Container(
            color: AppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Container(
              height: 40.h,
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Obx(() {
                final active = controller.activeStatusFilter.value;
                return Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab(
                        label: 'All',
                        isSelected: active == 'all',
                        onTap: () => controller.setStatusFilter('all'),
                      ),
                    ),
                    Expanded(
                      child: _buildFilterTab(
                        label: 'Active Draws',
                        isSelected: active == 'active',
                        onTap: () => controller.setStatusFilter('active'),
                      ),
                    ),
                    Expanded(
                      child: _buildFilterTab(
                        label: 'Past Draws',
                        isSelected: active == 'drawn',
                        onTap: () => controller.setStatusFilter('drawn'),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          // Main list
          Expanded(
            child: RefreshIndicator(
              color: AppColor.primary,
              onRefresh: () => controller.fetchLotteries(),
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.activeLotteries.isEmpty &&
                    controller.pastLotteries.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(16.r),
                    child: const SkeletonList(itemCount: 4),
                  );
                }

                final filter = controller.activeStatusFilter.value;
                final showActive = filter == 'all' || filter == 'active';
                final showPast = filter == 'all' || filter == 'drawn';

                final activeItems = controller.activeLotteries;
                final pastItems = controller.pastLotteries;

                if ((showActive && activeItems.isEmpty) && (showPast && pastItems.isEmpty)) {
                  return _buildEmptyState();
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  children: [
                    // Active Lotteries Section
                    if (showActive) ...[
                      if (filter == 'all') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Lotteries',
                              style: GoogleFonts.lato(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Text(
                              '${activeItems.length} Available',
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                      if (activeItems.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColor.border),
                          ),
                          child: Center(
                            child: Text(
                              'No active draws currently running. Check back soon!',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...activeItems.map((item) => _buildLotteryCard(item)),
                      if (filter == 'all') SizedBox(height: 16.h),
                    ],

                    // Past Lotteries Section
                    if (showPast) ...[
                      if (filter == 'all') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Past Lotteries',
                              style: GoogleFonts.lato(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Text(
                              '${pastItems.length} Drawn',
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                      if (pastItems.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColor.border),
                          ),
                          child: Center(
                            child: Text(
                              'No past draws recorded yet.',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...pastItems.map((item) => _buildPastLotteryCard(item)),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColor.primary : AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotteryCard(LotteryItemModel item) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(Routes.LOTTERY_DETAIL, arguments: item.id);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (item.isSeller) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'SELLER',
                              style: GoogleFonts.lato(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: item.status == 'active'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: item.status == 'active'
                                  ? const Color(0xFF16A34A)
                                  : AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // Prize Banner / Title
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.gift, color: AppColor.white, size: 20.r),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.prizeTitle ?? 'Grand Prize',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              'Pool: ৳${item.poolAmount.toStringAsFixed(2)} • ${item.winnerCountText}',
                              style: GoogleFonts.lato(
                                fontSize: 11.5.sp,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Details Row: Ticket Price + Status line + Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ticket Price',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        Text(
                          '৳${item.ticketPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.statusLine,
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        Text(
                          '${item.ticketCount} tickets sold',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastLotteryCard(LotteryItemModel item) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(Routes.LOTTERY_RESULTS, arguments: item.id);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'DRAWN',
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Prize Pool & Draw Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.prizeTitle ?? 'Prize Pool: ৳${item.poolAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    Text(
                      item.statusLine,
                      style: GoogleFonts.lato(
                        fontSize: 11.5.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Winning Users List (if present)
                if (item.winners.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SizedBox(height: 10.h),
                  Text(
                    'Winners Announced',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ...item.winners.take(3).map((w) {
                    final winnerUser = w.winner;
                    final displayName = (winnerUser?.name.isNotEmpty == true)
                        ? winnerUser!.name
                        : (winnerUser?.maskedPhone ?? 'Winner #${w.position}');
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12.r,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: (winnerUser?.avatarUrl != null && winnerUser!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(winnerUser.avatarUrl!)
                                : null,
                            child: (winnerUser?.avatarUrl == null || winnerUser!.avatarUrl!.isEmpty)
                                ? const Icon(Icons.person, color: Color(0xFF64748B), size: 12)
                                : null,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '#${w.ticketNumber} • ৳${w.prize.toStringAsFixed(0)}',
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.winnerCountText} • ${item.ticketCount} tickets',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Results',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.ticket, color: AppColor.primary, size: 32.r),
            ),
            SizedBox(height: 16.h),
            Text(
              'No lotteries found',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Check back soon for upcoming Good-Luck campaign draws and exciting prizes!',
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
}
