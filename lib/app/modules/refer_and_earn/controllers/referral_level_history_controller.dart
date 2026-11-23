import 'dart:developer';

import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/referral_model.dart';

class ReferralLevelHistoryController extends GetxController {
  static final Map<int, List<ReferralHistoryItem>> _memItemsCache = {};
  static final Map<int, String?> _memCursorCache = {};

  final level = 1.obs;
  final userCount = 0.obs;
  final ratePct = (0).obs;
  final items = <ReferralHistoryItem>[].obs;
  final isInitialLoading = false.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final nextCursor = RxnString();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      level.value = (args['level'] as num?)?.toInt() ?? 1;
      userCount.value = (args['userCount'] as num?)?.toInt() ?? 0;
      final rawRate = args['ratePct'];
      if (rawRate is num) {
        ratePct.value = rawRate.toInt();
      }
    }

    _loadFromCache();

    final hasCache = items.isNotEmpty;
    if (!hasCache) {
      isInitialLoading.value = true;
    }
    fetchLevelHistory(isBackground: hasCache);
  }

  void _loadFromCache() {
    final lvl = level.value;
    if (_memItemsCache.containsKey(lvl) && _memItemsCache[lvl]!.isNotEmpty) {
      items.assignAll(_memItemsCache[lvl]!);
      nextCursor.value = _memCursorCache[lvl];
      return;
    }

    try {
      final cached = getBox.read('ref_level_cache_$lvl');
      if (cached is Map) {
        final resp = ReferralHistoryResponse.fromJson(
          Map<String, dynamic>.from(cached),
        );
        if (resp.items.isNotEmpty) {
          items.assignAll(resp.items);
          nextCursor.value = resp.nextCursor;
          _memItemsCache[lvl] = resp.items;
          _memCursorCache[lvl] = resp.nextCursor;
        }
      }
    } catch (e) {
      log('Cache read error for level $lvl: $e');
    }
  }

  Future<void> fetchLevelHistory({
    bool isRefresh = false,
    bool isBackground = false,
  }) async {
    if (isRefresh) {
      nextCursor.value = null;
    }
    if (!isBackground) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final endpoint = 'referrals/history?level=${level.value}&limit=20';
      final response = await dioGet(endpoint);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;

        final historyResp = ReferralHistoryResponse.fromJson(data);
        items.assignAll(historyResp.items);
        nextCursor.value = historyResp.nextCursor;

        // Save to memory cache & disk cache
        final lvl = level.value;
        _memItemsCache[lvl] = List<ReferralHistoryItem>.from(historyResp.items);
        _memCursorCache[lvl] = historyResp.nextCursor;

        final cacheMap = {
          'items': historyResp.items.map((e) => e.toJson()).toList(),
          'nextCursor': historyResp.nextCursor,
        };
        getBox.write('ref_level_cache_$lvl', cacheMap);
      } else if (!isBackground) {
        errorMessage.value = 'Failed to load level ${level.value} referrals';
      }
    } catch (e) {
      log('Error fetching level ${level.value} referral history: $e');
      if (!isBackground) {
        errorMessage.value = 'Something went wrong. Please try again.';
      }
    } finally {
      isLoading.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value ||
        nextCursor.value == null ||
        nextCursor.value!.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final cursor = Uri.encodeComponent(nextCursor.value!);
      final endpoint =
          'referrals/history?level=${level.value}&limit=20&cursor=$cursor';
      final response = await dioGet(endpoint);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;

        final historyResp = ReferralHistoryResponse.fromJson(data);
        items.addAll(historyResp.items);
        nextCursor.value = historyResp.nextCursor;

        // Update memory and disk cache with full list
        final lvl = level.value;
        _memItemsCache[lvl] = List<ReferralHistoryItem>.from(items);
        _memCursorCache[lvl] = historyResp.nextCursor;

        final cacheMap = {
          'items': items.map((e) => e.toJson()).toList(),
          'nextCursor': historyResp.nextCursor,
        };
        getBox.write('ref_level_cache_$lvl', cacheMap);
      }
    } catch (e) {
      log('Error loading more level ${level.value} referrals: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshData() async {
    await fetchLevelHistory(isRefresh: true, isBackground: false);
  }
}
