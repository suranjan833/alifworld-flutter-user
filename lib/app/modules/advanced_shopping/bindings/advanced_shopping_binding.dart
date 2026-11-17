import 'package:get/get.dart';
import '../controllers/advanced_shopping_controller.dart';

class AdvancedShoppingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdvancedShoppingController>(
      () => AdvancedShoppingController(),
    );
  }
}
