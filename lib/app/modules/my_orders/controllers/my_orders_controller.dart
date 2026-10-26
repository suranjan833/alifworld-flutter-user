
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/widgets/no_internet_dialog.dart';
import '../../../routes/app_pages.dart';
import '../models/order_model.dart';

class MyOrdersController extends GetxController with SkeletonLoadingMixin {
  final selectedStatusIndex = 0.obs;
  final statuses = const ['All', 'In Progress', 'Delivered', 'Cancelled'];

  final orders = <OrderModel>[].obs;
  final nextCursor = RxnString();
  final isLoadingMore = false.obs;
  final hasInternetError = false.obs;

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
  }

  @override
  void onInit() {
    super.onInit();
    if (!_hasAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.LOGIN);
      });
      return;
    }
    fetchOrders();
  }

  /// 1. GET /account/orders?limit=20 - Fetch user orders list from API
  Future<void> fetchOrders({bool isRefresh = false}) async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      if (orders.isEmpty) {
        hasInternetError.value = true;
      } else {
        showNoInternetDialog(
          onRetry: () => fetchOrders(isRefresh: isRefresh),
        );
      }
      isLoading.value = false;
      return;
    }

    hasInternetError.value = false;
    if (!isRefresh && orders.isEmpty) {
      isLoading.value = true;
    }

    try {
      final response = await dioGet('account/orders?limit=20');

      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        List? orderList;
        if (rawData is Map<String, dynamic>) {
          if (rawData['items'] is List) {
            orderList = rawData['items'] as List;
          } else if (rawData['orders'] is List) {
            orderList = rawData['orders'] as List;
          }
          nextCursor.value = rawData['nextCursor']?.toString();
        } else if (rawData is List) {
          orderList = rawData;
        }

        if (orderList != null) {
          final parsed = orderList
              .whereType<Map<String, dynamic>>()
              .map((e) => OrderModel.fromJson(e))
              .toList();
          orders.assignAll(parsed);
        }
      }
    } catch (e, stack) {
      developer.log(
        'Failed to fetch user orders: $e',
        name: 'MyOrdersController',
        error: e,
        stackTrace: stack,
      );
      final isOnlineCheck = await hasInternetConnection();
      if (!isOnlineCheck && orders.isEmpty) {
        hasInternetError.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh handler
  Future<void> refreshOrders() async {
    await fetchOrders(isRefresh: true);
  }

  /// Pagination: Fetch next page of orders
  Future<void> loadMoreOrders() async {
    final cursor = nextCursor.value;
    if (cursor == null || cursor.isEmpty || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      final response = await dioGet('account/orders?limit=20&cursor=$cursor');

      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        List? orderList;
        if (rawData is Map<String, dynamic>) {
          if (rawData['items'] is List) {
            orderList = rawData['items'] as List;
          } else if (rawData['orders'] is List) {
            orderList = rawData['orders'] as List;
          }
          nextCursor.value = rawData['nextCursor']?.toString();
        }

        if (orderList != null && orderList.isNotEmpty) {
          final parsed = orderList
              .whereType<Map<String, dynamic>>()
              .map((e) => OrderModel.fromJson(e))
              .toList();
          orders.addAll(parsed);
        }
      }
    } catch (e) {
      developer.log('Load more orders failed: $e', name: 'MyOrdersController');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 2. GET /account/orders/{id} - Fetch single order details
  Future<OrderModel?> fetchOrderDetails(String orderId) async {
    try {
      final response = await dioGet('account/orders/$orderId');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic> && rawData.containsKey('order')) {
          rawData = rawData['order'];
        }
        if (rawData is Map<String, dynamic>) {
          final updated = OrderModel.fromJson(rawData);
          // Sync into local list if exists
          final idx = orders.indexWhere(
            (o) => o.id == updated.id || o.orderId == updated.orderId,
          );
          if (idx != -1) {
            orders[idx] = updated;
            orders.refresh();
          }
          return updated;
        }
      }
    } catch (e) {
      developer.log('fetchOrderDetails error: $e', name: 'MyOrdersController');
    }
    return null;
  }

  /// 3. POST /account/orders/{id}/cancel - Cancel an order
  Future<bool> cancelOrder(
    String orderId, {
    String reason = 'Customer requested',
  }) async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      showNoInternetDialog(
        onRetry: () => cancelOrder(orderId, reason: reason),
      );
      return false;
    }

    try {
      final response = await dioPost(
        endUrl: 'account/orders/$orderId/cancel',
        data: {'reason': reason},
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local status immediately
        final idx = orders.indexWhere(
          (o) => o.id == orderId || o.orderId == orderId,
        );
        if (idx != -1) {
          final existing = orders[idx];
          orders[idx] = existing.copyWith(
            status: 'Cancelled',
            backendStatus: 'cancelled',
          );
          orders.refresh();
        }

        Get.snackbar(
          'Order Cancelled',
          'Order $orderId has been cancelled successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.textPrimary,
          colorText: AppColor.white,
          duration: const Duration(seconds: 3),
        );
        fetchOrders(isRefresh: true);
        return true;
      } else {
        String errMsg = 'Failed to cancel order.';
        if (response.data is Map) {
          final d = response.data as Map;
          if (d['error'] is Map && d['error']['message'] != null) {
            errMsg = d['error']['message'].toString();
          } else if (d['message'] != null) {
            errMsg = d['message'].toString();
          }
        }
        Get.snackbar(
          'Unable to Cancel',
          errMsg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Cancellation Error',
        'Could not cancel order. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return false;
    }
  }

  List<OrderModel> get filteredOrders {
    if (selectedStatusIndex.value == 0) {
      return orders;
    }
    final targetStatus = statuses[selectedStatusIndex.value];
    return orders.where((o) => o.status == targetStatus).toList();
  }

  void changeStatusTab(int index) {
    selectedStatusIndex.value = index;
  }
}
