import 'package:get/get.dart';

import '../controllers/my_orders_controller.dart';
import '../controllers/order_details_controller.dart';

class MyOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyOrdersController>(() => MyOrdersController());
    Get.lazyPut<OrderDetailsController>(() => OrderDetailsController());
  }
}
