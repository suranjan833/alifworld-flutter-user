import 'package:get/get.dart';

import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../../routes/app_pages.dart';

class WishlistService extends GetxService {
  static WishlistService get to => Get.find<WishlistService>();

  final count = 0.obs;
  final wishlistedVariantIds = <String>{}.obs;
  final wishlistedProductIds = <String>{}.obs;

  static const String _kVariantIdsKey = 'wishlist_variant_ids';
  static const String _kProductIdsKey = 'wishlist_product_ids';

  @override
  void onInit() {
    super.onInit();
    _loadFromLocal();
  }

  void _loadFromLocal() {
    try {
      final rawVariants = getBox.read<List>(_kVariantIdsKey);
      if (rawVariants != null && rawVariants.isNotEmpty) {
        wishlistedVariantIds.assignAll(rawVariants.map((e) => e.toString()));
      }
      final rawProducts = getBox.read<List>(_kProductIdsKey);
      if (rawProducts != null && rawProducts.isNotEmpty) {
        wishlistedProductIds.assignAll(rawProducts.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  void _saveToLocal() {
    try {
      getBox.write(_kVariantIdsKey, wishlistedVariantIds.toList());
      getBox.write(_kProductIdsKey, wishlistedProductIds.toList());
    } catch (_) {}
  }

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final session = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (session != null && session.toString().trim().isNotEmpty);
  }

  bool isWishlisted(String? variantId, [String? productId]) {
    if (variantId != null &&
        variantId.isNotEmpty &&
        wishlistedVariantIds.contains(variantId)) {
      return true;
    }
    if (productId != null &&
        productId.isNotEmpty &&
        wishlistedProductIds.contains(productId)) {
      return true;
    }
    return false;
  }

  bool isProductWishlisted({
    String? productId,
    String? variantId,
    List<dynamic>? variants,
  }) {
    if (productId != null &&
        productId.isNotEmpty &&
        wishlistedProductIds.contains(productId)) {
      return true;
    }
    if (variantId != null &&
        variantId.isNotEmpty &&
        wishlistedVariantIds.contains(variantId)) {
      return true;
    }
    if (variants != null && variants.isNotEmpty) {
      for (final v in variants) {
        final id = v is Map ? v['id']?.toString() : v?.toString();
        if (id != null && id.isNotEmpty && wishlistedVariantIds.contains(id)) {
          return true;
        }
      }
    }
    return false;
  }

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

            for (final id in cleanIds) {
              if (returnedIds.contains(id)) {
                wishlistedVariantIds.add(id);
              } else {
                wishlistedVariantIds.remove(id);
              }
            }
            _saveToLocal();
            return returnedIds;
          }
        }
      }
    } catch (_) {}

    return wishlistedVariantIds;
  }

  Future<bool> toggleWishlist(String variantId, {String? productId}) async {
    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    if (variantId.isEmpty) return false;

    final isCurrentlyWish = isWishlisted(variantId, productId);
    final willAdd = !isCurrentlyWish;

    if (willAdd) {
      wishlistedVariantIds.add(variantId);
      if (productId != null && productId.isNotEmpty) {
        wishlistedProductIds.add(productId);
      }
      count.value++;
    } else {
      wishlistedVariantIds.remove(variantId);
      if (productId != null && productId.isNotEmpty) {
        wishlistedProductIds.remove(productId);
      }
      if (count.value > 0) count.value--;
    }
    _saveToLocal();

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
          wishlistedVariantIds.remove(variantId);
          if (productId != null && productId.isNotEmpty) {
            wishlistedProductIds.remove(productId);
          }
          if (count.value > 0) count.value--;
          _saveToLocal();

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
          wishlistedVariantIds.add(variantId);
          if (productId != null && productId.isNotEmpty) {
            wishlistedProductIds.add(productId);
          }
          count.value++;
          _saveToLocal();
          return isCurrentlyWish;
        }
      }
      return willAdd;
    } catch (_) {
      if (willAdd) {
        wishlistedVariantIds.remove(variantId);
        if (productId != null && productId.isNotEmpty) {
          wishlistedProductIds.remove(productId);
        }
        if (count.value > 0) count.value--;
      } else {
        wishlistedVariantIds.add(variantId);
        if (productId != null && productId.isNotEmpty) {
          wishlistedProductIds.add(productId);
        }
        count.value++;
      }
      _saveToLocal();
      return isCurrentlyWish;
    }
  }

  void syncLocalWishlist({
    Set<String>? variantIds,
    Set<String>? productIds,
  }) {
    if (variantIds != null) {
      wishlistedVariantIds.assignAll(variantIds);
    }
    if (productIds != null) {
      wishlistedProductIds.assignAll(productIds);
    }
    _saveToLocal();
  }

  void removeFromWishlist({String? variantId, String? productId}) {
    if (variantId != null && variantId.isNotEmpty) {
      wishlistedVariantIds.remove(variantId);
    }
    if (productId != null && productId.isNotEmpty) {
      wishlistedProductIds.remove(productId);
    }
    if (count.value > 0) count.value--;
    _saveToLocal();
  }

  void clear() {
    count.value = 0;
    wishlistedVariantIds.clear();
    wishlistedProductIds.clear();
    _saveToLocal();
  }
}
