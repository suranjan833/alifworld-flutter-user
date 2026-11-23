import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';
import 'my_orders_controller.dart';

class OrderDetailsController extends GetxController {
  final orderRx = OrderModel.placeholder().obs;
  final isLoading = false.obs;
  final isCancelling = false.obs;

  @override
  void onInit() {
    super.onInit();
    initOrder();
  }

  void initOrder({OrderModel? explicitOrder}) {
    OrderModel initialOrder;
    if (explicitOrder != null) {
      initialOrder = explicitOrder;
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

    orderRx.value = initialOrder;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncLatestOrderDetails();
    });
  }

  Future<void> syncLatestOrderDetails() async {
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
      if (fresh != null) {
        orderRx.value = fresh;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String lookupId, {String? reason}) async {
    if (!Get.isRegistered<MyOrdersController>()) {
      Get.put(MyOrdersController());
    }
    isCancelling.value = true;
    try {
      final success = await Get.find<MyOrdersController>()
          .cancelOrder(lookupId, reason: reason ?? '');
      if (success) {
        orderRx.value = orderRx.value.copyWith(
          status: 'Cancelled',
          backendStatus: 'cancelled',
        );
      }
      return success;
    } finally {
      isCancelling.value = false;
    }
  }
}
