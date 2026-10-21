import 'package:get/get.dart';

import '../controllers/manage_addresses_controller.dart';

class ManageAddressesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageAddressesController>(() => ManageAddressesController());
  }
}
