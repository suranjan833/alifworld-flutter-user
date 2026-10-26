import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../bag/controllers/bag_controller.dart';
import '../models/product_model.dart';

class CategoryProductsController extends GetxController {
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
    }

    _initialize();
  }

  bool get isBrandView => brandSlug.value.isNotEmpty;
  bool get showSubCategorySidebar => !isBrandView && subCategories.length > 1;

  Future<void> _initialize() async {
    isLoading.value = true;
    try {
      // If viewing a category (not a brand) and no subcategories were passed, fetch from /catalog/categories
      if (!isBrandView && subCategories.length <= 1 && categorySlug.value.isNotEmpty) {
        await _fetchSubCategoriesFromApi();
      }
      await _syncWishlistFromApi();
      await _loadProductsForSelected();
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
        final name = c['name']?.toString() ?? '';
        dynSubCats.add({
          'id': c['id']?.toString() ?? slug,
          'name': name,
          'slug': slug,
          'icon': _getIconForSubcategory(slug, c['imageUrl']?.toString() ?? c['image']?.toString()),
        });
      }
    }
    subCategories.assignAll(dynSubCats);
  }

  String _getIconForSubcategory(String slug, String? existingIcon) {
    if (existingIcon != null && existingIcon.isNotEmpty) {
      return resolveImageUrl(existingIcon);
    }
    switch (slug.toLowerCase()) {
      case 'mobile-phones':
      case 'mobile':
        return 'https://cdn-icons-png.flaticon.com/512/644/644458.png';
      case 'laptops-computers':
      case 'computers':
      case 'tablets':
        return 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png';
      case 'cameras-drones':
      case 'cameras':
        return 'https://cdn-icons-png.flaticon.com/512/2950/2950711.png';
      case 'audio-headphones':
      case 'audio':
        return 'https://cdn-icons-png.flaticon.com/512/3067/3067257.png';
      case 'wearables':
        return 'https://cdn-icons-png.flaticon.com/512/2933/2933245.png';
      case 'home-appliances':
      case 'small-appliances':
        return 'https://cdn-icons-png.flaticon.com/512/3076/3076042.png';
      case 'gaming':
      case 'video-games':
        return 'https://cdn-icons-png.flaticon.com/512/1410/1410332.png';
      case 'footwear':
      case 'shoes':
        return 'https://cdn-icons-png.flaticon.com/512/5499/5499206.png';
      case 'mens-fashion':
      case 'clothing':
        return 'https://cdn-icons-png.flaticon.com/512/3531/3531744.png';
      case 'womens-fashion':
        return 'https://cdn-icons-png.flaticon.com/512/3531/3531804.png';
      default:
        return 'https://cdn-icons-png.flaticon.com/512/3081/3081986.png';
    }
  }

  Future<void> _fetchSubCategoriesFromApi() async {
    try {
      final response = await dioGet('catalog/categories');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? catList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('categories')) {
          catList = rawData['categories'] as List?;
        } else if (rawData is List) {
          catList = rawData;
        }

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

              // Check if requested category is a subcategory
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

  /// Load live products strictly from GET /catalog/search
  Future<void> _loadProductsForSelected() async {
    isProductsLoading.value = true;
    try {
      String endpoint;
      if (brandSlug.value.isNotEmpty) {
        endpoint = 'catalog/search?brand=${brandSlug.value}';
      } else {
        String targetCategory = categorySlug.value;
        if (selectedSubCategoryIndex.value > 0 &&
            selectedSubCategoryIndex.value < subCategories.length) {
          final subSlug = subCategories[selectedSubCategoryIndex.value]['slug']?.toString();
          if (subSlug != null && subSlug.isNotEmpty) {
            targetCategory = subSlug;
          }
        }
        endpoint = targetCategory.isNotEmpty
            ? 'catalog/search?category=$targetCategory'
            : 'catalog/search';
      }

      final response = await dioGet(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? productList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('products')) {
          productList = rawData['products'] as List?;
        } else if (rawData is List) {
          productList = rawData;
        }

        if (productList != null) {
          allProducts.value = productList
              .whereType<Map<String, dynamic>>()
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          allProducts.clear();
        }
      } else {
        allProducts.clear();
      }
    } catch (_) {
      allProducts.clear();
    } finally {
      isProductsLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await _loadProductsForSelected();
  }

  bool get hasLoadedOnce => _hasLoadedOnce;

  List<ProductModel> get filteredProducts => allProducts;

  int get visibleItemCount => allProducts.length;

  int get totalItemCount => allProducts.length;

  void selectSubCategory(int index) {
    if (index >= 0 && index < subCategories.length && index != selectedSubCategoryIndex.value) {
      selectedSubCategoryIndex.value = index;
      _loadProductsForSelected();
    }
  }

  Future<void> _syncWishlistFromApi() async {
    final token = getBox.read(USER_TOKEN);
    if (token == null || token.toString().isEmpty) return;
    try {
      final response = await dioGet('wishlist');
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) raw = raw['data'];
        if (raw is List) {
          final ids = <String>{};
          for (var item in raw) {
            if (item is Map) {
              if (item['productId'] != null) ids.add(item['productId'].toString());
              if (item['variantId'] != null) ids.add(item['variantId'].toString());
              if (item['product'] is Map && item['product']['id'] != null) {
                ids.add(item['product']['id'].toString());
              }
            }
          }
          if (ids.isNotEmpty) {
            wishlistedProductIds.addAll(ids);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> toggleWishlist(String productId, [String? variantId]) async {
    final vId = (variantId != null && variantId.isNotEmpty) ? variantId : productId;
    final isAdding = !wishlistedProductIds.contains(productId);
    if (isAdding) {
      wishlistedProductIds.add(productId);
    } else {
      wishlistedProductIds.remove(productId);
    }

    final token = getBox.read(USER_TOKEN);
    if (token != null && token.toString().isNotEmpty) {
      try {
        if (isAdding) {
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

    Get.snackbar(
      'Added to Bag',
      '${product.title ?? "Item"} added to bag',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.primary,
      colorText: AppColor.white,
      duration: const Duration(seconds: 2),
    );
  }
}