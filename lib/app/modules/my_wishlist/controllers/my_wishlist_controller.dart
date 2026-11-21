import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/services/wishlist_service.dart';
import '../../bag/controllers/bag_controller.dart';

class MyWishlistController extends GetxController with SkeletonLoadingMixin {
  final wishlistItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  /// 1. GET /wishlist - Fetch user wishlist from API
  Future<void> fetchWishlist() async {
    initSkeletonLoading();
    try {
      final response = await dioGet('wishlist');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? rawList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('items')) {
          rawList = rawData['items'] as List?;
        } else if (rawData is List) {
          rawList = rawData;
        }

        if (rawList != null) {
          final items = rawList.map<Map<String, dynamic>>((e) {
            Map<String, dynamic>? v;
            if (e is Map<String, dynamic> &&
                e['variant'] is Map<String, dynamic>) {
              v = e['variant'] as Map<String, dynamic>;
            }
            final p = (e is Map<String, dynamic> &&
                    e['product'] is Map<String, dynamic>)
                ? e['product'] as Map<String, dynamic>
                : ((v != null && v['product'] is Map<String, dynamic>)
                    ? v['product'] as Map<String, dynamic>
                    : (e is Map<String, dynamic> ? e : <String, dynamic>{}));

            final priceMinor =
                p['priceMinor'] ?? v?['priceMinor'] ?? e['priceMinor'] ?? 0;
            final price = (priceMinor / 100.0).toStringAsFixed(2);

            final comparePriceMinor =
                p['compareAtPriceMinor'] ?? v?['compareAtPriceMinor'] ?? 0;
            final origPrice = comparePriceMinor > priceMinor
                ? '৳${(comparePriceMinor / 100.0).toStringAsFixed(2)}'
                : '';

            List? images =
                p['images'] ??
                v?['images'] ??
                (e is Map ? e['images'] as List? : null);
            String img = '';
            if (images != null && images.isNotEmpty && images.first != null) {
              img = resolveImageUrl(images.first.toString());
            } else if (p['imageUrl'] != null &&
                p['imageUrl'].toString().isNotEmpty) {
              img = resolveImageUrl(p['imageUrl'].toString());
            } else if (p['image'] != null &&
                p['image'].toString().isNotEmpty) {
              img = resolveImageUrl(p['image'].toString());
            }

            final variantId =
                e['variantId']?.toString() ??
                v?['id']?.toString() ??
                p['variantId']?.toString() ??
                '';

            return {
              'id': e['id']?.toString() ?? variantId,
              'productId': p['id']?.toString() ?? '',
              'variantId': variantId,
              'title':
                  p['name']?.toString() ?? p['title']?.toString() ?? 'Product',
              'brand': p['brandName']?.toString() ??
                  (p['brand'] is Map
                      ? (p['brand'] as Map)['name']?.toString() ?? 'Alif'
                      : (p['brand']?.toString() ?? 'Alif')),
              'price': '৳$price',
              'rawPrice': priceMinor / 100.0,
              'originalPrice': origPrice,
              'discount': '',
              'image': img,
              'slug': p['slug']?.toString() ?? '',
              'raw': e,
            };
          }).toList();
          wishlistItems.assignAll(items);
          if (Get.isRegistered<WishlistService>()) {
            WishlistService.to.count.value = items.length;
            final currentIds = items
                .map((it) => it['variantId']?.toString())
                .where((id) => id != null && id.isNotEmpty)
                .cast<String>()
                .toSet();
            WishlistService.to.wishlistedVariantIds.assignAll(currentIds);
          }
        } else {
          wishlistItems.clear();
          if (Get.isRegistered<WishlistService>()) {
            WishlistService.to.count.value = 0;
            WishlistService.to.wishlistedVariantIds.clear();
          }
        }
      } else {
        wishlistItems.clear();
      }
    } catch (_) {
      wishlistItems.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. DELETE /wishlist?variantId={variantId} - Remove specific variant from wishlist
  Future<void> removeItem(String id, [String? variantId]) async {
    String vId = (variantId != null && variantId.isNotEmpty) ? variantId : '';
    if (vId.isEmpty) {
      final existing = wishlistItems.firstWhereOrNull(
        (item) => item['id'] == id || item['variantId'] == id,
      );
      vId = existing?['variantId']?.toString() ?? id;
    }

    wishlistItems.removeWhere(
      (item) =>
          item['id'] == id ||
          item['variantId'] == id ||
          item['variantId'] == vId,
    );

    if (Get.isRegistered<WishlistService>()) {
      if (vId.isNotEmpty) {
        WishlistService.to.wishlistedVariantIds.remove(vId);
      }
      if (WishlistService.to.count.value > 0) {
        WishlistService.to.count.value--;
      }
    }

    try {
      if (vId.isNotEmpty) {
        await dioDelete('wishlist?variantId=$vId');
        if (Get.isRegistered<WishlistService>()) {
          WishlistService.to.refreshCount();
        }
      }
    } catch (_) {}

    Get.snackbar(
      'Removed',
      'Item removed from wishlist',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.textPrimary,
      colorText: AppColor.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// 3. Clear entire wishlist by deleting each wishlisted variant
  Future<void> clearWishlist() async {
    final idsToDelete = wishlistItems
        .map((e) => e['variantId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    wishlistItems.clear();
    if (Get.isRegistered<WishlistService>()) {
      WishlistService.to.clear();
    }

    for (final vId in idsToDelete) {
      try {
        await dioDelete('wishlist?variantId=$vId');
      } catch (_) {}
    }
    if (Get.isRegistered<WishlistService>()) {
      WishlistService.to.refreshCount();
    }

    Get.snackbar(
      'Wishlist Cleared',
      'All items removed from your wishlist',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.textPrimary,
      colorText: AppColor.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> addToBag(Map<String, dynamic> item) async {
    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController());
    }
    final bagCtrl = Get.find<BagController>();
    await bagCtrl.addItemToBag(item);
    await bagCtrl.fetchCart(showLoading: false, force: true);
    bagCtrl.cartItems.refresh();
  }
}
