import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../controllers/advanced_shopping_controller.dart';
import '../models/advanced_shopping_model.dart';

class AdvancedShoppingView extends GetView<AdvancedShoppingController> {
  const AdvancedShoppingView({super.key});

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
          'Advance Shopping',
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
            onPressed: () => controller.refreshAll(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          // 1. Tab Selector (Packages Store / My Packages)
          Container(
            color: AppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Container(
              height: 42.h,
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Obx(() {
                final tab = controller.selectedTab.value;
                final activeHoldingsCount =
                    controller.holdings.where((h) => h.isActive).length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildTopTab(
                        label: 'Packages Store',
                        icon: Iconsax.box_tick,
                        isSelected: tab == 0,
                        onTap: () => controller.selectedTab.value = 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTopTab(
                        label: activeHoldingsCount > 0
                            ? 'My Packages ($activeHoldingsCount)'
                            : 'My Packages',
                        icon: Iconsax.wallet_check,
                        isSelected: tab == 1,
                        onTap: () => controller.selectedTab.value = 1,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          // 2. Tab Content
          Expanded(
            child: Obx(() {
              if (controller.selectedTab.value == 0) {
                return _buildPackagesStoreTab(context);
              } else {
                return _buildMyHoldingsTab(context);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
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
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15.r,
                color: isSelected ? AppColor.primary : AppColor.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColor.primary : AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 0: PACKAGES STORE
  // -------------------------------------------------------------
  Widget _buildPackagesStoreTab(BuildContext context) {
    if (controller.isLoadingPackages.value && controller.packages.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: const SkeletonList(itemCount: 4),
      );
    }

    if (controller.packages.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.fetchPackages(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Column(
                children: [
                  Icon(Iconsax.box_remove, size: 54.r, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 16.h),
                  Text(
                    'No Packages Available',
                    style: GoogleFonts.lato(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'New advance shopping packages will be listed soon.',
                    style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () => controller.fetchPackages(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemCount: controller.packages.length,
        itemBuilder: (context, index) {
          final pkg = controller.packages[index];
          return _buildPackageCard(context, pkg);
        },
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, AdvancedShoppingPackageModel pkg) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image or Banner
          if (pkg.imageUrl != null && pkg.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              child: Image.network(
                pkg.imageUrl!,
                height: 130.h,
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
                // Top Row: Title + Interval Capsule
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pkg.title,
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        pkg.intervalTitle,
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),

                if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    pkg.description!,
                    style: GoogleFonts.lato(
                      fontSize: 12.5.sp,
                      color: AppColor.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],

                SizedBox(height: 14.h),

                // Metrics Grid (Price, Rate, Hold Term, Projected Profit)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: GoogleFonts.lato(
                                fontSize: 11.sp,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '৳${pkg.price.toStringAsFixed(0)}',
                              style: GoogleFonts.lato(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32.h, color: const Color(0xFFE2E8F0)),
                      // Rate
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Annual Rate',
                                style: GoogleFonts.lato(
                                  fontSize: 11.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${pkg.annualRatePct}% p.a.',
                                style: GoogleFonts.lato(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 32.h, color: const Color(0xFFE2E8F0)),
                      // Term
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hold Term',
                                style: GoogleFonts.lato(
                                  fontSize: 11.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${pkg.holdDays} Days',
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Profit highlight banner
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.money_recive, size: 16.r, color: const Color(0xFF059669)),
                      SizedBox(width: 6.w),
                      Text(
                        'Projected Profit: ',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        '৳${pkg.projectedInterest.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Wallet Routing + Cancellation Info
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 13.r, color: AppColor.textSecondary),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Profit to ${pkg.interestWalletTitle} • Principal to ${pkg.releaseWalletTitle}',
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 13.r, color: AppColor.textSecondary),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Cancellation fee: ৳${pkg.cancelFlat.toStringAsFixed(0)} flat + ${pkg.cancelPct}%',
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Buy Action Row
                Row(
                  children: [
                    if (pkg.myActiveCount > 0) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          pkg.maxPerUser != null
                              ? '${pkg.myActiveCount}/${pkg.maxPerUser} Active'
                              : '${pkg.myActiveCount} Active',
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (pkg.isLimitReached || pkg.isSoldOut || controller.isBuying.value)
                            ? null
                            : () => controller.buyPackage(context, pkg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                pkg.isLimitReached
                                    ? 'Limit Reached'
                                    : pkg.isSoldOut
                                        ? 'Sold Out'
                                        : 'Buy Package • ৳${pkg.price.toStringAsFixed(0)}',
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: (pkg.isLimitReached || pkg.isSoldOut)
                                      ? const Color(0xFF94A3B8)
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MY HOLDINGS (MY PACKAGES)
  // -------------------------------------------------------------
  Widget _buildMyHoldingsTab(BuildContext context) {
    if (!controller.hasAuth) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.wallet_2, size: 50.r, color: AppColor.primary),
              SizedBox(height: 16.h),
              Text(
                'Sign in to view your packages',
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Track your active investments, profit payout timeline, and maturity status.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textSecondary),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.LOGIN),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Sign In', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.isLoadingHoldings.value && controller.holdings.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: const SkeletonList(itemCount: 4),
      );
    }

    final items = controller.filteredHoldings;

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () => controller.fetchHoldings(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        children: [
          // Locked Balance Banner
          _buildLockedBalanceBanner(),

          SizedBox(height: 14.h),

          // Filter Chips (All, Active, Completed, Cancelled)
          _buildFilterChips(),

          SizedBox(height: 14.h),

          if (items.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColor.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Iconsax.box_1, size: 44.r, color: const Color(0xFF94A3B8)),
                    SizedBox(height: 12.h),
                    Text(
                      'No ${controller.holdingFilter.value.capitalizeFirst} Packages',
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Explore available packages in the store tab.',
                      style: GoogleFonts.lato(fontSize: 12.5.sp, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...items.map((holding) => _buildHoldingCard(context, holding)),
        ],
      ),
    );
  }

  Widget _buildLockedBalanceBanner() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOCKED IN PACKAGES',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Icon(Iconsax.lock, color: const Color(0xFFF59E0B), size: 16.r),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '৳${controller.lockedBalance.toStringAsFixed(2)}',
            style: GoogleFonts.lato(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Principal returns automatically to your release wallet upon maturity.',
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              color: const Color(0xFFCBD5E1),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filter = controller.holdingFilter.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'All (${controller.holdings.length})', filter == 'all'),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'active',
            'Active (${controller.holdings.where((h) => h.isActive).length})',
            filter == 'active',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'completed',
            'Completed (${controller.holdings.where((h) => h.isCompleted).length})',
            filter == 'completed',
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'cancelled',
            'Cancelled (${controller.holdings.where((h) => h.isCancelled).length})',
            filter == 'cancelled',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.holdingFilter.value = value,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : AppColor.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, AdvancedShoppingHoldingModel holding) {
    final title = holding.package?.title ?? 'Advance Shopping Package';
    final isExpanded = false.obs;

    Color statusBg;
    Color statusText;
    if (holding.isActive) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
    } else if (holding.isCompleted) {
      statusBg = const Color(0xFFDBEAFE);
      statusText = const Color(0xFF2563EB);
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFDC2626);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  holding.status.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusText,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Price & Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Principal: ৳${holding.price.toStringAsFixed(0)}',
                style: GoogleFonts.lato(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                '${holding.annualRatePct}% p.a. • ${holding.interestInterval.capitalizeFirst}',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Progress Bar (Day progress)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${holding.daysReceived} of ${holding.holdDays}',
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  Text(
                    holding.isActive
                        ? '${holding.daysRemaining} days remaining'
                        : holding.status.toUpperCase(),
                    style: GoogleFonts.lato(
                      fontSize: 11.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: holding.progressRatio,
                  minHeight: 6.h,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    holding.isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Earnings Summary Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credited Profit',
                      style: GoogleFonts.lato(fontSize: 11.sp, color: AppColor.textSecondary),
                    ),
                    Text(
                      '৳${holding.totalCredited.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Projected Total',
                      style: GoogleFonts.lato(fontSize: 11.sp, color: AppColor.textSecondary),
                    ),
                    Text(
                      '৳${holding.projectedProfit.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (holding.nextCreditAt != null && holding.isActive) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Iconsax.clock, size: 13.r, color: const Color(0xFF2563EB)),
                SizedBox(width: 4.w),
                Text(
                  'Next profit payout: ${_formatDate(holding.nextCreditAt!)}',
                  style: GoogleFonts.lato(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],

          if (holding.isCancelled && holding.cancelChargeMinor != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Cancelled: Fee ৳${(holding.cancelChargeMinor! / 100).toStringAsFixed(2)} deducted • Net ৳${((holding.cancelNetMinor ?? 0) / 100).toStringAsFixed(2)} returned to ${holding.releaseWalletTitle}',
                style: GoogleFonts.lato(
                  fontSize: 11.sp,
                  color: const Color(0xFFBE123C),
                ),
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // Expandable Credit Timeline Button
          if (holding.credits.isNotEmpty) ...[
            Obx(() => Column(
                  children: [
                    InkWell(
                      onTap: () => isExpanded.value = !isExpanded.value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payout Timeline (${holding.credits.length} Slices)',
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            Icon(
                              isExpanded.value
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18.r,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded.value) ...[
                      SizedBox(height: 8.h),
                      ...holding.credits.map((slice) => _buildCreditSliceRow(slice)),
                    ],
                  ],
                )),
          ],

          // Cancel button (Active only)
          if (holding.isActive) ...[
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _showCancelConfirmDialog(context, holding),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  'Cancel Package',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditSliceRow(AdvancedShoppingCreditItemModel slice) {
    Color badgeBg;
    Color badgeColor;
    if (slice.isCredited) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
    } else if (slice.isPending) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFB45309);
    } else {
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
    }

    final dateStr = slice.dueAt != null ? _formatDate(slice.dueAt!) : 'Scheduled';

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                slice.isCredited
                    ? Icons.check_circle_rounded
                    : (slice.isPending ? Icons.schedule_rounded : Icons.cancel_rounded),
                size: 14.r,
                color: badgeColor,
              ),
              SizedBox(width: 6.w),
              Text(
                dateStr,
                style: GoogleFonts.lato(fontSize: 11.5.sp, color: AppColor.textPrimary),
              ),
              Text(
                ' (${slice.daysCovered}d)',
                style: GoogleFonts.lato(fontSize: 11.sp, color: AppColor.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '৳${slice.amount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  slice.status.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(
    BuildContext context,
    AdvancedShoppingHoldingModel holding,
  ) {
    final charge = holding.cancelChargePreview;
    final net = holding.cancelNetPreview;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
            Text(
              'Cancel Package Confirmation',
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancelling returns ৳${net.toStringAsFixed(2)} to your ${holding.releaseWalletTitle} after ৳${charge.toStringAsFixed(2)} charges.',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Interest already credited (৳${holding.totalCredited.toStringAsFixed(2)}) stays with you in your interest wallet.',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('Keep Package', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.cancelHolding(context, holding);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('Confirm Cancel', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
