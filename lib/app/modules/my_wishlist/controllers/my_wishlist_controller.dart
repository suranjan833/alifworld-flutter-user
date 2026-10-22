import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
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
        if (rawData is List) {
          final items = rawData.map<Map<String, dynamic>>((e) {
            Map<String, dynamic>? v;
            if (e is Map<String, dynamic> && e['variant'] is Map<String, dynamic>) {
              v = e['variant'] as Map<String, dynamic>;
            }
            final p = (v != null && v['product'] is Map<String, dynamic>)
                ? v['product'] as Map<String, dynamic>
                : ((e is Map<String, dynamic> && e['product'] is Map<String, dynamic>)
                    ? e['product'] as Map<String, dynamic>
                    : (e is Map<String, dynamic> ? e : <String, dynamic>{}));

            final priceMinor = v?['priceMinor'] ?? p['priceMinor'] ?? e['priceMinor'] ?? 0;
            final price = (priceMinor / 100.0).toStringAsFixed(2);

            final comparePriceMinor = v?['compareAtPriceMinor'] ?? p['compareAtPriceMinor'] ?? 0;
            final origPrice = comparePriceMinor > priceMinor
                ? '৳${(comparePriceMinor / 100.0).toStringAsFixed(2)}'
                : '';

            List? images = v?['images'] ?? p['images'] ?? (e is Map ? e['images'] as List? : null);
            String img = '';
            if (images != null && images.isNotEmpty && images.first != null) {
              img = images.first.toString();
              if (!img.startsWith('http')) img = 'https://alifworld.vercel.app$img';
            } else if (p['image'] != null) {
              img = p['image'].toString();
              if (!img.startsWith('http')) img = 'https://alifworld.vercel.app$img';
            }

            final variantId = e['variantId']?.toString() ??
                v?['id']?.toString() ??
                p['variantId']?.toString() ??
                p['id']?.toString() ??
                '';

            return {
              'id': e['id']?.toString() ?? p['id']?.toString() ?? variantId,
              'productId': p['id']?.toString() ?? '',
              'variantId': variantId,
              'title': p['title']?.toString() ?? p['name']?.toString() ?? 'Product',
              'brand': p['brand'] is Map
                  ? (p['brand'] as Map)['name']?.toString() ?? 'Alif'
                  : (p['brand']?.toString() ?? 'Alif'),
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
        } else {
          wishlistItems.clear();
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
    final vId = (variantId != null && variantId.isNotEmpty) ? variantId : id;
    wishlistItems.removeWhere((item) =>
        item['id'] == id || item['variantId'] == id || item['variantId'] == vId);

    try {
      await dioDelete('wishlist?variantId=$vId');
    } catch (_) {}

    Get.snackbar(
      'Removed',
      'Item removed from wishlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.textPrimary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// 3. DELETE /wishlist - Clear entire wishlist
  Future<void> clearWishlist() async {
    wishlistItems.clear();
    try {
      await dioDelete('wishlist');
    } catch (_) {}

    Get.snackbar(
      'Wishlist Cleared',
      'All items removed from your wishlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.textPrimary,
      colorText: Colors.white,
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

    Get.snackbar(
      'Added to Bag',
      '${item['title']} moved to bag',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
