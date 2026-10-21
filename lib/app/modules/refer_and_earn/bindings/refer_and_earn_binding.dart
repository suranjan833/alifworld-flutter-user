import 'package:get/get.dart';

import '../controllers/refer_and_earn_controller.dart';

class ReferAndEarnBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferAndEarnController>(() => ReferAndEarnController());
  }
}
