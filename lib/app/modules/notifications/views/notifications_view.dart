import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
          'Notifications',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.ticket, size: 20.r, color: AppColor.textPrimary),
            onPressed: () => controller.markAllAsRead(),
          ),
        ],
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const SkeletonList(itemCount: 4);
        }
        if (controller.notificationsList.isEmpty) {
          return Center(
            child: Text(
              'No notifications',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                color: AppColor.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.r),
          itemCount: controller.notificationsList.length,
          itemBuilder: (context, index) {
            final notif = controller.notificationsList[index];
            final isRead = notif['isRead'] as bool;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isRead ? AppColor.white : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isRead
                      ? AppColor.transparent
                      : AppColor.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.notification_bing,
                    color: isRead
                        ? AppColor.textSecondary
                        : AppColor.primaryDark,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notif['body'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            color: AppColor.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          notif['time'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: AppColor.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
