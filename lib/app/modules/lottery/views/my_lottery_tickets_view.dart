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

class MyLotteryTicketsView extends StatefulWidget {
  const MyLotteryTicketsView({super.key});

  @override
  State<MyLotteryTicketsView> createState() => _MyLotteryTicketsViewState();
}

class _MyLotteryTicketsViewState extends State<MyLotteryTicketsView> {
  final controller = Get.find<LotteryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyTickets(refresh: true);
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
          'My Lottery Tickets',
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
            onPressed: () => controller.fetchMyTickets(refresh: true),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        if (!controller.hasAuth) {
          return _buildGuestPrompt();
        }

        if (controller.isMyTicketsLoading.value && controller.myTickets.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: const SkeletonList(itemCount: 6),
          );
        }

        if (controller.myTickets.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () => controller.fetchMyTickets(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200 &&
                  !controller.isLoadingMoreTickets.value &&
                  controller.myTicketsCursor.value != null) {
                controller.fetchMyTickets(refresh: false);
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: controller.myTickets.length +
                  (controller.isLoadingMoreTickets.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.myTickets.length) {
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

                final item = controller.myTickets[index];
                return _buildTicketCard(item);
              },
            ),
          ),
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
            Icon(Iconsax.ticket, size: 50.r, color: AppColor.primary),
            SizedBox(height: 16.h),
            Text(
              'Sign in to view your tickets',
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Track purchased draw tickets and check winning announcements.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textSecondary),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.LOGIN),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('Log In / Register'),
            ),
          ],
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
              'No tickets found',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'You have not purchased any lottery tickets yet. Join an active draw from the Lottery list!',
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

  Widget _buildTicketCard(MyLotteryTicketItemModel item) {
    final dt = item.purchasedAt;
    final dateStr = dt != null
        ? '${dt.day}/${dt.month}/${dt.year}'
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: item.isWinner ? const Color(0xFFFEF3C7) : AppColor.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: item.isWinner ? const Color(0xFFF59E0B) : AppColor.border,
          width: item.isWinner ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  Icon(
                    Iconsax.ticket,
                    color: item.isWinner ? const Color(0xFFD97706) : AppColor.primary,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Ticket #${item.ticketNumber}',
                    style: GoogleFonts.lato(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
              if (item.isWinner)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'WINNER #${item.winPosition ?? 1}${item.winPrize != null ? " • ৳${item.winPrize!.toStringAsFixed(0)}" : ""}',
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  item.lottery?.status.toUpperCase() ?? 'ACTIVE',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),

          if (item.lottery != null) ...[
            SizedBox(height: 8.h),
            Text(
              item.lottery!.title,
              style: GoogleFonts.lato(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            if (item.lottery!.prizeTitle != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Prize: ${item.lottery!.prizeTitle!}',
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: AppColor.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],

          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (dateStr.isNotEmpty)
                Text(
                  'Purchased on $dateStr',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              if (item.lottery != null)
                GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.LOTTERY_DETAIL, arguments: item.lottery!.id);
                  },
                  child: Text(
                    'Draw Details →',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
