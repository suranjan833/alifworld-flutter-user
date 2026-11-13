import 'package:get/get.dart';

import '../controllers/points_help_controller.dart';

class PointsHelpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PointsHelpController>(() => PointsHelpController());
  }
}
