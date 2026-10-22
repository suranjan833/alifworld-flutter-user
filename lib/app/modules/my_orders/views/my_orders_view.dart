import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/no_internet_dialog.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../../../routes/app_pages.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../controllers/my_orders_controller.dart';
import '../models/order_model.dart';
import 'order_details_view.dart';

class MyOrdersView extends GetView<MyOrdersController> {
  const MyOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
          'My Orders',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.orders.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: const SkeletonList(itemCount: 4),
          );
        }

        if (controller.hasInternetError.value && controller.orders.isEmpty) {
          return RefreshIndicator(
            color: AppColor.primary,
            onRefresh: () => controller.refreshOrders(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.75.sh,
                child: NoInternetWidget(
                  onRetry: () => controller.fetchOrders(),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () => controller.refreshOrders(),
          child: Column(
            children: [
              // Filter Tabs
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const BouncingScrollPhysics(),
                  child: Obx(
                    () => Row(
                      children: List.generate(
                        controller.statuses.length,
                        (index) => _buildStatusTab(index),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Order Cards List
              Expanded(
                child: Obx(() {
                  final ordersList = controller.filteredOrders;

                  if (ordersList.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 0.6.sh,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80.r,
                                height: 80.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Iconsax.box_remove,
                                    size: 40.r,
                                    color: AppColor.textHint,
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                'No orders found',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'You haven\'t placed any orders in this section yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              SizedBox(height: 18.h),
                              ElevatedButton(
                                onPressed: () {
                                  if (Get.isRegistered<MainNavigationController>()) {
                                    Get.find<MainNavigationController>().changeTab(0);
                                  } else {
                                    Get.offAllNamed(Routes.MAIN_NAVIGATION);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 22.w,
                                    vertical: 10.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: Text(
                                  'Start Shopping',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: ordersList.length,
                    itemBuilder: (context, index) {
                      final order = ordersList[index];
                      return _buildOrderCard(order);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusTab(int index) {
    final isSelected = controller.selectedStatusIndex.value == index;

    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: InkWell(
        onTap: () => controller.changeStatusTab(index),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            controller.statuses[index],
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final items = order.items;
    final status = order.status;

    Color statusColor;
    Color statusBg;
    if (status == 'Delivered') {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
    } else if (status == 'In Progress') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    } else {
      statusColor = AppColor.error;
      statusBg = const Color(0xFFFEE2E2);
    }

    return InkWell(
      onTap: () => Get.to(() => OrderDetailsView(order: order)),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderId,
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Placed on ${order.date}',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          SizedBox(height: 12.h),

          // Items Preview
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            )
          else
            ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: const Color(0xFFF8F9FA),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.image.isNotEmpty
                        ? Image.network(
                            item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Iconsax.image,
                              size: 22.r,
                              color: AppColor.textSecondary,
                            ),
                          )
                        : Icon(
                            Iconsax.image,
                            size: 22.r,
                            color: AppColor.textSecondary,
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.lato(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Qty: ${item.quantity} • ৳${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          SizedBox(height: 12.h),

          // Total & Details Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Total: ',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: order.formattedTotal,
                      style: GoogleFonts.lato(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Get.to(() => OrderDetailsView(order: order)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.lato(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
