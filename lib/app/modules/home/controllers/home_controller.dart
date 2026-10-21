import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../models/home_category_model.dart';
import '../models/showcase_model.dart';

class HomeController extends GetxController with SkeletonLoadingMixin {
  final currentIndex = 0.obs;
  final selectedCategoryIndex = 0.obs;
  final currentBannerIndex = 0.obs;
  final currentLocation = 'Bakali coloni, Vijay Nagar, Bhuj, Gujar...'.obs;
  final isFetchingLocation = false.obs;
  final isCategoryProductsLoading = false.obs;

  final showcase = Rxn<ShowcaseModel>();

  @override
  void onInit() {
    super.onInit();
    // Defer so the shimmer is visible when the tab is first opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadHomeData();
    });
  }

  Future<void> loadHomeData() async {
    isLoading.value = true;
    try {
      await fetchCategories();
      await fetchShowcase();
    } finally {
      isLoading.value = false;
    }
  }

  /// 1. GET /catalog/categories
  Future<void> fetchCategories() async {
    try {
      final response = await dioGet('catalog/categories');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? categoryList;
        if (rawData is Map<String, dynamic> &&
            rawData.containsKey('categories')) {
          categoryList = rawData['categories'] as List?;
        } else if (rawData is List) {
          categoryList = rawData;
        }

        if (categoryList != null && categoryList.isNotEmpty) {
          final allIcon = showcase.value?.fullAllCategoryIconUrl;
          final dynCats = <HomeCategoryModel>[
            categories.first.copyWith(
              imageUrl: (allIcon != null && allIcon.isNotEmpty)
                  ? allIcon
                  : categories.first.imageUrl,
            ),
          ];

          for (int i = 0; i < categoryList.length; i++) {
            final item = categoryList[i];
            if (item is Map<String, dynamic>) {
              final catId = item['id']?.toString() ?? '';
              final catName = item['name']?.toString() ?? '';
              final catSlug = item['slug']?.toString() ?? '';
              final headerBgMobile = item['headerBgMobileUrl']?.toString();
              final imgUrl = item['imageUrl']?.toString();
              if (catName.isNotEmpty) {
                dynCats.add(HomeCategoryModel.fromApiCategory(
                  id: catId,
                  name: catName,
                  slug: catSlug,
                  headerBgMobile: headerBgMobile,
                  imageUrl: imgUrl,
                  index: i + 1,
                ));
              }
            }
          }
          categories.assignAll(dynCats);
        }
      }
    } catch (_) {}
  }

  /// 2. GET /catalog/showcase or GET /catalog/showcase?category=`<slug>`
  Future<void> fetchShowcase([String? categorySlug]) async {
    isCategoryProductsLoading.value = true;
    try {
      final isAll = categorySlug == null ||
          categorySlug.isEmpty ||
          categorySlug.toLowerCase() == 'all';
      final endpoint = isAll
          ? 'catalog/showcase'
          : 'catalog/showcase?category=$categorySlug';

      final response = await dioGet(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          final model = ShowcaseModel.fromJson(rawData);
          showcase.value = model;

          // Update brands for current showcase
          if (model.brands.isNotEmpty) {
            topBrands.assignAll(model.brands.map((b) => {
                  'name': b.name,
                  'logo': b.fullLogoUrl,
                  'slug': b.slug,
                }).toList());
          }

          // Update mobile header background if provided by showcase
          final fullMob = model.fullHeaderBgMobileUrl;
          if (fullMob.isNotEmpty) {
            final idx = selectedCategoryIndex.value;
            if (idx >= 0 && idx < categories.length) {
              categories[idx] = categories[idx].copyWith(
                headerBgMobileUrl: fullMob,
              );
            }
          }

          // Update "All" category icon if provided by showcase
          if (model.fullAllCategoryIconUrl.isNotEmpty && categories.isNotEmpty) {
            categories[0] = categories[0].copyWith(
              imageUrl: model.fullAllCategoryIconUrl,
            );
          }

          // Populate or update categories dynamically from showcase
          if (model.rawCategories.isNotEmpty) {
            if (categories.length <= 1) {
              final dynCats = <HomeCategoryModel>[
                categories.first,
              ];
              for (int i = 0; i < model.rawCategories.length; i++) {
                final rawCat = model.rawCategories[i];
                final catId = rawCat['id']?.toString() ?? '';
                final catName = rawCat['name']?.toString() ?? '';
                final catSlug = rawCat['slug']?.toString() ?? '';
                final rawImg = rawCat['imageUrl']?.toString();
                if (catName.isNotEmpty) {
                  dynCats.add(HomeCategoryModel.fromApiCategory(
                    id: catId,
                    name: catName,
                    slug: catSlug,
                    imageUrl: rawImg,
                    index: i + 1,
                  ));
                }
              }
              categories.assignAll(dynCats);
            } else {
              for (var rawCat in model.rawCategories) {
                final slug = rawCat['slug']?.toString() ?? '';
                final rawImg = rawCat['imageUrl']?.toString();
                if (slug.isNotEmpty && rawImg != null && rawImg.isNotEmpty) {
                  final fullImg = rawImg.startsWith('http')
                      ? rawImg
                      : 'https://alifworld.vercel.app$rawImg';
                  final catIdx = categories.indexWhere((c) => c.slug == slug);
                  if (catIdx != -1) {
                    categories[catIdx] =
                        categories[catIdx].copyWith(imageUrl: fullImg);
                  }
                }
              }
            }
          }

          // Populate live products across rails into current category
          final liveProducts = <Map<String, dynamic>>[];
          for (var rail in model.rails) {
            for (var prod in rail.products) {
              liveProducts.add(prod.toDetailsMap());
            }
          }
          final idx = selectedCategoryIndex.value;
          if (idx >= 0 && idx < categories.length) {
            categories[idx].products = liveProducts;
          }
          categories.refresh();
        }
      }
    } catch (_) {
    } finally {
      isCategoryProductsLoading.value = false;
      categories.refresh();
      selectedCategoryIndex.refresh();
    }
  }

  /// 3. GET /catalog/brands
  Future<void> fetchBrands() async {
    try {
      final response = await dioGet('catalog/brands');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? brandList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('brands')) {
          brandList = rawData['brands'] as List?;
        } else if (rawData is List) {
          brandList = rawData;
        }

        if (brandList != null) {
          for (var item in brandList) {
            if (item is Map<String, dynamic>) {
              final b = BrandModel.fromJson(item);
              if (b.name.isNotEmpty) {
                final logoUrl = b.logoUrl.startsWith('http')
                    ? b.logoUrl
                    : 'https://alifworld.vercel.app${b.logoUrl}';
                final alreadyHas =
                    topBrands.any((element) => element['name'] == b.name);
                if (!alreadyHas) {
                  topBrands.add({'name': b.name, 'logo': logoUrl});
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> refreshData() async {
    await loadHomeData();
  }

  final searchHints = const [
    'Search "Sofa Sets"',
    'Search "Smartphones"',
    'Search "Headphones"',
    'Search "Gaming Mouse"',
    'Search "Air Fryers"',
    'Search "Wireless Earbuds"',
    'Search "Dining Chairs"',
  ];

  final RxList<HomeCategoryModel> categories = <HomeCategoryModel>[
    HomeCategoryModel(
      id: 'all',
      name: 'All',
      slug: 'all',
      icon: 'all',
      searchHint: 'Search "Sofa Sets"',
      bannerTitle: 'TIMELESS ELEGANCE',
      bannerSubtitle: 'Crafted For You',
      bannerImage:
          'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?q=80&w=1200&auto=format&fit=crop',
      bgColor: const Color(0xFFFAF9F6),
      accentColor: const Color(0xFF3760A5),
      buttonColor: const Color(0xFF3760A5),
      subtitleColor: const Color(0xFF5A6578),
      isScriptSubtitle: true,
      products: const [],
    ),
  ].obs;

  final RxList<Map<String, String>> topBrands = <Map<String, String>>[].obs;

  HomeCategoryModel get currentCategory =>
      categories[selectedCategoryIndex.value];

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void selectCategory(int index) {
    if (index < 0 || index >= categories.length) return;
    selectedCategoryIndex.value = index;
    final cat = categories[index];
    final slug = (cat.slug == 'all' || cat.slug.isEmpty) ? '' : cat.slug;
    fetchShowcase(slug);
  }

  Future<void> toggleFavorite(int productIndex) async {
    final products = currentCategory.products;
    if (productIndex >= 0 && productIndex < products.length) {
      final isFav = !(products[productIndex]['isFavorite'] as bool? ?? false);
      products[productIndex]['isFavorite'] = isFav;
      selectedCategoryIndex.refresh();

      final prod = products[productIndex];
      String vId = '';
      if (prod['variants'] is List && (prod['variants'] as List).isNotEmpty) {
        final fv = (prod['variants'] as List).first;
        if (fv is Map && fv['id'] != null) {
          vId = fv['id'].toString();
        }
      }
      if (vId.isEmpty) {
        vId = prod['variantId']?.toString() ?? prod['id']?.toString() ?? '';
      }

      final token = getBox.read(USER_TOKEN);
      if (token != null && token.toString().isNotEmpty && vId.isNotEmpty) {
        try {
          if (isFav) {
            await dioPost(
              endUrl: 'wishlist',
              data: {'variantId': vId},
              isJson: true,
            );
          } else {
            await dioDelete('wishlist?variantId=$vId');
          }
        } catch (_) {}
      }
    }
  }

  void setLocation(String newLocation) {
    currentLocation.value = newLocation;
  }

  Future<void> fetchGPSLocation() async {
    isFetchingLocation.value = true;
    await Future.delayed(const Duration(seconds: 1));
    currentLocation.value = 'Vijay Nagar, Sector 4, Bhuj';
    isFetchingLocation.value = false;
  }
}
