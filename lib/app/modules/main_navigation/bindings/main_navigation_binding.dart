import 'package:get/get.dart';

import '../../account/controllers/account_controller.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../categories/controllers/categories_controller.dart';
import '../../discover/controllers/discover_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/main_navigation_controller.dart';

class MainNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavigationController>(
      () => MainNavigationController(),
      fenix: true,
    );
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<CategoriesController>(
      () => CategoriesController(),
      fenix: true,
    );
    Get.lazyPut<DiscoverController>(() => DiscoverController(), fenix: true);
    Get.put<BagController>(BagController(), permanent: true);
    Get.lazyPut<AccountController>(() => AccountController(), fenix: true);
  }
}
