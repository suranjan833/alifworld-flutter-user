import 'package:get/get.dart';

import '../controllers/top_brands_controller.dart';

class TopBrandsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopBrandsController>(() => TopBrandsController());
  }
}
