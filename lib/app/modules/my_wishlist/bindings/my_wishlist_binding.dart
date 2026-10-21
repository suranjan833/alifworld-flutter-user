import 'package:get/get.dart';

import '../controllers/my_wishlist_controller.dart';

class MyWishlistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyWishlistController>(() => MyWishlistController());
  }
}
