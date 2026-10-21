import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class OrderSuccessController extends GetxController {
  final orderId = '#ALF-98742'.obs;
  final paymentId = 'pay_Rzp984210'.obs;
  final paymentMethod = 'Razorpay Online'.obs;
  final totalAmount = 0.0.obs;
  final itemCount = 1.obs;
  final deliveryAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      orderId.value = args['orderId'] as String? ?? '#ALF-98742';
      paymentId.value = args['paymentId'] as String? ?? 'pay_Rzp984210';
      paymentMethod.value =
          args['paymentMethod'] as String? ?? 'Razorpay Online';
      totalAmount.value = (args['totalAmount'] as num?)?.toDouble() ?? 0.0;
      itemCount.value = (args['itemCount'] as num?)?.toInt() ?? 1;
      deliveryAddress.value = args['address'] as String? ?? '';
    }
  }

  void trackOrder() {
    Get.offAllNamed(Routes.MAIN_NAVIGATION);
    Get.toNamed(Routes.MY_ORDERS);
  }

  void continueShopping() {
    Get.offAllNamed(Routes.MAIN_NAVIGATION);
  }
}
