import 'package:get/get.dart';

import '../../../data/models/rewards_info_model.dart';
import '../../../data/services/rewards_service.dart';

class PointsHelpController extends GetxController {
  RewardsService get rewardsService => RewardsService.to;
  RewardsInfoModel get info => rewardsService.info.value;

  String get pointValueFormatted =>
      rewardsService.formatPointsMoney(1); // e.g. ৳1

  num get cashbackPct => info.cashbackPct;
  CustomerSplitModel get customerSplit => info.customerSplit;
  List<num> get referralPct => info.referralPct;
  GeoPctModel get geoPct => info.geoPct;
  List<StarBandModel> get starBands => info.customerStarBands;
  Map<String, ClubPeriodTiersModel> get clubTiers => info.customerClub;

  Future<void> refreshInfo() async {
    await rewardsService.fetchRewardsInfo(forceRefresh: true);
  }
}
