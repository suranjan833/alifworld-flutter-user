import 'package:get/get.dart';
import '../../account/controllers/account_controller.dart';
import '../../bag/controllers/bag_controller.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 3) {
      if (!Get.isRegistered<BagController>()) {
        Get.put(BagController());
      }
      Get.find<BagController>().fetchCart(showLoading: false, force: true);
    }
    if (index == 4 && Get.isRegistered<AccountController>()) {
      // Silent refresh: wallet total + club achievements, no loading state.
      Get.find<AccountController>().refreshWalletAndProgress();
    }
  }
}
