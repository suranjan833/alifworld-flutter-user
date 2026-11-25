import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../models/product_model.dart';

class CategoryProductsController extends GetxController {
  static const String _kCatProductsPrefix = 'cached_cat_products_v2_';
  static const String _kCatSubCatsPrefix = 'cached_cat_subcats_v2_';

  static final Map<String, List<ProductModel>> _memoryProductsCache = {};
  static final Map<String, List<Map<String, dynamic>>> _memorySubCategoriesCache = {};

  static const Map<String, String> _subCatIcons = {
    'mobile-phones': 'https://cdn-icons-png.flaticon.com/512/644/644458.png',
    'mobile': 'https://cdn-icons-png.flaticon.com/512/644/644458.png',
    'laptops-computers': 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png',
    'computers': 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png',
    'tablets': 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png',
    'cameras-drones': 'https://cdn-icons-png.flaticon.com/512/2950/2950711.png',
    'cameras': 'https://cdn-icons-png.flaticon.com/512/2950/2950711.png',
    'audio-headphones': 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png',
    'audio': 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png',
    'wearables': 'https://cdn-icons-png.flaticon.com/512/2933/2933245.png',
    'home-appliances': 'https://cdn-icons-png.flaticon.com/512/3076/3076042.png',
    'small-appliances': 'https://cdn-icons-png.flaticon.com/512/3076/3076042.png',
    'gaming': 'https://cdn-icons-png.flaticon.com/512/1410/1410332.png',
    'video-games': 'https://cdn-icons-png.flaticon.com/512/1410/1410332.png',
    'footwear': 'https://cdn-icons-png.flaticon.com/512/5499/5499206.png',
    'shoes': 'https://cdn-icons-png.flaticon.com/512/5499/5499206.png',
    'mens-fashion': 'https://cdn-icons-png.flaticon.com/512/3531/3531744.png',
    'clothing': 'https://cdn-icons-png.flaticon.com/512/3531/3531744.png',
    'womens-fashion': 'https://cdn-icons-png.flaticon.com/512/3531/3531804.png',
  };

  final categoryName = 'All Categories'.obs;
  final categoryImage = ''.obs;
  final categorySlug = ''.obs;
  final brandSlug = ''.obs;

  final selectedSubCategoryIndex = 0.obs;
  final wishlistedProductIds = <String>{}.obs;

  final subCategories = <Map<String, dynamic>>[
    {
      'id': 'all',
      'name': 'All',
      'slug': '',
      'icon': 'https://cdn-icons-png.flaticon.com/512/3081/3081986.png',
    },
  ].obs;

  final allProducts = <ProductModel>[].obs;
  final isLoading = true.obs;
  final isProductsLoading = false.obs;
  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    List<ProductModel>? initialPassedProducts;

    if (args != null && args is Map) {
      if (args.containsKey('name') && args['name'] != null) {
        categoryName.value = args['name'].toString();
      }
      final rawImg = args['imageUrl'] ?? args['image'] ?? args['icon'];
      if (rawImg != null &&
          rawImg.toString() != 'null' &&
          rawImg.toString().trim().isNotEmpty) {
        categoryImage.value = rawImg.toString().trim();
      }
      if (args.containsKey('slug') && args['slug'] != null) {
        categorySlug.value = args['slug'].toString();
      }
      if (args.containsKey('brandSlug')) {
        brandSlug.value = args['brandSlug'].toString();
      } else if (args.containsKey('brand')) {
        brandSlug.value = args['brand'].toString().toLowerCase();
      }

      if (args.containsKey('children') && args['children'] is List) {
        final childrenList = args['children'] as List;
        if (childrenList.isNotEmpty) {
          _populateSubCategories(childrenList);
        }
      }

      if (args.containsKey('initialProducts') && args['initialProducts'] is List) {
        try {
          final rawInit = args['initialProducts'] as List;
          initialPassedProducts = rawInit
              .whereType<Map>()
              .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } catch (_) {}
      }
    }

