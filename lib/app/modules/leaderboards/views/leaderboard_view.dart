import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/leaderboard_controller.dart';
import '../models/leaderboard_model.dart';
import 'widgets/my_progress_card.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

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
          'Leaderboards',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Conditions & Rewards',
            icon: Icon(
              Iconsax.info_circle,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.showConditionsSheet(context),
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
      body: Column(
        children: [
          // 1. Kind Toggle & Period Chips Header
          _buildFilterHeader(),

          // 2. Main content area
          Expanded(
            child: RefreshIndicator(
              color: AppColor.primary,
              onRefresh: () => controller.refreshAll(),
              child: Obx(() {
                if (controller.isLoading.value && controller.leaderboard.value == null) {
                  return Padding(
                    padding: EdgeInsets.all(16.r),
                    child: const SkeletonList(itemCount: 8),
                  );
                }

                final lb = controller.leaderboard.value;
                final entries = lb?.entries ?? [];
                final hasPool = lb?.pool != null;
                final myProg = controller.currentPeriodProgress;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(bottom: 30.h),
                  children: [
                    // My Progress Card (if logged in)
                    if (controller.hasAuth && myProg != null)
                      MyProgressCard(
                        progress: myProg,
                        pendingPoints: controller.myProgress.value?.pendingPoints ?? 0,
                        showStar: true,
                      ),

                    // Pool Summary Header (if pool is enabled)
                    if (hasPool) _buildPoolBanner(lb!.pool!),

                    // Your Position Strip (§12 - hidden when signed out or in seller tab)
                    if (controller.hasAuth &&
                        controller.selectedKind.value == 'customer' &&
                        myProg != null)
                      _buildYourPositionStrip(myProg),

                    // List Section
                    if (entries.isEmpty)
                      _buildEmptyState()
                    else ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36.w,
                              child: Text(
                                '#',
                                style: GoogleFonts.lato(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                controller.selectedKind.value == 'seller'
                                    ? 'Store'
                                    : 'Customer',
                                style: GoogleFonts.lato(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ),
                            if (hasPool) ...[
                              SizedBox(
                                width: 95.w,
                                child: Text(
                                  'Reward Pool',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                            ],
                            SizedBox(
                              width: 65.w,
                              child: Text(
                                'Points',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.lato(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...entries.map((entry) {
                        final isMe = controller.isMyEntry(entry);
                        final poolBand = hasPool
                            ? controller.getPoolBandForRank(entry.rank)
                            : null;
                        return _buildEntryRow(entry, isMe, poolBand, hasPool);
                      }),
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

  Widget _buildFilterHeader() {
    return Container(
      color: AppColor.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kind toggle: Customer vs Seller per §12
          Obx(() {
            final isCustomer = controller.selectedKind.value == 'customer';
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeKind('customer'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isCustomer ? AppColor.white : AppColor.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: isCustomer
                              ? [
                                  BoxShadow(
                                    color: AppColor.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Customers',
                            style: GoogleFonts.lato(
                              fontSize: 13.5.sp,
                              fontWeight:
                                  isCustomer ? FontWeight.bold : FontWeight.w600,
                              color: isCustomer
                                  ? AppColor.primaryDark
                                  : AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeKind('seller'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: !isCustomer ? AppColor.white : AppColor.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: !isCustomer
                              ? [
                                  BoxShadow(
                                    color: AppColor.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Sellers',
                            style: GoogleFonts.lato(
                              fontSize: 13.5.sp,
                              fontWeight:
                                  !isCustomer ? FontWeight.bold : FontWeight.w600,
                              color: !isCustomer
                                  ? AppColor.primaryDark
                                  : AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 10.h),

          // Period Chips
          Obx(() {
            final active = controller.selectedPeriod.value;
            const periods = [
              {'key': 'daily', 'label': 'Daily (24h)'},
              {'key': 'weekly', 'label': 'Weekly (7d)'},
              {'key': 'monthly', 'label': 'Monthly (30d)'},
              {'key': 'yearly', 'label': 'Yearly (365d)'},
            ];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: periods.map((p) {
                  final isSelected = active == p['key'];
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(p['label']!),
                      selected: isSelected,
                      onSelected: (_) => controller.changePeriod(p['key']!),
                      selectedColor: AppColor.primary,
                      backgroundColor: const Color(0xFFF8F9FA),
                      side: BorderSide(
                        color: isSelected ? AppColor.primary : AppColor.border,
                      ),
                      labelStyle: GoogleFonts.lato(
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColor.white : AppColor.textSecondary,
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildYourPositionStrip(MyProgressPeriodModel progress) {
    final rank = progress.star?.rank;
    final points = progress.points;
    if (rank == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.profile_circle, color: const Color(0xFF2563EB), size: 18.r),
              SizedBox(width: 8.w),
              Text(
                'Your Position: Rank #$rank',
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          Text(
            '$points pts',
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolBanner(LeaderboardPoolModel pool) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.gift, color: const Color(0xFFD97706), size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Reward Pool: ৳${pool.poolAmount.toStringAsFixed(2)}',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
          Text(
            '${pool.bands.length} Bands',
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(
    LeaderboardEntryModel entry,
    bool isMe,
    LeaderboardPoolBandModel? poolBand,
    bool showPool,
  ) {
    Widget rankWidget;
    if (entry.rank == 1) {
      rankWidget = _buildMedalBadge(const Color(0xFFF59E0B), '1');
    } else if (entry.rank == 2) {
      rankWidget = _buildMedalBadge(const Color(0xFF94A3B8), '2');
    } else if (entry.rank == 3) {
      rankWidget = _buildMedalBadge(const Color(0xFFB45309), '3');
    } else {
      rankWidget = SizedBox(
        width: 32.w,
        child: Text(
          '#${entry.rank}',
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF7ED) : AppColor.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isMe ? AppColor.primary : AppColor.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          rankWidget,
          SizedBox(width: 8.w),

          // Avatar / Icon
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: (entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty)
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: (entry.avatarUrl == null || entry.avatarUrl!.isEmpty)
                ? const Icon(
                    Icons.person,
                    color: Color(0xFF64748B),
                    size: 18,
                  )
                : null,
          ),
          SizedBox(width: 10.w),

          // Name & Phone / You badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'You',
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
                if (entry.maskedPhone != null && entry.maskedPhone!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    entry.maskedPhone!,
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Pool reward column
          if (showPool) ...[
            SizedBox(
              width: 95.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    poolBand != null
                        ? '${poolBand.key.toUpperCase()} · ${poolBand.pct}%'
                        : '—',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF059669),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (poolBand != null)
                    Text(
                      '৳${poolBand.poolAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
          ],

          // Points
          SizedBox(
            width: 65.w,
            child: Text(
              '${entry.points} pts',
              textAlign: TextAlign.right,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalBadge(Color color, String rank) {
    return Container(
      width: 28.r,
      height: 28.r,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rank,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.cup,
                color: AppColor.primary,
                size: 32.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No rankings posted yet',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Points will appear here after delivered orders settle.',
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
