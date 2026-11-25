import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/rewards_info_model.dart';
import '../models/leaderboard_model.dart';
import '../views/widgets/club_details_sheet.dart';
import '../views/widgets/star_bands_sheet.dart';

class LeaderboardController extends GetxController {
  final selectedKind = 'customer'.obs; // 'customer', 'seller'
  final selectedPeriod = 'daily'.obs; // 'daily', 'weekly', 'monthly', 'yearly'
  final selectedBandFilter = 'all'.obs; // 'all', 'mega_star', 'super_star', 'star'

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

  void changeKind(String kind) {
    if (selectedKind.value == kind) return;
    selectedKind.value = kind;
    fetchLeaderboard();
  }

  void changePeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    fetchLeaderboard();
  }

  void changeBandFilter(String bandKey) {
    selectedBandFilter.value = bandKey;
  }

  /// Returns active bands from leaderboard response or default bands
  List<StarBandModel> get availableBands {
    final bands = leaderboard.value?.bands ?? [];
    if (bands.isNotEmpty) return bands;
    return [
      StarBandModel(key: 'mega_star', from: 1, to: 10, pct: 1),
      StarBandModel(key: 'super_star', from: 11, to: 50, pct: 1),
      StarBandModel(key: 'star', from: 51, to: 100, pct: 1),
    ];
  }

  /// Maps entry rank to matching StarBand
  StarBandModel? getBandForRank(int rank) {
    for (final band in availableBands) {
      if (rank >= band.from && rank <= band.to) return band;
    }
    return null;
  }

  /// Top 3 entries for podium
  List<LeaderboardEntryModel> get topThreeEntries {
    final entries = leaderboard.value?.entries ?? [];
    return entries.where((e) => e.rank <= 3).toList();
  }

  LeaderboardEntryModel? get entryRank1 {
    final entries = leaderboard.value?.entries ?? [];
    return entries.firstWhereOrNull((e) => e.rank == 1);
  }

  LeaderboardEntryModel? get entryRank2 {
    final entries = leaderboard.value?.entries ?? [];
    return entries.firstWhereOrNull((e) => e.rank == 2);
  }

  LeaderboardEntryModel? get entryRank3 {
    final entries = leaderboard.value?.entries ?? [];
    return entries.firstWhereOrNull((e) => e.rank == 3);
  }

  /// Filtered rankings list (ranks 4–100 or filtered by band)
  List<LeaderboardEntryModel> get filteredListEntries {
    final entries = leaderboard.value?.entries ?? [];
    if (selectedBandFilter.value == 'all') {
      return entries.where((e) => e.rank > 3).toList();
    }
    final activeBand = availableBands.firstWhereOrNull((b) => b.key == selectedBandFilter.value);
    if (activeBand == null) {
      return entries.where((e) => e.rank > 3).toList();
    }
    return entries.where((e) => e.rank >= activeBand.from && e.rank <= activeBand.to).toList();
  }

  /// GET /api/v1/leaderboards?kind=customer|seller&period=daily|weekly|monthly|yearly
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;
      final url =
          'leaderboards?kind=${selectedKind.value}&period=${selectedPeriod.value}';
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
    StarBandsSheet.show(context);
  }

  void showClubDetailsSheet(BuildContext context, {String? period}) {
    ClubDetailsSheet.show(context, period: period ?? selectedPeriod.value);
  }
}
