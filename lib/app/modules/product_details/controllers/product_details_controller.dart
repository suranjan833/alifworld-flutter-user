import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../home/models/showcase_model.dart';
import '../../my_wishlist/controllers/my_wishlist_controller.dart';
import '../models/product_details_model.dart';

class ProductDetailsController extends GetxController with SkeletonLoadingMixin {
  final product = Rxn<ProductDetailsModel>();
  final variants = <ProductVariantModel>[].obs;
  final seller = Rxn<ProductSellerModel>();

  final selectedVariantIndex = 0.obs;
  final selectedImageIndex = 0.obs;
  final isWishlisted = false.obs;
  final selectedQuantity = 1.obs;
  final isLoadingDetails = false.obs;
  final isBuyingNow = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    _initializeData(args);
  }

  void _initializeData(dynamic args) {
    if (args == null) return;

    if (args is String) {
      fetchProductBySlug(args);
      return;
    }

    if (args is ProductDetailsModel) {
      _setProduct(args);
    } else if (args is ShowcaseProductModel) {
      _setProduct(ProductDetailsModel.fromShowcase(args));
    } else if (args is Map<String, dynamic>) {
      _setProduct(ProductDetailsModel.fromJson(args));
    } else {
      try {
        final map = (args as dynamic).toJson() as Map<String, dynamic>;
        _setProduct(ProductDetailsModel.fromJson(map));
      } catch (_) {
        return;
      }
    }

    final currentSlug = product.value?.slug;
    if (currentSlug != null && currentSlug.isNotEmpty) {
      fetchProductBySlug(currentSlug);
    }
  }

  void _setProduct(ProductDetailsModel model) {
    final prev = product.value;
    final finalImages = model.images.isNotEmpty
        ? model.images
        : (prev != null && prev.images.isNotEmpty ? prev.images : <String>[]);
    final finalVariants = model.variants.isNotEmpty
        ? model.variants
        : (prev != null && prev.variants.isNotEmpty
            ? prev.variants
            : <ProductVariantModel>[]);

    final merged = model.copyWith(
      images: finalImages,
      variants: finalVariants,
      priceMinor: model.priceMinor ?? prev?.priceMinor,
      compareAtPriceMinor:
          model.compareAtPriceMinor ?? prev?.compareAtPriceMinor,
      brandName: (model.brandName != null && model.brandName!.isNotEmpty)
          ? model.brandName
          : prev?.brandName,
      categoryName:
          (model.categoryName != null && model.categoryName!.isNotEmpty)
              ? model.categoryName
              : prev?.categoryName,
      minPurchaseQty: model.minPurchaseQty ?? prev?.minPurchaseQty,
      maxPurchaseQty: model.maxPurchaseQty ?? prev?.maxPurchaseQty,
      isVisible: model.isVisible,
    );

    product.value = merged;
    variants.assignAll(merged.variants);
    seller.value = merged.seller;
    isWishlisted.value = merged.isFavorite;

    if (selectedVariantIndex.value >= merged.variants.length) {
      selectedVariantIndex.value = 0;
    }
    selectedQuantity.value = merged.effectiveMinQty;

    _recordRecentlyViewed();
    checkWishlistStatus();
  }

  Future<void> fetchProductBySlug(String slug) async {
    try {
      isLoadingDetails.value = true;
      // 1. Try GET /catalog/products/{slug}
      final response = await dioGet('catalog/products/$slug');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData.containsKey('product')) {
          rawData = rawData['product'];
        }
        if (rawData is Map) {
          _setProduct(
            ProductDetailsModel.fromJson(Map<String, dynamic>.from(rawData)),
          );
          return;
        }
      }

      // 2. Fallback to GET /catalog/search if slug route is unreachable
      final searchResponse = await dioGet('catalog/search');
      if (searchResponse.statusCode == 200 && searchResponse.data != null) {
        dynamic rawData = searchResponse.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? prods;
        if (rawData is Map && rawData.containsKey('products')) {
          prods = rawData['products'] as List?;
        }
        if (prods != null) {
          final found = prods.firstWhereOrNull(
            (p) => p is Map && (p['slug'] == slug || p['id'] == slug),
          );
          if (found != null && found is Map) {
            _setProduct(
              ProductDetailsModel.fromJson(Map<String, dynamic>.from(found)),
            );
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingDetails.value = false;
    }
  }

  bool get isVisible => product.value?.isVisible ?? true;

  ProductVariantModel? get selectedVariant {
    if (variants.isNotEmpty && selectedVariantIndex.value < variants.length) {
      return variants[selectedVariantIndex.value];
    }
    return null;
  }

  List<String> get imagesList {
    final sv = selectedVariant;
    if (sv != null && sv.images.isNotEmpty) {
      return sv.images;
    }
    final p = product.value;
    if (p != null && p.images.isNotEmpty) {
      return p.images;
    }
    if (p != null && p.displayImage.isNotEmpty) {
      return [p.displayImage];
    }
    return const [];
  }

  double get activePriceValue {
    final sv = selectedVariant;
    if (sv != null && sv.price > 0) {
      return sv.price;
    }
    return product.value?.price ?? 0.0;
  }

  String get activePriceFormatted {
    final sv = selectedVariant;
    if (sv != null && sv.price > 0) {
      return sv.priceFormatted;
    }
    return product.value?.priceFormatted ?? '৳0.00';
  }

  String? get activeOriginalPriceFormatted {
    final sv = selectedVariant;
    if (sv != null && sv.originalPriceFormatted != null) {
      return sv.originalPriceFormatted;
    }
    return product.value?.originalPriceFormatted;
  }

  String get activeDiscount {
    final sv = selectedVariant;
    if (sv != null && sv.discount.isNotEmpty) {
      return sv.discount;
    }
    return product.value?.discount ?? '';
  }

  int? get activeStock {
    final sv = selectedVariant;
    if (sv != null && sv.stockQty != null) {
      return sv.stockQty;
    }
    return product.value?.stockQty;
  }

  String? get activeSku => selectedVariant?.sku;

  bool get isOpenBoxDelivery => product.value?.openBoxDelivery ?? false;

  int get activeProductPoints {
    final sv = selectedVariant;
    if (sv != null && sv.productPoints != null) {
      return sv.productPoints!;
    }
    return product.value?.productPoints ?? 0;
  }

  int get activePriceMinor {
    final sv = selectedVariant;
    if (sv != null) {
      return sv.effectivePriceMinor;
    }
    return product.value?.priceMinor ?? 0;
  }

  int? get activeCompareAtPriceMinor {
    final sv = selectedVariant;
    if (sv != null && sv.compareAtPriceMinor != null) {
      return sv.compareAtPriceMinor;
    }
    return product.value?.compareAtPriceMinor;
  }

  bool get isCampaignActive => selectedVariant?.isCampaignActive ?? false;

  bool get hasMrpSaving {
    if (isCampaignActive) return false;
    final comp = activeCompareAtPriceMinor;
    final price = activePriceMinor;
    return comp != null && comp > price && price > 0;
  }

  double get mrpSavingAmount {
    final comp = activeCompareAtPriceMinor ?? 0;
    final price = activePriceMinor;
    if (comp > price) {
      return (comp - price) / 100.0;
    }
    return 0.0;
  }

  int get mrpSavingPct {
    final comp = activeCompareAtPriceMinor ?? 0;
    final price = activePriceMinor;
    if (comp > price && comp > 0) {
      return (((comp - price) / comp) * 100).round();
    }
    return 0;
  }

  String get displayTitleWithVariant =>
      product.value?.titleWithVariant(selectedVariant) ?? '';

  int get minPurchaseQty => product.value?.effectiveMinQty ?? 1;
  int? get maxPurchaseQty => product.value?.maxPurchaseQty;
  int get effectiveCap {
    final s = activeStock;
    final m = maxPurchaseQty;
    if (s != null && m != null) return s < m ? s : m;
    return m ?? s ?? 999999;
  }

  void selectVariant(int index) {
    if (index >= 0 && index < variants.length) {
      selectedVariantIndex.value = index;
      selectedQuantity.value = minPurchaseQty;
      selectedImageIndex.value = 0;
      _recordRecentlyViewed();
      if (isVisible && Get.isRegistered<WishlistService>()) {
        isWishlisted.value =
            WishlistService.to.isWishlisted(selectedVariant?.id);
      }
    }
  }

  void _recordRecentlyViewed() {
    final p = product.value;
    if (p == null || p.slug.isEmpty) return;
    final sv = selectedVariant;
    if (Get.isRegistered<RecentlyViewedService>()) {
      RecentlyViewedService.to.recordView(
        slug: p.slug,
        productId: p.id,
        name: p.name,
        brandName: p.brandName,
        variantId: sv?.id,
        variantLabel: sv?.label,
        imageUrl: (sv != null && sv.images.isNotEmpty)
            ? sv.images.first
            : (p.images.isNotEmpty ? p.images.first : p.displayImage),
        priceMinor: activePriceMinor,
        compareAtPriceMinor: activeCompareAtPriceMinor,
        campaignActive: isCampaignActive,
        productPoints: activeProductPoints,
        sellerName: seller.value?.shopName,
      );
    }
  }

  void incrementQuantity() {
    final cap = effectiveCap;
    if (selectedQuantity.value < cap) {
      selectedQuantity.value++;
    } else {
      final msg = maxPurchaseQty != null && selectedQuantity.value >= maxPurchaseQty!
          ? 'Maximum purchase for this item is $maxPurchaseQty'
          : 'Only $cap units available';
      Get.snackbar(
        'Limit Reached',
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.black87,
        colorText: AppColor.white,
      );
    }
  }

  void decrementQuantity() {
    final minQty = minPurchaseQty;
    if (selectedQuantity.value > minQty) {
      selectedQuantity.value--;
    } else if (minQty > 1) {
      Get.snackbar(
        'Minimum Purchase',
        'Minimum purchase for this item is $minQty',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.black87,
        colorText: AppColor.white,
      );
    }
  }

  Future<void> checkWishlistStatus() async {
    if (!isVisible) {
      isWishlisted.value = false;
      return;
    }
    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) {
      isWishlisted.value = false;
      return;
    }

    final p = product.value;
    if (p == null) return;

    final targetVariantIds = <String>[];
    for (var v in variants) {
      if (v.id.isNotEmpty) targetVariantIds.add(v.id);
    }
    if (targetVariantIds.isEmpty && p.variants.isNotEmpty) {
      for (var v in p.variants) {
        if (v.id.isNotEmpty) targetVariantIds.add(v.id);
      }
    }

    if (targetVariantIds.isEmpty) return;

    await wishlistSvc.checkStatus(targetVariantIds);
    final sv = selectedVariant;
    final activeVId = sv?.id ??
        (targetVariantIds.isNotEmpty ? targetVariantIds.first : '');
    isWishlisted.value = wishlistSvc.isWishlisted(activeVId);
  }

  Future<void> toggleWishlist() async {
    final p = product.value;
    if (!isVisible) {
      Get.snackbar(
        'Not Available',
        'This product is not available right now.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    final sv = selectedVariant;
    final vId = sv?.id ??
        (p?.variants.isNotEmpty == true ? p!.variants.first.id : '');

    if (vId.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not find product variant',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    if (!Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final wasWishlisted = isWishlisted.value;
    final newStatus = await wishlistSvc.toggleWishlist(vId);
    isWishlisted.value = newStatus;

    if (newStatus != wasWishlisted) {
      Get.snackbar(
        newStatus ? 'Added to Wishlist' : 'Removed from Wishlist',
        newStatus
            ? '${p?.name ?? 'Item'} saved to your wishlist'
            : 'Item removed from wishlist',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.textPrimary,
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
    }

    if (Get.isRegistered<MyWishlistController>()) {
      Get.find<MyWishlistController>().fetchWishlist();
    }
  }

  /// GET /catalog/products/{slug}/share?variant={variantId}
  Future<void> shareProduct() async {
    final p = product.value;
    if (p == null || p.slug.isEmpty) return;

    try {
      final sv = selectedVariant;
      final vId =
          sv?.id ?? (p.variants.isNotEmpty ? p.variants.first.id : null);
      final query =
          (vId != null && vId.isNotEmpty) ? '?variant=$vId' : '';
      final response =
          await dioGet('catalog/products/${p.slug}/share$query');

      String shareText = '';
      String shareUrl = '';

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data')) {
          data = data['data'];
        }
        if (data is Map) {
          shareText = data['text']?.toString() ?? '';
          shareUrl = data['url']?.toString() ?? '';
        }
      }

      if (shareText.isEmpty) {
        final fallbackUrl = shareUrl.isNotEmpty
            ? shareUrl
            : 'https://dev.alifworld.com.bd/product/${p.slug}${vId != null ? '?variant=$vId' : ''}';
        shareText =
            'Check out ${p.name} on Alifworld!\n\nShop now: $fallbackUrl';
      }

      try {
        final result = await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: p.name,
          ),
        );
        if (result.status == ShareResultStatus.unavailable) {
          final copyText = shareUrl.isNotEmpty ? shareUrl : shareText;
          await Clipboard.setData(ClipboardData(text: copyText));
          Get.snackbar(
            'Link Copied',
            'Product link copied to clipboard',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.textPrimary,
            colorText: AppColor.white,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (_) {
        final copyText = shareUrl.isNotEmpty ? shareUrl : shareText;
        await Clipboard.setData(ClipboardData(text: copyText));
        Get.snackbar(
          'Link Copied',
          'Product link copied to clipboard',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.textPrimary,
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      Get.snackbar(
        'Share Failed',
        'Could not generate share link',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
    }
  }

  Future<void> addToBag() async {
    if (!isVisible || variants.isEmpty) {
      Get.snackbar(
        'Not Available',
        'This product is not available right now.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final bool hasAuth = (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);

    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final p = product.value;
    if (p == null) return;

    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController());
    }
    final bagCtrl = Get.find<BagController>();

    final sv = selectedVariant;
    final fallbackVariantId =
        sv?.id ?? (p.variants.isNotEmpty ? p.variants.first.id : null);
    final itemPayload = <String, dynamic>{
      'id': p.id,
      'productId': p.id,
      'variantId': fallbackVariantId,
      'variantLabel': sv?.label ?? (p.variants.isNotEmpty ? p.variants.first.label : null),
      'brand': p.displayBrand,
      'title': p.name,
      'price': activePriceValue,
      'image': imagesList.first,
      'slug': p.slug,
      'variants': p.variants.map((v) => v.toJson()).toList(),
      if (p.minPurchaseQty != null) 'minPurchaseQty': p.minPurchaseQty,
      if (p.maxPurchaseQty != null) 'maxPurchaseQty': p.maxPurchaseQty,
    };

    final effectiveQty = selectedQuantity.value < minPurchaseQty
        ? minPurchaseQty
        : selectedQuantity.value;
    await bagCtrl.addItemToBag(itemPayload, quantity: effectiveQty);
    await bagCtrl.fetchCart(showLoading: false, force: true);
    bagCtrl.cartItems.refresh();
  }

  Future<void> buyNow() async {
    if (isBuyingNow.value) return;

    if (!isVisible || variants.isEmpty) {
      Get.snackbar(
        'Not Available',
        'This product is not available right now.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final bool hasAuth = (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);

    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final p = product.value;
    if (p == null) return;

    if (!Get.isRegistered<BagController>()) {
      Get.put(BagController());
    }
    final bagCtrl = Get.find<BagController>();

    final sv = selectedVariant;
    final fallbackVariantId =
        sv?.id ?? (p.variants.isNotEmpty ? p.variants.first.id : null);
    final itemPayload = <String, dynamic>{
      'id': p.id,
      'productId': p.id,
      'variantId': fallbackVariantId,
      'variantLabel': sv?.label ?? (p.variants.isNotEmpty ? p.variants.first.label : null),
      'brand': p.displayBrand,
      'title': p.name,
      'price': activePriceValue,
      'image': imagesList.first,
      'slug': p.slug,
      'variants': p.variants.map((v) => v.toJson()).toList(),
      if (p.minPurchaseQty != null) 'minPurchaseQty': p.minPurchaseQty,
      if (p.maxPurchaseQty != null) 'maxPurchaseQty': p.maxPurchaseQty,
    };

    final effectiveQty = selectedQuantity.value < minPurchaseQty
        ? minPurchaseQty
        : selectedQuantity.value;

    isBuyingNow.value = true;
    try {
      final success = await bagCtrl.addItemToBag(
        itemPayload,
        quantity: effectiveQty,
      );
      if (success) {
        await bagCtrl.fetchCart(showLoading: false, force: true);
        bagCtrl.cartItems.refresh();
        Get.toNamed(Routes.BAG);
      }
    } finally {
      isBuyingNow.value = false;
    }
  }

  void openSellerDetails() {
    final s = seller.value;
    if (s != null) {
      final map = s.toJson();
      if (s.slug.isNotEmpty) {
        map['slug'] = s.slug;
      }
      Get.toNamed(Routes.SELLER_DETAILS, arguments: map);
    } else {
      Get.toNamed(Routes.SELLER_DETAILS);
    }
  }
}

