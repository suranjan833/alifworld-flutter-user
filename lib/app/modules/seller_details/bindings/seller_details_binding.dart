import 'package:get/get.dart';

import '../controllers/seller_details_controller.dart';

class SellerDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerDetailsController>(() => SellerDetailsController());
  }
}
