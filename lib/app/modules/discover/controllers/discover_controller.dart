import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../home/models/showcase_model.dart';

class DiscoverController extends GetxController with SkeletonLoadingMixin {
  /// Categories shown in the top bar of the Discover page.
  final discoverCategories = <Map<String, dynamic>>[].obs;

  /// Index of the category currently selected in the top bar.
  final selectedCategoryIndex = 0.obs;

  final posts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCategoriesAndProducts();
    });
  }

  Future<void> fetchCategoriesAndProducts() async {
    initSkeletonLoading();
    try {
      // 1. Fetch categories
      final catRes = await dioGet('catalog/categories');
      if (catRes.statusCode == 200 && catRes.data != null) {
        dynamic raw = catRes.data;
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is List) {
          final list = <Map<String, dynamic>>[
            {
              'name': 'All',
              'slug': '',
              'image':
                  'https://cdn-icons-png.flaticon.com/512/3081/3081986.png',
              'accent': const Color(0xFFFDF0DC),
            }
          ];
          for (var item in raw) {
            if (item is Map<String, dynamic>) {
              list.add({
                'name': item['name'] ?? '',
                'slug': item['slug'] ?? '',
                'image': item['iconUrl'] ??
                    item['bannerUrl'] ??
                    'https://cdn-icons-png.flaticon.com/512/3081/3081986.png',
                'accent': const Color(0xFFE9E2F7),
              });
            }
          }
          discoverCategories.assignAll(list);
        }
      }

      // 2. Fetch products
      await fetchFeedProducts('');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFeedProducts(String categorySlug) async {
    try {
      final endpoint = categorySlug.isNotEmpty
          ? 'catalog/search?category=$categorySlug'
          : 'catalog/search';
      final res = await dioGet(endpoint);
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is List) {
          final items = <Map<String, dynamic>>[];
          for (int i = 0; i < raw.length; i++) {
            final p = raw[i];
            if (p is Map<String, dynamic>) {
              final prod = ShowcaseProductModel.fromJson(p);
              final img = prod.displayImage;
              final sellerMap = prod.seller;
              final sellerName = prod.sellerShopName ??
                  (sellerMap != null
                      ? (sellerMap['storeName']?.toString() ??
                          sellerMap['name']?.toString() ??
                          'Alif Store')
                      : 'Alif Store');
              final sellerAvatar = sellerMap != null
                  ? (sellerMap['logoUrl']?.toString() ??
                      sellerMap['avatar']?.toString() ??
                      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png')
                  : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
              items.add({
                'id': prod.id,
                'title': prod.name,
                'overlayText': '',
                'image': img,
                'sellerName': sellerName,
                'sellerAvatar': sellerAvatar,
                'likes': 0,
                'isLiked': false,
                'aspectRatio': (i % 2 == 0) ? 0.75 : 0.85,
                'productModel': prod,
                'raw': p,
              });
            }
          }
          posts.assignAll(items);
        } else {
          posts.clear();
        }
      } else {
        posts.clear();
      }
    } catch (_) {
      posts.clear();
    }
  }

  void selectCategory(int index) {
    if (index >= 0 && index < discoverCategories.length) {
      selectedCategoryIndex.value = index;
      final slug = discoverCategories[index]['slug']?.toString() ?? '';
      fetchFeedProducts(slug);
    }
  }

  void toggleLike(int index) {
    if (index >= 0 && index < posts.length) {
      final isLiked = posts[index]['isLiked'] as bool;
      posts[index]['isLiked'] = !isLiked;
      posts[index]['likes'] =
          (posts[index]['likes'] as int) + (isLiked ? -1 : 1);
      posts.refresh();
    }
  }
}
