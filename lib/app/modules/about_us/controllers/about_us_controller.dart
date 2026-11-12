import 'package:get/get.dart';

import '../../../data/services/app_update_service.dart';

class AboutUsController extends GetxController {
  final appVersion = '1.3.8+138'.obs;
  final companyName = 'Alif Commerce Inc.'.obs;

  void checkForUpdate() {
    if (Get.isRegistered<AppUpdateService>()) {
      AppUpdateService.to.checkForUpdate(showToastIfNoUpdate: true);
    }
  }

  void previewUpdateDialog() {
    if (Get.isRegistered<AppUpdateService>()) {
      AppUpdateService.to.showForceUpdateDialog(isPreview: true);
    }
  }

  final coreValues = const [
    {
      'title': 'Customer First',
      'description': 'We prioritize customer satisfaction with 24/7 support and hassle-free services.',
    },
    {
      'title': 'Quality Assurance',
      'description': 'Every product on Alif is verified for authenticity and top-notch build quality.',
    },
    {
      'title': 'Fast Delivery',
      'description': 'Swift, reliable shipping networks bringing your orders right to your doorstep.',
    },
  ];
}
