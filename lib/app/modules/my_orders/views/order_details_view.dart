import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../controllers/my_orders_controller.dart';
import '../models/order_model.dart';

class OrderDetailsView extends StatefulWidget {
  final OrderModel? order;

  const OrderDetailsView({super.key, this.order});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  late final Rx<OrderModel> orderRx;
  final isLoading = false.obs;
  final isCancelling = false.obs;

  @override
  void initState() {
    super.initState();
    OrderModel initialOrder;
    if (widget.order != null) {
      initialOrder = widget.order!;
    } else if (Get.arguments is OrderModel) {
      initialOrder = Get.arguments as OrderModel;
    } else if (Get.arguments is Map<String, dynamic>) {
      initialOrder = OrderModel.fromJson(Get.arguments as Map<String, dynamic>);
    } else if (Get.arguments is String) {
      initialOrder = OrderModel.placeholder(id: Get.arguments as String);
    } else if (Get.parameters['id'] != null) {
      initialOrder = OrderModel.placeholder(id: Get.parameters['id']!);
    } else {
      initialOrder = OrderModel.placeholder();
    }

    orderRx = initialOrder.obs;

    // Background sync with GET /account/orders/{id}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLatestOrderDetails();
    });
  }

  Future<void> _syncLatestOrderDetails() async {
    final cur = orderRx.value;
    final lookupId = cur.id.isNotEmpty ? cur.id : cur.orderId;
    if (lookupId.isEmpty || lookupId == '#ALF-PENDING') return;

    if (cur.items.isEmpty) {
      isLoading.value = true;
    }

    if (!Get.isRegistered<MyOrdersController>()) {
      Get.put(MyOrdersController());
    }

    try {
      final fresh =
          await Get.find<MyOrdersController>().fetchOrderDetails(lookupId);
      if (fresh != null && mounted) {
        orderRx.value = fresh;
      }
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
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
          'Order Details',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.copy, color: AppColor.textPrimary, size: 20.r),
            tooltip: 'Copy Order ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderRx.value.orderId));
              Get.snackbar(
                'Copied',
                'Order ID copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColor.textPrimary,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        final o = orderRx.value;

        if (isLoading.value && o.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColor.primary,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Status Header Card
              _buildOrderHeaderCard(o),
              SizedBox(height: 14.h),

              // 2. Premium Tracking Timeline Card
              _buildTimelineCard(o),
              SizedBox(height: 14.h),

              // 3. Delivery Address Card
              _buildDeliveryAddressCard(o),
              SizedBox(height: 14.h),

              // 4. Ordered Items Card
              _buildOrderedItemsCard(o),
              SizedBox(height: 14.h),

              // 5. Payment & Price Summary Card
              _buildPriceSummaryCard(o),
              SizedBox(height: 20.h),

              // 6. Support & Cancel Actions
              _buildActionButtons(context, o),
              SizedBox(height: 24.h),
            ],
          ),
        );
      }),
    );
  }

  /// 1. Order Header Card
  Widget _buildOrderHeaderCard(OrderModel o) {
    Color statusBg;
    Color statusColor;
    String statusLabel = o.status;

    if (o.status == 'Delivered') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF16A34A);
    } else if (o.status == 'Cancelled') {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = AppColor.error;
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Number',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      o.orderId,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Placed On',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                o.date,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Premium Tracking Timeline Card
  Widget _buildTimelineCard(OrderModel o) {
    final currentStage = o.trackingStage; // 0..4
    final isCancelled = o.status == 'Cancelled';

    final timelineSteps = [
      _TimelineItemData(
        title: 'Order Placed',
        subtitle: 'We have received and verified your order',
        icon: Iconsax.document_text,
        isCompleted: !isCancelled && currentStage >= 0,
        isActive: !isCancelled && currentStage == 0,
        stageIndex: 0,
      ),
      _TimelineItemData(
        title: 'Shipped',
        subtitle: 'Package dispatched from fulfillment warehouse',
        icon: Iconsax.truck_fast,
        isCompleted: !isCancelled && currentStage >= 1,
        isActive: !isCancelled && currentStage == 1,
        stageIndex: 1,
      ),
      _TimelineItemData(
        title: 'Handed Over to Nearest Delivery Zone',
        subtitle: 'Package arrived at your regional distribution hub',
        icon: Iconsax.location,
        isCompleted: !isCancelled && currentStage >= 2,
        isActive: !isCancelled && currentStage == 2,
        stageIndex: 2,
      ),
      _TimelineItemData(
        title: 'Out for Delivery',
        subtitle: 'Courier partner is en route to deliver at your door',
        icon: Iconsax.routing,
        isCompleted: !isCancelled && currentStage >= 3,
        isActive: !isCancelled && currentStage == 3,
        stageIndex: 3,
      ),
      _TimelineItemData(
        title: 'Delivered',
        subtitle: 'Package successfully handed over to customer',
        icon: Iconsax.box_tick,
        isCompleted: !isCancelled && currentStage >= 4,
        isActive: !isCancelled && currentStage == 4,
        stageIndex: 4,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Tracking',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  isCancelled
                      ? 'Order Cancelled'
                      : (currentStage >= 4 ? 'Completed' : 'On Track'),
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: isCancelled
                        ? AppColor.error
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Vertical Timeline Nodes
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineSteps.length,
            itemBuilder: (context, index) {
              final item = timelineSteps[index];
              final isLast = index == timelineSteps.length - 1;
              final nextCompleted =
                  !isLast && timelineSteps[index + 1].isCompleted;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Node + Connecting Line
                  SizedBox(
                    width: 32.r,
                    child: Column(
                      children: [
                        _buildNodeCircle(item, isCancelled: isCancelled),
                        if (!isLast)
                          Container(
                            width: 2.w,
                            height: 38.h,
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            color: nextCompleted
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE2E8F0),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Step Text Details
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 4.h, bottom: isLast ? 0 : 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: item.isActive || item.isCompleted
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCancelled
                                        ? AppColor.textSecondary
                                        : (item.isActive || item.isCompleted
                                            ? AppColor.textPrimary
                                            : AppColor.textSecondary),
                                  ),
                                ),
                              ),
                              if (item.isActive && !isCancelled)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: item.isCompleted || item.isActive
                                  ? AppColor.textSecondary
                                  : const Color(0xFF94A3B8),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCircle(_TimelineItemData item, {bool isCancelled = false}) {
    if (isCancelled && item.stageIndex == 0) {
      return Container(
        width: 32.r,
        height: 32.r,
        decoration: const BoxDecoration(
          color: Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          color: AppColor.error,
          size: 18.r,
        ),
      );
    }

    if (item.isCompleted) {
      return Container(
        width: 32.r,
        height: 32.r,
        decoration: const BoxDecoration(
          color: Color(0xFF16A34A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 18.r,
        ),
      );
    }

    if (item.isActive) {
      return Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD97706),
            width: 2.w,
          ),
        ),
        child: Center(
          child: Container(
            width: 12.r,
            height: 12.r,
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5.w,
        ),
      ),
      child: Center(
        child: Container(
          width: 8.r,
          height: 8.r,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// 3. Delivery Address Card
  Widget _buildDeliveryAddressCard(OrderModel o) {
    final addr = o.address?.trim().isNotEmpty == true
        ? o.address!
        : 'Customer Delivery Address';
    final name = o.recipientName?.trim().isNotEmpty == true
        ? o.recipientName!
        : 'Customer';
    final phone = o.phone?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Iconsax.location,
                    size: 18.r,
                    color: AppColor.primaryDark,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Shipping Address',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          if (phone.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              phone,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                color: AppColor.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 6.h),
          Text(
            addr,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColor.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Ordered Items Card
  Widget _buildOrderedItemsCard(OrderModel o) {
    final items = o.items;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items in this Order (${items.isNotEmpty ? items.length : o.itemCount})',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          if (o.sellerName != null && o.sellerName!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Iconsax.shop, size: 15.r, color: AppColor.primaryDark),
                SizedBox(width: 6.w),
                Text(
                  'Seller: ${o.sellerName}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryDark,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          if (items.isEmpty)
            Text(
              'Item details included in shipment package',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54.r,
                        height: 54.r,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item.image.isNotEmpty
                            ? Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(
                                  Iconsax.image,
                                  size: 24.r,
                                  color: AppColor.textSecondary,
                                ),
                              )
                            : Icon(
                                Iconsax.image,
                                size: 24.r,
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
                              style: GoogleFonts.inter(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.variantName.isNotEmpty &&
                                item.variantName != item.name) ...[
                              SizedBox(height: 2.h),
                              Text(
                                item.variantName,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ],
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  '৳${item.price.toStringAsFixed(2)} each',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '৳${(item.lineTotal > 0 ? item.lineTotal : item.price * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Divider(
                      color: const Color(0xFFF1F5F9),
                      height: 20.h,
                    ),
                ],
              );
            }),
          if (o.openBoxDelivery) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.box_tick,
                    size: 14.r,
                    color: const Color(0xFF16A34A),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Open Box Delivery Available',
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Payment & Price Summary Card
  Widget _buildPriceSummaryCard(OrderModel o) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
          Text(
            'Payment & Total',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  o.formattedPaymentMethod,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (o.paymentStatus != null && o.paymentStatus!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: o.formattedPaymentStatus
                            .toLowerCase()
                            .contains('partially')
                        ? const Color(0xFFFFFBEB)
                        : (o.formattedPaymentStatus
                                .toLowerCase()
                                .contains('paid')
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: o.formattedPaymentStatus
                              .toLowerCase()
                              .contains('partially')
                          ? const Color(0xFFFDE68A)
                          : (o.formattedPaymentStatus
                                  .toLowerCase()
                                  .contains('paid')
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    o.formattedPaymentStatus,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: o.formattedPaymentStatus
                              .toLowerCase()
                              .contains('partially')
                          ? const Color(0xFFB45309)
                          : (o.formattedPaymentStatus
                                  .toLowerCase()
                                  .contains('paid')
                              ? const Color(0xFF15803D)
                              : AppColor.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items Subtotal',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                o.formattedSubtotal,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                o.formattedShipping,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: o.shippingFee == 0
                      ? const Color(0xFF16A34A)
                      : AppColor.textPrimary,
                ),
              ),
            ],
          ),
          if (o.discount > 0) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Text(
                  '-৳${o.discount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
          if (o.walletPaid > 0) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid from Wallet',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Text(
                  '-৳${o.walletPaid.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o.walletPaid > 0 && o.remainingPayable > 0
                    ? 'Total Amount'
                    : 'Total Payable',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                o.formattedTotal,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primaryDark,
                ),
              ),
            ],
          ),
          if (o.walletPaid > 0 && o.remainingPayable > 0) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due on Delivery (COD)',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB45309),
                  ),
                ),
                Text(
                  '৳${o.remainingPayable.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 6. Action Buttons: Need Help? and Cancel Order
  Widget _buildActionButtons(BuildContext context, OrderModel o) {
    final canCancel = o.status != 'Cancelled' && o.status != 'Delivered';

    return Column(
      children: [
        if (canCancel)
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: isCancelling.value
                  ? null
                  : () => _showCancelOrderModal(context, o),
              icon: Icon(
                Iconsax.close_circle,
                size: 19.r,
                color: AppColor.error,
              ),
              label: Text(
                'Cancel Order',
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        if (canCancel) SizedBox(height: 12.h),

        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.snackbar(
                'Customer Support',
                'Connecting to Alif Support for Order ${o.orderId}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColor.textPrimary,
                colorText: Colors.white,
              );
            },
            icon: Icon(Iconsax.message_question, size: 18.r),
            label: Text(
              'Need Help with this Order?',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.textPrimary,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Modal for selecting cancellation reason and confirming
  void _showCancelOrderModal(BuildContext context, OrderModel o) {
    final reasons = [
      'Placed order by mistake',
      'I found a better price elsewhere',
      'Delivery time is too long',
      'Need to change shipping address or items',
      'Other reason',
    ];

    final selectedReason = reasons.first.obs;
    final otherReasonController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Iconsax.danger,
                            color: AppColor.error,
                            size: 20.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Cancel Order',
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColor.textSecondary,
                      size: 22.r,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'Are you sure you want to cancel order ${o.orderId}? Please select a reason:',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),

              // Reason Radio Options
              Obx(
                () => Column(
                  children: reasons.map((reason) {
                    final isSelected = selectedReason.value == reason;
                    return InkWell(
                      onTap: () => selectedReason.value = reason,
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF1F2)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18.r,
                              color: isSelected
                                  ? AppColor.error
                                  : AppColor.textHint,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColor.textPrimary
                                      : AppColor.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 18.h),

              // Confirm and Dismiss Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Keep Order',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: isCancelling.value
                            ? null
                            : () async {
                                isCancelling.value = true;
                                final reasonText =
                                    selectedReason.value == 'Other reason' &&
                                            otherReasonController.text.trim().isNotEmpty
                                        ? otherReasonController.text.trim()
                                        : selectedReason.value;

                                final lookupId = o.id.isNotEmpty ? o.id : o.orderId;

                                if (!Get.isRegistered<MyOrdersController>()) {
                                  Get.put(MyOrdersController());
                                }

                                final success = await Get.find<MyOrdersController>()
                                    .cancelOrder(lookupId, reason: reasonText);

                                isCancelling.value = false;

                                if (success) {
                                  Get.back(); // Close bottomsheet
                                  // Update local status to Cancelled immediately
                                  orderRx.value = OrderModel(
                                    id: o.id,
                                    orderId: o.orderId,
                                    date: o.date,
                                    status: 'Cancelled',
                                    totalAmount: o.totalAmount,
                                    subtotal: o.subtotal,
                                    shippingFee: o.shippingFee,
                                    discount: o.discount,
                                    itemCount: o.itemCount,
                                    items: o.items,
                                    paymentMethod: o.paymentMethod,
                                    paymentStatus: o.paymentStatus,
                                    address: o.address,
                                    recipientName: o.recipientName,
                                    phone: o.phone,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.error,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: isCancelling.value
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Confirm Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _TimelineItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final int stageIndex;

  const _TimelineItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
    required this.stageIndex,
  });
}
