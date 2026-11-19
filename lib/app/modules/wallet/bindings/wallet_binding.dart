import 'package:get/get.dart';

import '../controllers/manual_payment_controller.dart';
import '../controllers/wallet_controller.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(() => WalletController());
    Get.lazyPut<ManualPaymentController>(() => ManualPaymentController());
  }
}
