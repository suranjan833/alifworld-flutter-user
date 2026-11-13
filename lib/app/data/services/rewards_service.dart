import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/functions/dio_function/my_dio.dart';
import '../models/rewards_info_model.dart';

class RewardsService extends GetxService {
  static RewardsService get to => Get.find<RewardsService>();

  final info = Rx<RewardsInfoModel>(RewardsInfoModel());
  final isLoading = false.obs;

  DateTime? _lastFetchedAt;
  static const Duration _cacheDuration = Duration(seconds: 60);

  @override
  void onInit() {
    super.onInit();
    fetchRewardsInfo();
  }

  /// Fetches rewards config from GET /api/v1/rewards/info
  /// Respects 60s cache unless [forceRefresh] is true.
  Future<RewardsInfoModel> fetchRewardsInfo({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastFetchedAt != null &&
        now.difference(_lastFetchedAt!) < _cacheDuration) {
      return info.value;
    }

    try {
      isLoading.value = true;
      final response = await dioGet('rewards/info');
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          final parsed = RewardsInfoModel.fromJson(raw);
          info.value = parsed;
          _lastFetchedAt = DateTime.now();
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('Error fetching rewards info: $e');
    } finally {
      isLoading.value = false;
    }

    return info.value;
  }

  int get pointValueMinor => info.value.pointValueMinor;
  double pointsToMoney(int points) => info.value.pointsToMoney(points);
  String formatPointsMoney(int points) => info.value.formatPointsMoney(points);
  CustomerSplitModel get customerSplit => info.value.customerSplit;
  List<StarBandModel> get customerStarBands => info.value.customerStarBands;
  GeoPctModel get geoPct => info.value.geoPct;
  Map<String, ClubPeriodTiersModel> get customerClub => info.value.customerClub;
}
