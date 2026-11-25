import 'package:get/get.dart';

import '../../../data/services/rewards_service.dart';

class ClubDetailsController extends GetxController {
  final selectedPeriod = 'daily'.obs;

  void setPeriod(String? period) {
    if (period != null && period.trim().isNotEmpty) {
      selectedPeriod.value = period.toLowerCase().trim();
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<RewardsService>()) {
      RewardsService.to.fetchRewardsInfo();
    }
  }
}
