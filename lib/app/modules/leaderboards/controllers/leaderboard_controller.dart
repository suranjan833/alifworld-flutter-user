import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/rewards_info_model.dart';
import '../../../data/services/rewards_service.dart';
import '../models/leaderboard_model.dart';
import '../views/widgets/star_bands_sheet.dart';

class LeaderboardController extends GetxController {
  final selectedPeriod = 'daily'.obs; // 'daily', 'weekly', 'monthly', 'yearly'

  final isLoading = false.obs;
  final isMyProgressLoading = false.obs;

  final leaderboard = Rxn<LeaderboardResponseModel>();
  final myProgress = Rxn<MyProgressResponseModel>();

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchLeaderboard(),
      if (hasAuth) fetchMyProgress(),
    ]);
  }

  void changePeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    fetchLeaderboard();
  }

  /// GET /api/v1/leaderboards?kind=customer&period=daily|weekly|monthly|yearly
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;
      final url = 'leaderboards?kind=customer&period=${selectedPeriod.value}';
      final response = await dioGet(url);

      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          leaderboard.value = LeaderboardResponseModel.fromJson(raw);
        }
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// GET /api/v1/leaderboards/my-progress (customer session)
  Future<void> fetchMyProgress() async {
    if (!hasAuth) {
      myProgress.value = null;
      return;
    }

    try {
      isMyProgressLoading.value = true;
      final response = await dioGet('leaderboards/my-progress');

      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          myProgress.value = MyProgressResponseModel.fromJson(raw);
        }
      } else if (response.statusCode == 401) {
        // Logged out / expired session - silently hide without erroring
        myProgress.value = null;
      }
    } catch (e) {
      debugPrint('Error fetching my-progress: $e');
    } finally {
      isMyProgressLoading.value = false;
    }
  }

  MyProgressPeriodModel? get currentPeriodProgress {
    if (myProgress.value == null) return null;
    return myProgress.value!.getPeriod(selectedPeriod.value);
  }

  bool isMyEntry(LeaderboardEntryModel entry) {
    if (!hasAuth) return false;
    final progress = currentPeriodProgress;
    if (progress?.star?.rank == null) return false;
    return progress!.star!.rank == entry.rank;
  }

  LeaderboardPoolBandModel? getPoolBandForRank(int rank) {
    final pool = leaderboard.value?.pool;
    if (pool == null) return null;
    try {
      return pool.bands.firstWhere((b) => rank >= b.from && rank <= b.to);
    } catch (_) {
      return null;
    }
  }

  void showConditionsSheet(BuildContext context) {
    final bands = (leaderboard.value?.bands.isNotEmpty ?? false)
        ? leaderboard.value!.bands
        : (Get.isRegistered<RewardsService>()
            ? RewardsService.to.customerStarBands
            : <StarBandModel>[]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StarBandsSheet(bands: bands),
    );
  }
}
