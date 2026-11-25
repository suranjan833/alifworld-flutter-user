import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../data/widgets/app_cached_image.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
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

  // In-memory cache for fast category switching
  final Map<String, ShowcaseModel> _showcaseCache = {};

  // Cache keys & TTL
  static const String _kCachedCategories = 'cached_home_categories';
  static const String _kCachedCategoriesTs = 'cached_home_categories_ts';
  static const String _kCachedShowcaseAll = 'cached_home_showcase_all';
  static const String _kCachedShowcaseAllTs = 'cached_home_showcase_all_ts';

  static const int _categoriesTtlMs = 30 * 60 * 1000; // 30 minutes
  static const int _showcaseTtlMs = 10 * 60 * 1000; // 10 minutes

  @override
  void onInit() {
    super.onInit();
    _loadFromLocalCache();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadHomeData());
  }

  void _loadFromLocalCache() {
    try {
      final cachedCats = getBox.read(_kCachedCategories);
      if (cachedCats is List && cachedCats.isNotEmpty) {
        _applyCategoryList(cachedCats);
      }

      final cachedShowcase = getBox.read(_kCachedShowcaseAll);
      if (cachedShowcase is Map) {
        _applyShowcaseData(
          Map<String, dynamic>.from(cachedShowcase),
          categorySlug: 'all',
          isCacheLoad: true,
        );
      }

      // If we have cached showcase & categories, dismiss loading immediately
      if (showcase.value != null && categories.length > 1) {
        isLoading.value = false;
      }
    } catch (_) {}
  }

  @override
  void onReady() {
    super.onReady();
    _fetchCartOnHomeLoad();
  }

  void _fetchCartOnHomeLoad() {
    try {
      if (!Get.isRegistered<BagController>()) {
        Get.put<BagController>(BagController(), permanent: true);
      }
      Get.find<BagController>().fetchCart(showLoading: false, force: true);
    } catch (_) {}
  }

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    // Only show shimmer if we don't have cached data displayed yet
    if (showcase.value == null || categories.length <= 1) {
      isLoading.value = true;
    }

    try {
      _fetchCartOnHomeLoad();
      if (Get.isRegistered<WishlistService>()) {
        WishlistService.to.refreshCount();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final catsTs = getBox.read<int>(_kCachedCategoriesTs) ?? 0;
      final isCatsExpired = (now - catsTs) > _categoriesTtlMs;

      final showcaseTs = getBox.read<int>(_kCachedShowcaseAllTs) ?? 0;
      final isShowcaseExpired = (now - showcaseTs) > _showcaseTtlMs;

      // Run parallel network requests only when expired, forced, or missing
      final tasks = <Future>[];
      if (forceRefresh || isCatsExpired || categories.length <= 1) {
        tasks.add(fetchCategories(force: forceRefresh));
      }
      if (forceRefresh || isShowcaseExpired || showcase.value == null) {
        tasks.add(fetchShowcase('all', forceRefresh));
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _applyCategoryList(List categoryList) {
    if (categoryList.isEmpty) return;
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
      if (item is Map) {
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

  /// 1. GET /catalog/categories
  Future<void> fetchCategories({bool force = false}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final catsTs = getBox.read<int>(_kCachedCategoriesTs) ?? 0;
      final isExpired = (now - catsTs) > _categoriesTtlMs;

      // Skip API if cache is fresh and not forced
      if (!force && !isExpired && categories.length > 1) {
        return;
      }

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
          _applyCategoryList(categoryList);
          try {
            getBox.write(_kCachedCategories, categoryList);
            getBox.write(_kCachedCategoriesTs, now);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _applyShowcaseData(
    Map<String, dynamic> rawData, {
    String? categorySlug,
    bool isCacheLoad = false,
  }) {
    final model = ShowcaseModel.fromJson(rawData);
    showcase.value = model;

    final isAll = categorySlug == null ||
        categorySlug.isEmpty ||
        categorySlug.toLowerCase() == 'all';
    final cacheKey = isAll ? 'all' : categorySlug.toLowerCase();
    _showcaseCache[cacheKey] = model;

    // Cache to GetStorage if it's the main 'all' showcase and not loaded from cache
    if (isAll && !isCacheLoad) {
      try {
        getBox.write(_kCachedShowcaseAll, rawData);
        getBox.write(
            _kCachedShowcaseAllTs, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
    }

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
            final fullImg = resolveImageUrl(rawImg);
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
    syncWishlistToProducts();

    // Silently pre-cache top banners and images into disk & RAM
    _precacheShowcaseImages(model);
  }

  void _precacheShowcaseImages(ShowcaseModel model) {
    try {
      final context = Get.context;
      if (context == null) return;

      if (model.fullHeaderBgMobileUrl.isNotEmpty) {
        AppCachedImage.precache(context, model.fullHeaderBgMobileUrl);
      }

      for (final mb in model.miniBanners.take(4)) {
        if (mb.fullImageUrl.isNotEmpty) {
          AppCachedImage.precache(context, mb.fullImageUrl);
        }
      }

      for (final b in model.brands.take(6)) {
        if (b.fullLogoUrl.isNotEmpty) {
          AppCachedImage.precache(context, b.fullLogoUrl);
        }
      }
    } catch (_) {}
  }

  /// 2. GET /catalog/showcase or GET /catalog/showcase?category=`<slug>`
  Future<void> fetchShowcase([String? categorySlug, bool force = false]) async {
    final isAll = categorySlug == null ||
        categorySlug.isEmpty ||
        categorySlug.toLowerCase() == 'all';
    final cacheKey = isAll ? 'all' : categorySlug.toLowerCase();

    // Check memory cache first
    if (!force && _showcaseCache.containsKey(cacheKey)) {
      final cachedModel = _showcaseCache[cacheKey]!;
      showcase.value = cachedModel;
      final idx = selectedCategoryIndex.value;
      if (idx >= 0 && idx < categories.length) {
        final liveProds = <Map<String, dynamic>>[];
        for (var r in cachedModel.rails) {
          for (var p in r.products) {
            liveProds.add(p.toDetailsMap());
          }
        }
        categories[idx].products = liveProds;
        categories.refresh();
      }
      return;
    }

    isCategoryProductsLoading.value = true;
    try {
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
          _applyShowcaseData(rawData, categorySlug: categorySlug);
        }
      }
    } catch (_) {
    } finally {
      isCategoryProductsLoading.value = false;
      categories.refresh();
      selectedCategoryIndex.refresh();
    }
  }

  Future<void> fetchBrands() async {
    try {
      final response = await dioGet('catalog/brands');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        final brandList = (rawData is Map && rawData['brands'] is List)
            ? rawData['brands'] as List
            : (rawData is List ? rawData : null);
        if (brandList != null) {
          for (var item in brandList) {
            if (item is Map<String, dynamic>) {
              final b = BrandModel.fromJson(item);
              if (b.name.isNotEmpty && !topBrands.any((e) => e['name'] == b.name)) {
                topBrands.add({'name': b.name, 'logo': resolveImageUrl(b.logoUrl)});
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> refreshData() async => loadHomeData(forceRefresh: true);

  final searchHints = const [
    'Search "Sofa Sets"',
    'Search "Smartphones"',
    'Search "Headphones"',
    'Search "Gaming Mouse"',
    'Search "Air Fryers"',
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
  HomeCategoryModel get currentCategory => categories[selectedCategoryIndex.value];

  void changeTab(int index) => currentIndex.value = index;

  void selectCategory(int index) {
    if (index < 0 || index >= categories.length || selectedCategoryIndex.value == index) return;
    selectedCategoryIndex.value = index;
    final cat = categories[index];
    final slug = (cat.slug == 'all' || cat.slug.isEmpty) ? '' : cat.slug;
    currentBannerIndex.value = 0;
    fetchShowcase(slug);
  }

  String _extractVariantId(Map prod) {
    final v = prod['variants'];
    if (v is List && v.isNotEmpty && v.first is Map && v.first['id'] != null) {
      return v.first['id'].toString();
    }
    return prod['variantId']?.toString() ?? '';
  }

  Future<void> syncWishlistToProducts() async {
    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) return;

    final visibleVariantIds = <String>[];
    for (final r in (showcase.value?.rails ?? [])) {
      for (final p in r.products) {
        final vId = p.variantId ?? (p.variants.isNotEmpty ? p.variants.first['id']?.toString() : null);
        if (vId != null && vId.isNotEmpty) visibleVariantIds.add(vId);
      }
    }
    for (final cat in categories) {
      for (final prod in cat.products) {
        final vId = _extractVariantId(prod);
        if (vId.isNotEmpty) visibleVariantIds.add(vId);
      }
    }
    if (visibleVariantIds.isNotEmpty) {
      await wishlistSvc.checkStatus(visibleVariantIds);
    }
  }

  Future<void> toggleProductWishlist(Map<String, dynamic> product) async {
    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) return Get.toNamed(Routes.LOGIN);

    final pId = product['productId']?.toString() ?? product['id']?.toString() ?? '';
    final vId = _extractVariantId(product);
    final targetId = vId.isNotEmpty ? vId : pId;
    if (targetId.isNotEmpty) {
      await wishlistSvc.toggleWishlist(targetId, productId: pId.isNotEmpty ? pId : null);
    }
  }

  Future<void> toggleFavorite(int productIndex) async {
    final products = currentCategory.products;
    if (productIndex >= 0 && productIndex < products.length) {
      await toggleProductWishlist(products[productIndex]);
    }
  }

  void setLocation(String newLocation) => currentLocation.value = newLocation;

  Future<void> fetchGPSLocation() async {
    isFetchingLocation.value = true;
    await Future.delayed(const Duration(seconds: 1));
    currentLocation.value = 'Vijay Nagar, Sector 4, Bhuj';
    isFetchingLocation.value = false;
  }
}
