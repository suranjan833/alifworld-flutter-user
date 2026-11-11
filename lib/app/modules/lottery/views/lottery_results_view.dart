import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/lottery_controller.dart';
import '../models/lottery_model.dart';

class LotteryResultsView extends StatefulWidget {
  const LotteryResultsView({super.key});

  @override
  State<LotteryResultsView> createState() => _LotteryResultsViewState();
}

class _LotteryResultsViewState extends State<LotteryResultsView> {
  final controller = Get.find<LotteryController>();
  late String _lotteryId;

  @override
  void initState() {
    super.initState();
    _lotteryId = Get.arguments?.toString() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lotteryId.isNotEmpty) {
        controller.fetchLotteryResults(_lotteryId);
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
          'Draw Results',
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
            onPressed: () => controller.fetchLotteryResults(_lotteryId),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (controller.isResultsLoading.value &&
            controller.lotteryResults.value == null) {
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: const SkeletonList(itemCount: 4),
          );
        }

        final res = controller.lotteryResults.value;
        if (res == null) {
          return Center(
            child: Text(
              'Draw results unavailable',
              style: GoogleFonts.lato(fontSize: 14.sp, color: AppColor.textSecondary),
            ),
          );
        }

        final isDrawn = res.status.toLowerCase() == 'drawn';
        final winners = res.winners;

        // Collect caller's ticket numbers for this lottery from detail if present
        final myTickets = controller.activeLotteryDetail.value?.myTickets ?? [];
        final myTicketNumbers = myTickets.map((t) => t.ticketNumber).toSet();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildResultsHeaderCard(res),

              SizedBox(height: 16.h),

              if (!isDrawn || winners.isEmpty) ...[
                _buildPendingResultsCard(res),
              ] else ...[
                Text(
                  'Declared Winners',
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 10.h),

                ...winners.map((winner) {
                  final isMyWinningTicket = myTicketNumbers.contains(winner.ticketNumber);
                  return _buildWinnerCard(winner, isMyWinningTicket);
                }),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResultsHeaderCard(LotteryResultsResponseModel res) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  res.title,
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: res.status == 'drawn'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  res.status.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: res.status == 'drawn'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          if (res.prizeTitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              res.prizeTitle!,
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prize Pool: ৳${res.poolAmount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                res.winnerCount == 1 ? '1 Winner' : '${res.winnerCount} Winners',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingResultsCard(LotteryResultsResponseModel res) {
    final resultDateStr = res.resultAt != null
        ? '${res.resultAt!.day}/${res.resultAt!.month}/${res.resultAt!.year}'
        : 'scheduled date';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 36.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        children: [
          Icon(Iconsax.clock, color: const Color(0xFFD97706), size: 48.r),
          SizedBox(height: 14.h),
          Text(
            'Results are not published yet',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Winning tickets will be announced on $resultDateStr after the draw concludes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              color: AppColor.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(LotteryWinnerModel winner, bool isMyTicket) {
    final isFirst = winner.position == 1;
    final winnerUser = winner.winner;
    final displayName = (winnerUser?.name.isNotEmpty == true)
        ? winnerUser!.name
        : (winnerUser?.maskedPhone ?? 'Winner #${winner.position}');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFFFEF3C7)
            : (isMyTicket ? const Color(0xFFEFF6FF) : AppColor.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isFirst
              ? const Color(0xFFF59E0B)
              : (isMyTicket ? const Color(0xFF2563EB) : AppColor.border),
          width: (isFirst || isMyTicket) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Position Trophy / Badge
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: isFirst
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isFirst
                  ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
                  : Text(
                      '#${winner.position}',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 10.w),

          // Winner Avatar
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: (winnerUser?.avatarUrl != null && winnerUser!.avatarUrl!.isNotEmpty)
                ? NetworkImage(winnerUser.avatarUrl!)
                : null,
            child: (winnerUser?.avatarUrl == null || winnerUser!.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Color(0xFF64748B), size: 18)
                : null,
          ),
          SizedBox(width: 12.w),

          // Winner details + Ticket number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    if (isMyTicket) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'YOUR TICKET!',
                          style: GoogleFonts.lato(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (winnerUser?.maskedPhone != null &&
                    winnerUser!.maskedPhone!.isNotEmpty &&
                    winnerUser.maskedPhone != displayName) ...[
                  SizedBox(height: 2.h),
                  Text(
                    winnerUser.maskedPhone!,
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  'Ticket #${winner.ticketNumber}',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),

          // Prize
          Text(
            '৳${winner.prize.toStringAsFixed(2)}',
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: isFirst ? const Color(0xFF92400E) : AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}
