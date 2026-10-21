import 'package:get/get.dart';

import '../controllers/refund_policy_controller.dart';

class RefundPolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RefundPolicyController>(() => RefundPolicyController());
  }
}
