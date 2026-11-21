import 'package:get/get.dart';

import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../../routes/app_pages.dart';

/// Centralized service for Wishlist status and badge counter per alifworld-flutter-wishlist-status.md
class WishlistService extends GetxService {
  static WishlistService get to => Get.find<WishlistService>();

  final count = 0.obs;
  final wishlistedVariantIds = <String>{}.obs;

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final session = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (session != null && session.toString().trim().isNotEmpty);
  }

  bool isWishlisted(String? variantId) {
    if (variantId == null || variantId.isEmpty) return false;
    return wishlistedVariantIds.contains(variantId);
  }

  /// Initial or badge-only count refresh
  /// GET /wishlist/status (no params) -> { data: { wishlistedVariantIds: [], count: N } }
  Future<int> refreshCount() async {
    if (!hasAuth) {
      count.value = 0;
      return 0;
    }
    try {
      final response = await dioGet('wishlist/status');
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data')) data = data['data'];
        if (data is Map && data['count'] is num) {
          final c = (data['count'] as num).toInt();
          count.value = c;
          return c;
        }
      }
    } catch (_) {}
    return count.value;
  }

  /// One status call per screen with visible variant IDs
  /// GET /wishlist/status?variantIds=v1,v2,v3 (max 200)
  Future<Set<String>> checkStatus(Iterable<String?> variantIds) async {
    if (!hasAuth) {
      count.value = 0;
      return const {};
    }

    final cleanIds = variantIds
        .where((id) => id != null && id.trim().isNotEmpty)
        .map((id) => id!.trim())
        .toSet()
        .take(200)
        .toList();

    if (cleanIds.isEmpty) {
      return const {};
    }

    try {
      final query = cleanIds.join(',');
      final response = await dioGet('wishlist/status?variantIds=$query');
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data')) data = data['data'];
        if (data is Map) {
          if (data['count'] is num) {
            count.value = (data['count'] as num).toInt();
          }
          if (data['wishlistedVariantIds'] is List) {
            final returnedIds = (data['wishlistedVariantIds'] as List)
                .map((e) => e.toString())
                .toSet();

            // Update local cache: for checked ids, update their status
            for (final id in cleanIds) {
              if (returnedIds.contains(id)) {
                wishlistedVariantIds.add(id);
              } else {
                wishlistedVariantIds.remove(id);
              }
            }
            return returnedIds;
          }
        }
      }
    } catch (_) {}

    return wishlistedVariantIds;
  }

  /// Toggle wishlist by variantId
  /// POST /wishlist or DELETE /wishlist?variantId={variantId}
  Future<bool> toggleWishlist(String variantId) async {
    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    if (variantId.isEmpty) return false;

    final isCurrentlyWish = wishlistedVariantIds.contains(variantId);
    final willAdd = !isCurrentlyWish;

    // Optimistic update
    if (willAdd) {
      wishlistedVariantIds.add(variantId);
      count.value++;
    } else {
      wishlistedVariantIds.remove(variantId);
      if (count.value > 0) count.value--;
    }

    try {
      if (willAdd) {
        final res = await dioPost(
          endUrl: 'wishlist',
          data: {'variantId': variantId},
          isJson: true,
        );
        if ((res.statusCode == 200 || res.statusCode == 201) &&
            res.data != null) {
          dynamic d = res.data;
          if (d is Map && d.containsKey('data')) d = d['data'];
          if (d is Map && d['items'] is List) {
            count.value = (d['items'] as List).length;
          }
        } else {
          // Revert on API non-success
          wishlistedVariantIds.remove(variantId);
          if (count.value > 0) count.value--;

          String? errCode;
          String? errMsg;
          if (res.data is Map) {
            final map = res.data as Map;
            if (map['error'] is Map) {
              errCode = map['error']['code']?.toString();
              errMsg = map['error']['message']?.toString();
            } else if (map['message'] != null) {
              errMsg = map['message'].toString();
            }
          }
          if (errCode == 'PRODUCT_NOT_AVAILABLE' ||
              res.statusCode == 400 ||
              (errMsg != null && errMsg.toLowerCase().contains('not available'))) {
            showSnack(
              'Not Available',
              errMsg ?? 'This product is not available right now.',
            );
          }
          return isCurrentlyWish;
        }
      } else {
        final res = await dioDelete('wishlist?variantId=$variantId');
        if (res.statusCode == 200 || res.statusCode == 204) {
          refreshCount();
        } else {
          // Revert on API non-success
          wishlistedVariantIds.add(variantId);
          count.value++;
          return isCurrentlyWish;
        }
      }
      return willAdd;
    } catch (_) {
      // Revert on error
      if (willAdd) {
        wishlistedVariantIds.remove(variantId);
        if (count.value > 0) count.value--;
      } else {
        wishlistedVariantIds.add(variantId);
        count.value++;
      }
      return isCurrentlyWish;
    }
  }

  void clear() {
    count.value = 0;
    wishlistedVariantIds.clear();
  }
}
