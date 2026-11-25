import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../categories/models/product_model.dart';
import '../models/search_result_model.dart';

class CatalogSearchController extends GetxController {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();

  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isCategoriesLoading = false.obs;

  final products = <ProductModel>[].obs;
  final ranges = Rxn<SearchRangesModel>();
  final cursor = RxnString();
  final hasMore = false.obs;

  // Filters & Sorting
  final selectedCategorySlug = ''.obs;
  final selectedCategoryName = ''.obs;
  final selectedSort = 'relevance'.obs; // relevance, newest, price_asc, price_desc
  final minPriceFilter = RxnDouble();
  final maxPriceFilter = RxnDouble();

  // Categories list for filter chips
  final categories = <Map<String, dynamic>>[].obs;

  // Recent Searches
  static const String _recentSearchesKey = 'catalog_recent_searches';
  final recentSearches = <String>[].obs;

  // Popular / Trending keywords
  final popularSearches = const [
    'Saree',
    'Bed Sheet',
    'Ghee',
    'Geyser',
    'Water Heater',
    'Night Cream',
    'Midea',
    'Konka',
  ];

  // Wishlist state
  final wishlistedProductIds = <String>{}.obs;

  Timer? _debounceTimer;

  bool get isPreSearch => searchQuery.value.trim().isEmpty && selectedCategorySlug.value.isEmpty;
  bool get hasActiveFilter =>
      selectedSort.value != 'relevance' ||
      selectedCategorySlug.value.isNotEmpty ||
      minPriceFilter.value != null ||
      maxPriceFilter.value != null;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _fetchCategories();
    _syncWishlist();

    scrollController.addListener(_onScroll);

