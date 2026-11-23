import 'package:get/get.dart';

import '../controllers/referral_level_history_controller.dart';

class ReferralLevelHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralLevelHistoryController>(
      () => ReferralLevelHistoryController(),
    );
  }
}
