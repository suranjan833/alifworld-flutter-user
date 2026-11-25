import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/mini_banners_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<MiniBannersController>(
      () => MiniBannersController(),
    );
  }
}