    // Read initial arguments if provided
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['query'] != null && args['query'].toString().isNotEmpty) {
        final initialQuery = args['query'].toString().trim();
        textController.text = initialQuery;
        searchQuery.value = initialQuery;
      }
      if (args['category'] != null && args['category'].toString().isNotEmpty) {
        selectedCategorySlug.value = args['category'].toString();
        selectedCategoryName.value = args['categoryName']?.toString() ?? args['category'].toString();
      }
      if (searchQuery.value.isNotEmpty || selectedCategorySlug.value.isNotEmpty) {
        performSearch(saveToHistory: searchQuery.value.isNotEmpty);
      }
    } else if (args != null && args is String && args.isNotEmpty) {
      textController.text = args;
      searchQuery.value = args;
      performSearch(saveToHistory: true);
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    textController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      if (currentScroll >= maxScroll - 300 &&
          hasMore.value &&
          !isLoadingMore.value &&
          !isLoading.value) {
        loadMore();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Input & Live Search
  // ---------------------------------------------------------------------------

  void onQueryChanged(String value) {
    searchQuery.value = value;
    _debounceTimer?.cancel();

    if (value.trim().isEmpty && selectedCategorySlug.value.isEmpty) {
      products.clear();
      cursor.value = null;
      hasMore.value = false;
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      performSearch(saveToHistory: false);
    });
  }

  void onSubmit(String value) {
    _debounceTimer?.cancel();
    final clean = value.trim();
    if (clean.isEmpty && selectedCategorySlug.value.isEmpty) return;

    searchQuery.value = clean;
    focusNode.unfocus();
    performSearch(saveToHistory: clean.isNotEmpty);
  }

  void selectKeyword(String keyword) {
    textController.text = keyword;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    searchQuery.value = keyword;
    focusNode.unfocus();
    performSearch(saveToHistory: true);
  }

  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
    selectedCategorySlug.value = '';
    selectedCategoryName.value = '';
    minPriceFilter.value = null;
    maxPriceFilter.value = null;
    selectedSort.value = 'relevance';
    products.clear();
    cursor.value = null;
    hasMore.value = false;
    ranges.value = null;
  }

  // ---------------------------------------------------------------------------
  // Search API execution
  // ---------------------------------------------------------------------------

  Future<void> performSearch({bool saveToHistory = true}) async {
    final query = searchQuery.value.trim();
    if (query.isEmpty && selectedCategorySlug.value.isEmpty) {
      products.clear();
      cursor.value = null;
      hasMore.value = false;
      return;
    }

    if (saveToHistory && query.isNotEmpty) {
      _addRecentSearch(query);
    }

    isLoading.value = true;
    try {
      final endpoint = _buildSearchEndpoint();
      final response = await dioGet(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final result = SearchResponseModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        products.value = result.products;
        ranges.value = result.ranges;
        cursor.value = result.pagination.cursor;
        hasMore.value = result.pagination.hasMore;
      } else {
        products.clear();
        cursor.value = null;
        hasMore.value = false;
      }
    } catch (_) {
      products.clear();
      cursor.value = null;
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || cursor.value == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      final endpoint = _buildSearchEndpoint(cursorParam: cursor.value);
      final response = await dioGet(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final result = SearchResponseModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        products.addAll(result.products);
        cursor.value = result.pagination.cursor;
        hasMore.value = result.pagination.hasMore;
      } else {
        hasMore.value = false;
      }
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  String _buildSearchEndpoint({String? cursorParam}) {
    final params = <String>[];
    final q = searchQuery.value.trim();
    if (q.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(q)}');
    }

    if (selectedCategorySlug.value.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(selectedCategorySlug.value)}');
    }

    if (selectedSort.value != 'relevance') {
      params.add('sort=${selectedSort.value}');
    }

    if (minPriceFilter.value != null && minPriceFilter.value! > 0) {
      final minor = (minPriceFilter.value! * 100).toInt();
      params.add('minPrice=$minor');
    }

    if (maxPriceFilter.value != null && maxPriceFilter.value! > 0) {
      final minor = (maxPriceFilter.value! * 100).toInt();
      params.add('maxPrice=$minor');
    }

    if (cursorParam != null && cursorParam.isNotEmpty) {
      params.add('cursor=${Uri.encodeComponent(cursorParam)}');
    }

    params.add('limit=20');

    return 'catalog/search?${params.join('&')}';
  }

  // ---------------------------------------------------------------------------
  // Filters & Sorting Handlers
  // ---------------------------------------------------------------------------

  void setSort(String sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
    performSearch(saveToHistory: false);
  }

  void setCategory(String slug, String name) {
    if (selectedCategorySlug.value == slug) {
      // Toggle off if clicked again
      selectedCategorySlug.value = '';
      selectedCategoryName.value = '';
    } else {
      selectedCategorySlug.value = slug;
      selectedCategoryName.value = name;
    }
    performSearch(saveToHistory: false);
  }

  void applyPriceFilter(double? min, double? max) {
    minPriceFilter.value = min;
    maxPriceFilter.value = max;
    performSearch(saveToHistory: false);
  }

  void resetFilters() {
    selectedCategorySlug.value = '';
    selectedCategoryName.value = '';
    selectedSort.value = 'relevance';
    minPriceFilter.value = null;
    maxPriceFilter.value = null;
    performSearch(saveToHistory: false);
  }

  // ---------------------------------------------------------------------------
  // Recent Searches Management (GetStorage)
  // ---------------------------------------------------------------------------

  void _loadRecentSearches() {
    try {
      final stored = getBox.read(_recentSearchesKey);
      if (stored != null && stored is List) {
        recentSearches.value = stored.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  void _addRecentSearch(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return;

    final updated = List<String>.from(recentSearches);
    updated.removeWhere((e) => e.toLowerCase() == clean.toLowerCase());
    updated.insert(0, clean);
    if (updated.length > 15) {
      updated.removeLast();
    }
    recentSearches.value = updated;
    getBox.write(_recentSearchesKey, updated);
  }

  void removeRecentSearch(String term) {
    recentSearches.removeWhere((e) => e == term);
    getBox.write(_recentSearchesKey, recentSearches.toList());
  }

  void clearAllRecentSearches() {
    recentSearches.clear();
    getBox.remove(_recentSearchesKey);
  }

  // ---------------------------------------------------------------------------
  // Categories from catalog/categories
  // ---------------------------------------------------------------------------

  Future<void> _fetchCategories() async {
    isCategoriesLoading.value = true;
    try {
      final response = await dioGet('catalog/categories');
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          raw = raw['data'];
        }
        List? catList;
        if (raw is Map<String, dynamic> && raw.containsKey('categories')) {
          catList = raw['categories'] as List?;
        } else if (raw is List) {
          catList = raw;
        }

        if (catList != null) {
          final list = <Map<String, dynamic>>[];
          for (var c in catList) {
            if (c is Map) {
              final slug = c['slug']?.toString() ?? '';
              final name = c['name']?.toString() ?? '';
              if (slug.isNotEmpty && name.isNotEmpty && slug != 'all') {
                list.add({
                  'id': c['id']?.toString() ?? slug,
                  'name': name,
                  'slug': slug,
                  'imageUrl': c['imageUrl']?.toString(),
                });
              }
            }
          }
          categories.value = list;
        }
      }
    } catch (_) {} finally {
      isCategoriesLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Wishlist & Cart Actions
  // ---------------------------------------------------------------------------

  bool isVariantWishlisted(String? vId, [String? pId]) {
    if ((vId == null || vId.isEmpty) && (pId == null || pId.isEmpty)) return false;
    return wishlistedProductIds.contains(vId) ||
        (pId != null && wishlistedProductIds.contains(pId)) ||
        (Get.isRegistered<WishlistService>() &&
            WishlistService.to.isWishlisted(vId, pId));
  }

  Future<void> _syncWishlist() async {
    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) return;

    final visibleVariantIds = <String>[];
    for (final p in products) {
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
      final prod = products.firstWhereOrNull((p) => p.id == productId);
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
