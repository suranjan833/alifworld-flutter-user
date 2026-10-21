import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Mixin that gives any GetxController a one-line simulated initial load.
///
/// While [isLoading] is true, views show their shimmer skeleton. Swap the
/// body of [fetchData] for a real API call later — the skeleton flow and
/// [refreshData] keep working unchanged.
mixin SkeletonLoadingMixin on GetxController {
  /// Whether the initial load has finished. Starts true so the shimmer
  /// shows from the very first frame.
  final isLoading = true.obs;

  bool _hasLoadedOnce = false;
  Timer? _debounce;

  /// Kick off the initial load. Call from [onInit].
  void initSkeletonLoading() {
    _runLoad();
  }

  /// Simulated network fetch. Replace with the real API call.
  Future<void> fetchData() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  /// Re-runs the skeleton briefly on pull-to-refresh.
  Future<void> refreshData() async {
    if (isLoading.value) return;
    await _runLoad();
  }

  Future<void> _runLoad() async {
    isLoading.value = true;
    try {
      await fetchData();
    } finally {
      _hasLoadedOnce = true;
      isLoading.value = false;
    }
  }

  /// True after the first successful load completes.
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// Debounced helper if a page wants search-as-you-type loading.
  void debounceLoad(
    VoidCallback load, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, load);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
