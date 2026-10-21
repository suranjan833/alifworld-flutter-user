import 'package:get/get.dart';

import '../controllers/bag_controller.dart';

class BagBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BagController>(() => BagController());
  }
}
