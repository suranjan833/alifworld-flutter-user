import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class OrderSuccessController extends GetxController {
  final orderId = ''.obs;
  final batchNumber = ''.obs;
  final paymentStatus = ''.obs;
  final paymentId = ''.obs;
  final paymentMethod = 'Cash on Delivery'.obs;
  final totalAmount = 0.0.obs;
  final itemCount = 1.obs;
  final deliveryAddress = ''.obs;

  bool get isCod {
    final pm = paymentMethod.value.toLowerCase();
    return pm.contains('cod') || pm.contains('cash');
  }

  bool get isWallet {
    final pm = paymentMethod.value.toLowerCase();
    return pm.contains('wallet');
  }

  bool get showPaymentId => !isCod && paymentId.value.trim().isNotEmpty;

  String get formattedPaymentStatus {
    final status = paymentStatus.value.trim().toLowerCase();
    if (status.isEmpty) {
      if (isWallet) return 'Partially Paid';
      return 'Pending';
    }
    switch (status) {
      case 'partially_paid':
        return 'Partially Paid';
      case 'paid':
        return 'Paid';
      case 'cod_pending':
        return 'COD Pending';
      case 'unpaid':
        return 'Unpaid';
      case 'failed':
        return 'Failed';
      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      orderId.value = args['orderId'] as String? ?? '';
      batchNumber.value = args['batchNumber'] as String? ?? '';
      paymentStatus.value = args['paymentStatus'] as String? ?? '';
      paymentId.value = args['paymentId'] as String? ?? '';
      paymentMethod.value =
          args['paymentMethod'] as String? ?? 'Cash on Delivery';
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
