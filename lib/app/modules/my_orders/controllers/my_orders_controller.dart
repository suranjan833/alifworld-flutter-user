
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../models/order_model.dart';

class MyOrdersController extends GetxController with SkeletonLoadingMixin {
  final selectedStatusIndex = 0.obs;

  final statuses = const ['All', 'In Progress', 'Delivered', 'Cancelled'];

  final orders = <OrderModel>[
    OrderModel(
      id: '1',
      orderId: '#ALF-98742',
      date: '24 Sep 2026',
      status: 'In Progress',
      totalAmount: 1299.0,
      itemCount: 2,
      items: [
        OrderItemModel(
          id: 'it1',
          name: 'Smart Color Bulb 2 Pack',
          image:
              'https://images.unsplash.com/photo-1550525811-e5869dd03032?q=80&w=400&auto=format&fit=crop',
          quantity: 1,
          price: 499.0,
        ),
        OrderItemModel(
          id: 'it2',
          name: 'Gaming Mouse 16000 DPI',
          image:
              'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?q=80&w=400&auto=format&fit=crop',
          quantity: 1,
          price: 800.0,
        ),
      ],
    ),
    OrderModel(
      id: '2',
      orderId: '#ALF-85412',
      date: '18 Sep 2026',
      status: 'Delivered',
      totalAmount: 2499.0,
      itemCount: 1,
      items: [
        OrderItemModel(
          id: 'it3',
          name: 'Gaming Controller Wireless',
          image:
              'https://images.unsplash.com/photo-1600080972464-8e5f35f63d08?q=80&w=400&auto=format&fit=crop',
          quantity: 1,
          price: 2499.0,
        ),
      ],
    ),
    OrderModel(
      id: '3',
      orderId: '#ALF-74120',
      date: '10 Aug 2026',
      status: 'Delivered',
      totalAmount: 5999.0,
      itemCount: 1,
      items: [
        OrderItemModel(
          id: 'it4',
          name: 'Air Fryer Max XL 5.5L',
          image:
              'https://images.unsplash.com/photo-1585515320310-259814833e62?q=80&w=400&auto=format&fit=crop',
          quantity: 1,
          price: 5999.0,
        ),
      ],
    ),
    OrderModel(
      id: '4',
      orderId: '#ALF-63214',
      date: '02 Jul 2026',
      status: 'Cancelled',
      totalAmount: 899.0,
      itemCount: 1,
      items: [
        OrderItemModel(
          id: 'it5',
          name: 'Flip 6 Portable Speaker',
          image:
              'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?q=80&w=400&auto=format&fit=crop',
          quantity: 1,
          price: 899.0,
        ),
      ],
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  /// 1. GET /account/orders - Fetch user orders list from API
  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await dioGet('account/orders');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? orderList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('orders')) {
          orderList = rawData['orders'] as List?;
        } else if (rawData is List) {
          orderList = rawData;
        }

        if (orderList != null && orderList.isNotEmpty) {
          final parsed = orderList
              .whereType<Map<String, dynamic>>()
              .map((e) => OrderModel.fromJson(e))
              .toList();
          if (parsed.isNotEmpty) {
            orders.assignAll(parsed);
          }
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. POST /account/orders/{id}/cancel - Cancel an order
  Future<void> cancelOrder(String orderId, {String reason = 'Customer requested'}) async {
    try {
      final response = await dioPost(
        endUrl: 'account/orders/$orderId/cancel',
        data: {'reason': reason},
        isJson: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Order Cancelled',
          'Order $orderId has been cancelled',
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchOrders();
      }
    } catch (_) {}
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
