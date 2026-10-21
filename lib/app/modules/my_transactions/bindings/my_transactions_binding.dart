import 'package:get/get.dart';

import '../controllers/my_transactions_controller.dart';

class MyTransactionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyTransactionsController>(() => MyTransactionsController());
  }
}
