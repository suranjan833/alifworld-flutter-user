import 'package:get/get.dart';
import '../../bag/controllers/bag_controller.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 3) {
      if (Get.isRegistered<BagController>()) {
        Get.find<BagController>().fetchCart(showLoading: false);
      }
    }
  }
}