    _loadFromCache(initialPassedProducts: initialPassedProducts);
    _initialize(isSilent: allProducts.isNotEmpty);
  }

  bool get isBrandView => brandSlug.value.isNotEmpty;
  bool get showSubCategorySidebar => !isBrandView && subCategories.length > 1;

  String _getCacheKey(String slugOrCategory) {
    if (isBrandView) return 'brand_${brandSlug.value.toLowerCase().trim()}';
    final s = slugOrCategory.toLowerCase().trim();
    return s.isNotEmpty ? s : 'all';
  }

  List<ProductModel>? _getStoredProducts(String cacheKey) {
    if (_memoryProductsCache.containsKey(cacheKey) &&
        _memoryProductsCache[cacheKey]!.isNotEmpty) {
      return _memoryProductsCache[cacheKey];
    }
    try {
      final stored = getBox.read('$_kCatProductsPrefix$cacheKey');
      if (stored is List && stored.isNotEmpty) {
        final list = stored
            .whereType<Map>()
            .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          _memoryProductsCache[cacheKey] = list;
          return list;
        }
      }
    } catch (_) {}
    return null;
  }

  void _loadFromCache({List<ProductModel>? initialPassedProducts}) {
    final rootSlug = categorySlug.value.toLowerCase().trim();

    if (!isBrandView && subCategories.length <= 1 && rootSlug.isNotEmpty) {
      if (_memorySubCategoriesCache.containsKey(rootSlug) &&
          _memorySubCategoriesCache[rootSlug]!.isNotEmpty) {
        subCategories.assignAll(_memorySubCategoriesCache[rootSlug]!);
      } else {
        try {
          final storedSub = getBox.read('$_kCatSubCatsPrefix$rootSlug');
          if (storedSub is List && storedSub.isNotEmpty) {
            final parsedSub = storedSub
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (parsedSub.isNotEmpty) {
              _memorySubCategoriesCache[rootSlug] = parsedSub;
              subCategories.assignAll(parsedSub);
            }
          }
        } catch (_) {}
      }
    }

    final cacheKey = _getCacheKey(rootSlug);
    if (initialPassedProducts != null && initialPassedProducts.isNotEmpty) {
      allProducts.assignAll(initialPassedProducts);
      _memoryProductsCache[cacheKey] = initialPassedProducts;
      isLoading.value = false;
      return;
    }

    final cached = _getStoredProducts(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      allProducts.assignAll(cached);
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
  }

  Future<void> _initialize({bool isSilent = false}) async {
    if (!isSilent) isLoading.value = true;
    try {
      if (!isBrandView && subCategories.length <= 1 && categorySlug.value.isNotEmpty) {
        await _fetchSubCategoriesFromApi();
      }
      await _syncWishlistFromApi();
      await _loadProductsForSelected(isSilent: isSilent);
    } finally {
      isLoading.value = false;
      _hasLoadedOnce = true;
    }
  }

  void _populateSubCategories(List childrenList, {String? parentSlug}) {
    final rootSlug = parentSlug ?? categorySlug.value;
    final dynSubCats = <Map<String, dynamic>>[
      {
        'id': 'all',
        'name': 'All',
        'slug': rootSlug,
        'icon': 'https://cdn-icons-png.flaticon.com/512/3081/3081986.png',
      },
    ];
    for (var c in childrenList) {
      if (c is Map) {
        final slug = c['slug']?.toString() ?? '';
        dynSubCats.add({
          'id': c['id']?.toString() ?? slug,
          'name': c['name']?.toString() ?? '',
          'slug': slug,
          'icon': _getIconForSubcategory(slug, c['imageUrl']?.toString() ?? c['image']?.toString()),
        });
      }
    }
    subCategories.assignAll(dynSubCats);

    final cacheSubKey = rootSlug.toLowerCase().trim();
    if (cacheSubKey.isNotEmpty) {
      _memorySubCategoriesCache[cacheSubKey] = dynSubCats;
      try {
        getBox.write('$_kCatSubCatsPrefix$cacheSubKey', dynSubCats);
      } catch (_) {}
    }
  }

  String _getIconForSubcategory(String slug, String? existingIcon) {
    if (existingIcon != null && existingIcon.isNotEmpty) {
      return resolveImageUrl(existingIcon);
    }
    return _subCatIcons[slug.toLowerCase()] ?? 'https://cdn-icons-png.flaticon.com/512/3081/3081986.png';
  }

  Future<void> _fetchSubCategoriesFromApi() async {
    try {
      final response = await dioGet('catalog/categories');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? catList = rawData is Map<String, dynamic> && rawData.containsKey('categories')
            ? rawData['categories'] as List?
            : (rawData is List ? rawData : null);

        if (catList != null) {
          final currentSlug = categorySlug.value.toLowerCase();
          final currentName = categoryName.value.toLowerCase();

          for (var item in catList) {
            if (item is Map) {
              final s = item['slug']?.toString().toLowerCase() ?? '';
              final n = item['name']?.toString().toLowerCase() ?? '';
              final children = item['children'] as List?;

              if (s == currentSlug || n == currentName || s.contains(currentSlug) || currentSlug.contains(s)) {
                final catImg = item['imageUrl']?.toString() ?? item['image']?.toString();
                if (catImg != null && catImg != 'null' && catImg.isNotEmpty) {
                  if (categoryImage.value.isEmpty || categoryImage.value == 'null') {
                    categoryImage.value = catImg;
                  }
                }
                if (children != null && children.isNotEmpty) {
                  _populateSubCategories(children, parentSlug: s);
                  break;
                }
              }

              if (children != null && children.isNotEmpty) {
                final matchedChild = children.firstWhere(
                  (c) =>
                      c is Map &&
                      (c['slug']?.toString().toLowerCase() == currentSlug ||
                          c['name']?.toString().toLowerCase() == currentName),
                  orElse: () => null,
                );

                if (matchedChild != null) {
                  _populateSubCategories(children, parentSlug: s);
                  final targetSlug = matchedChild['slug']?.toString() ?? '';
                  final foundIdx = subCategories.indexWhere(
                    (el) => el['slug']?.toString() == targetSlug,
                  );
                  if (foundIdx != -1) {
                    selectedSubCategoryIndex.value = foundIdx;
                  }
                  categoryName.value = item['name']?.toString() ?? categoryName.value;
                  break;
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProductsForSelected({bool isSilent = false}) async {
    String targetCategory = categorySlug.value;
    if (selectedSubCategoryIndex.value > 0 &&
        selectedSubCategoryIndex.value < subCategories.length) {
      final subSlug = subCategories[selectedSubCategoryIndex.value]['slug']?.toString();
      if (subSlug != null && subSlug.isNotEmpty) {
        targetCategory = subSlug;
      }
    }

    final cacheKey = _getCacheKey(targetCategory);
    if (!isSilent && allProducts.isEmpty) {
      isProductsLoading.value = true;
    }

    try {
      final endpoint = brandSlug.value.isNotEmpty
          ? 'catalog/search?brand=${brandSlug.value}'
          : (targetCategory.isNotEmpty
              ? 'catalog/search?category=$targetCategory'
              : 'catalog/search');

      final response = await dioGet(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? productList = rawData is Map<String, dynamic> && rawData.containsKey('products')
            ? rawData['products'] as List?
            : (rawData is List ? rawData : null);

        if (productList != null) {
          final freshList = productList
              .whereType<Map<String, dynamic>>()
              .map((item) => ProductModel.fromJson(item))
              .toList();

          if (!_areProductListsEqual(allProducts, freshList)) {
            allProducts.assignAll(freshList);
            _memoryProductsCache[cacheKey] = freshList;
            try {
              getBox.write('$_kCatProductsPrefix$cacheKey', productList);
            } catch (_) {}
          } else {
            _memoryProductsCache[cacheKey] = freshList;
          }
        } else if (allProducts.isEmpty) {
          allProducts.clear();
        }
      }
    } catch (_) {
    } finally {
      isProductsLoading.value = false;
    }
  }

  bool _areProductListsEqual(List<ProductModel> a, List<ProductModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].price != b[i].price ||
          a[i].originalPrice != b[i].originalPrice ||
          a[i].stockQty != b[i].stockQty ||
          a[i].productPoints != b[i].productPoints ||
          a[i].title != b[i].title) {
        return false;
      }
    }
    return true;
  }

  Future<void> refreshProducts() async {
    await _loadProductsForSelected(isSilent: false);
  }

  bool get hasLoadedOnce => _hasLoadedOnce;
  List<ProductModel> get filteredProducts => allProducts;
  int get visibleItemCount => allProducts.length;
  int get totalItemCount => allProducts.length;

  void selectSubCategory(int index) {
    if (index >= 0 && index < subCategories.length && index != selectedSubCategoryIndex.value) {
      selectedSubCategoryIndex.value = index;

      final subSlug = subCategories[index]['slug']?.toString() ?? '';
      final targetCat = subSlug.isNotEmpty ? subSlug : categorySlug.value;
      final cacheKey = _getCacheKey(targetCat);

      final cached = _getStoredProducts(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        allProducts.assignAll(cached);
        isProductsLoading.value = false;
        _loadProductsForSelected(isSilent: true);
      } else {
        allProducts.clear();
        isProductsLoading.value = true;
        _loadProductsForSelected(isSilent: false);
      }
    }
  }

  bool isVariantWishlisted(String? vId, [String? pId]) {
    if ((vId == null || vId.isEmpty) && (pId == null || pId.isEmpty)) return false;
    return wishlistedProductIds.contains(vId) ||
        (pId != null && wishlistedProductIds.contains(pId)) ||
        (Get.isRegistered<WishlistService>() &&
            WishlistService.to.isWishlisted(vId, pId));
  }

  Future<void> _syncWishlistFromApi() async {
    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) return;

    final visibleVariantIds = <String>[];
    for (final p in allProducts) {
      if (p.variants != null && p.variants!.isNotEmpty) {
        final fv = p.variants!.first;
        if (fv['id'] != null) {
          visibleVariantIds.add(fv['id'].toString());
        }
      }
    }

    if (visibleVariantIds.isNotEmpty) {
      await wishlistSvc.checkStatus(visibleVariantIds);
      wishlistedProductIds.assignAll(wishlistSvc.wishlistedVariantIds);
    }
  }

  Future<void> toggleWishlist(String productId, [String? variantId]) async {
    String resolvedVariantId =
        (variantId != null && variantId.isNotEmpty) ? variantId : '';
    if (resolvedVariantId.isEmpty) {
      final prod = allProducts.firstWhereOrNull((p) => p.id == productId);
      if (prod?.variants != null && prod!.variants!.isNotEmpty) {
        final fv = prod.variants!.first;
        if (fv['id'] != null) {
          resolvedVariantId = fv['id'].toString();
        }
      }
    }
    if (resolvedVariantId.isEmpty) return;

    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    await wishlistSvc.toggleWishlist(resolvedVariantId);
    wishlistedProductIds.assignAll(wishlistSvc.wishlistedVariantIds);
  }

  Future<void> addToCart(ProductModel product) async {
    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController());
    }
    final bagCtrl = Get.find<BagController>();

    final vId = (product.variants != null && product.variants!.isNotEmpty)
        ? product.variants!.first['id']?.toString()
        : null;

    await bagCtrl.addItemToBag({
      'id': product.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'productId': product.id ?? '',
      'variantId': vId,
      'variants': product.variants,
      'title': product.title ?? 'Product',
      'price': product.price,
      'image': product.image ?? '',
      'brand': product.brand ?? 'Alif',
      'slug': product.slug,
    });
    await bagCtrl.fetchCart(showLoading: false, force: true);
    bagCtrl.cartItems.refresh();
  }
}
