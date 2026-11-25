import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/leaderboard_controller.dart';
import 'widgets/leaderboard_entry_tile.dart';
import 'widgets/leaderboard_podium_widget.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard',
              style: GoogleFonts.lato(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              'Activity & rankings updated in real-time',
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Conditions & Rewards',
            icon: Icon(
              Icons.info_outline_rounded,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.showConditionsSheet(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColor.textPrimary,
              size: 22.r,
            ),
            onPressed: () => controller.refreshAll(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          // 1. Period Filter Tabs (Daily, Weekly, Monthly, Yearly)
          _buildPeriodFilterHeader(),

          // 2. Main Content
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

                final entries = controller.leaderboard.value?.entries ?? [];
                final listEntries = controller.filteredListEntries;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(bottom: 30.h),
                  children: [
                    // Sticky "Your Position" Strip
                    if (controller.hasAuth) _buildYourPositionStrip(),

                    // Olympic Top 3 Podium (when entries available)
                    if (entries.isNotEmpty) const LeaderboardPodiumWidget(),

                    // Star Band Filter Pills
                    if (entries.isNotEmpty) _buildBandFilterChips(),

                    // Empty State or List Section
                    if (entries.isEmpty)
                      _buildEmptyState()
                    else if (listEntries.isEmpty)
                      _buildNoFilteredEntries()
                    else ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                        child: Text(
                          controller.selectedBandFilter.value == 'all'
                              ? 'RANKINGS (#4 - #100)'
                              : 'FILTERED RANKINGS',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      ...listEntries.map((entry) {
                        final isMe = controller.isMyEntry(entry);
                        final band = controller.getBandForRank(entry.rank);
                        return LeaderboardEntryTile(
                          entry: entry,
                          isMe: isMe,
                          band: band,
                        );
                      }),
                    ],

                    // Bottom Settlement Notice
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15.r,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Rankings settle at the end of each calendar period.',
                            style: GoogleFonts.lato(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Obx(() {
        final active = controller.selectedPeriod.value;
        const periods = [
          {'key': 'daily', 'label': 'Daily'},
          {'key': 'weekly', 'label': 'Weekly'},
          {'key': 'monthly', 'label': 'Monthly'},
          {'key': 'yearly', 'label': 'Yearly'},
        ];

        return Row(
          children: periods.map((p) {
            final isSelected = active == p['key'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: GestureDetector(
                  onTap: () => controller.changePeriod(p['key']!),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFF621C), Color(0xFFEA580C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p['label']!,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildYourPositionStrip() {
    return Obx(() {
      final myProg = controller.currentPeriodProgress;
      final rank = myProg?.star?.rank;
      final totalRanked = myProg?.star?.totalRanked ?? 0;
      final points = myProg?.points ?? 0;

      final isRanked = rank != null && rank > 0;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: const Color(0xFF2563EB),
                  size: 18.r,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                isRanked
                    ? 'Your Position: #$rank of ${_formatNumber(totalRanked)} · ${_formatNumber(points)} Points'
                    : 'Your Position: Unranked (Earn points to enter leaderboard)',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBandFilterChips() {
    return Obx(() {
      final active = controller.selectedBandFilter.value;
      final bands = controller.availableBands;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('all', 'All', active == 'all'),
              ...bands.map((b) {
                String label;
                if (b.key == 'mega_star') {
                  label = '👑 Mega Star #${b.from}-${b.to}';
                } else if (b.key == 'super_star') {
                  label = '🥈 Super Star #${b.from}-${b.to}';
                } else {
                  label = '⭐ Star #${b.from}-${b.to}';
                }
                return _buildFilterChip(b.key, label, active == b.key);
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip(String key, String label, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () => controller.changeBandFilter(key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(24.r),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48.r, color: const Color(0xFFCBD5E1)),
          SizedBox(height: 12.h),
          Text(
            'No Leaderboard Entries',
            style: GoogleFonts.lato(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
          SizedBox(height: 6.h),
          Text(
            'Rankings will appear as customers earn posted points in this period.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12.sp, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilteredEntries() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          'No participants found in this tier.',
          style: GoogleFonts.lato(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
