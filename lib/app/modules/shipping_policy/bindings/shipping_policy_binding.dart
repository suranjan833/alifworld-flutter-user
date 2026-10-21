import 'package:get/get.dart';

import '../controllers/shipping_policy_controller.dart';

class ShippingPolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShippingPolicyController>(() => ShippingPolicyController());
  }
}
