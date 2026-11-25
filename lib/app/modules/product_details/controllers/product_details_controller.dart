import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../home/models/showcase_model.dart';
import '../models/product_details_model.dart';
import 'product_wishlist_share_mixin.dart';

class ProductDetailsController extends GetxController
    with SkeletonLoadingMixin, ProductWishlistShareMixin {
  @override
  final product = Rxn<ProductDetailsModel>();
  @override
  final variants = <ProductVariantModel>[].obs;
  @override
  final seller = Rxn<ProductSellerModel>();

  final selectedVariantIndex = 0.obs;
  final selectedImageIndex = 0.obs;
  @override
  final isWishlisted = false.obs;
  final selectedQuantity = 0.obs;
  final isDetailsLoaded = false.obs;
  final isLoadingDetails = false.obs;
  final isBuyingNow = false.obs;
  String? _targetVariantId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    _initializeData(args);
  }

  void _initializeData(dynamic args) {
    String? targetSlug;
    if (args == null) {
      targetSlug = Get.parameters['slug'];
      _targetVariantId = Get.parameters['variant'];
    } else if (args is String) {
      targetSlug = args;
    } else if (args is ProductDetailsModel) {
      targetSlug = args.slug;
      final hasVariantMin = args.variants.isNotEmpty &&
          args.variants.first.minPurchaseQty != null;
      _setProduct(args, isFullDetails: hasVariantMin);
    } else if (args is ShowcaseProductModel) {
      targetSlug = args.slug;
      _setProduct(ProductDetailsModel.fromShowcase(args), isFullDetails: false);
    } else if (args is Map) {
      targetSlug = args['slug']?.toString();
      _targetVariantId = args['variantId']?.toString() ?? args['variant']?.toString();
      try {
        _setProduct(ProductDetailsModel.fromJson(Map<String, dynamic>.from(args)), isFullDetails: false);
      } catch (_) {}
    } else {
      try {
        final map = (args as dynamic).toJson() as Map<String, dynamic>;
        targetSlug = map['slug']?.toString();
        _targetVariantId = map['variantId']?.toString();
        _setProduct(ProductDetailsModel.fromJson(map), isFullDetails: false);
      } catch (_) {
        return;
      }
    }

    if (targetSlug != null && targetSlug.isNotEmpty) {
      final cachedRaw = getBox.read('pdp_cache_$targetSlug');
      if (cachedRaw is Map) {
        try {
          final cachedModel = ProductDetailsModel.fromJson(
            Map<String, dynamic>.from(cachedRaw),
          );
          _setProduct(cachedModel, isFullDetails: true);
        } catch (_) {}
      }
      fetchProductBySlug(targetSlug);
    }
  }

  void _setProduct(ProductDetailsModel model, {bool isFullDetails = false}) {
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

    final tVarId = _targetVariantId;
    if (tVarId != null && tVarId.isNotEmpty) {
      final idx = merged.variants.indexWhere((v) => v.id == tVarId);
      if (idx >= 0) {
        selectedVariantIndex.value = idx;
      }
    } else if (selectedVariantIndex.value >= merged.variants.length) {
      selectedVariantIndex.value = 0;
    }

    final hasVariantMin = merged.variants.any((v) => v.minPurchaseQty != null);
    if (isFullDetails || hasVariantMin) {
      isDetailsLoaded.value = true;
      selectedQuantity.value = minPurchaseQty;
    } else {
      isDetailsLoaded.value = false;
      selectedQuantity.value = 0;
    }

    recordRecentlyViewed();
    checkWishlistStatus();
  }

  Future<void> fetchProductBySlug(String slug) async {
    try {
      if (!isDetailsLoaded.value) {
        isLoadingDetails.value = true;
      }
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
          final cleanMap = Map<String, dynamic>.from(rawData);
          getBox.write('pdp_cache_$slug', cleanMap);
          _setProduct(
            ProductDetailsModel.fromJson(cleanMap),
            isFullDetails: true,
          );
        }
      }
    } catch (e) {
      // Keep existing product if fetch fails
    } finally {
      isLoadingDetails.value = false;
    }
  }

  @override
  ProductVariantModel? get selectedVariant {
    if (variants.isEmpty) return null;
    if (selectedVariantIndex.value >= variants.length) {
      return variants.first;
    }
    return variants[selectedVariantIndex.value];
  }

  @override
  bool get isVisible => product.value?.isVisible ?? true;

  bool get isOpenBoxDelivery => product.value?.openBoxDelivery ?? false;

  String? get activeSku => selectedVariant?.sku ?? product.value?.slug;

  int? get activeStock {
    final sv = selectedVariant;
    if (sv != null && sv.stockQty != null) return sv.stockQty;
    return product.value?.stockQty;
  }

  bool get activeInStock {
    final s = activeStock;
    if (s != null) return s > 0;
    return product.value?.inStock ?? true;
  }

  @override
  int get activePriceMinor =>
      selectedVariant?.effectivePriceMinor ?? product.value?.priceMinor ?? 0;

  @override
  int? get activeCompareAtPriceMinor =>
      selectedVariant?.compareAtPriceMinor ??
      product.value?.compareAtPriceMinor;

  @override
  int get activeProductPoints =>
      selectedVariant?.productPoints ?? product.value?.productPoints ?? 0;

  @override
  bool get isCampaignActive => selectedVariant?.isCampaignActive ?? false;
  String? get campaignName => selectedVariant?.campaignName;

  double get activePriceValue {
    final minor = activePriceMinor;
    if (minor > 0) return minor / 100.0;
    return product.value?.price ?? 0.0;
  }

  double? get activeOriginalPriceValue {
    final minor = activeCompareAtPriceMinor;
    if (minor != null && minor > 0) return minor / 100.0;
    return product.value?.originalPrice;
  }

  bool get hasMrpSaving =>
      activeOriginalPriceValue != null &&
      activeOriginalPriceValue! > activePriceValue;

  double get mrpSavingAmount => hasMrpSaving
      ? (activeOriginalPriceValue! - activePriceValue)
      : 0.0;

  int get mrpSavingPct => hasMrpSaving && activeOriginalPriceValue! > 0
      ? ((mrpSavingAmount / activeOriginalPriceValue!) * 100).round()
      : 0;

  String get activePriceFormatted {
    final price = activePriceValue;
    return '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }

  String? get activeOriginalPriceFormatted {
    final orig = activeOriginalPriceValue;
    if (orig != null && orig > activePriceValue) {
      return '৳${orig.toStringAsFixed(orig.truncateToDouble() == orig ? 0 : 2)}';
    }
    return null;
  }

  String get activeDiscount {
    final orig = activeOriginalPriceValue;
    final price = activePriceValue;
    if (orig != null && orig > price && price > 0) {
      final pct = (((orig - price) / orig) * 100).round();
      if (pct > 0) return '$pct% OFF';
    }
    return '';
  }

  List<String> get imagesList {
    final sv = selectedVariant;
    if (sv != null && sv.images.isNotEmpty) return sv.images;
    final pImages = product.value?.images;
    if (pImages != null && pImages.isNotEmpty) return pImages;
    return [''];
  }

  int get savingsPercentage {
    final comp = activeOriginalPriceValue ?? 0;
    final price = activePriceValue;
    if (comp > price && comp > 0) {
      return (((comp - price) / comp) * 100).round();
    }
    return 0;
  }

  String get displayTitleWithVariant =>
      product.value?.titleWithVariant(selectedVariant) ?? '';

  int get minPurchaseQty {
    final svMin = selectedVariant?.minPurchaseQty;
    if (svMin != null && svMin > 0) return svMin;
    return product.value?.effectiveMinQty ?? 1;
  }

  int? get maxPurchaseQty =>
      selectedVariant?.maxPurchaseQty ?? product.value?.effectiveMaxQty;

  int get effectiveCap {
    final s = activeStock;
    final m = maxPurchaseQty;
    if (s != null && m != null) return s < m ? s : m;
    return m ?? s ?? 999999;
  }

  void selectVariant(int index) {
    if (index >= 0 && index < variants.length) {
      selectedVariantIndex.value = index;
      final minQty = minPurchaseQty;
      final cap = effectiveCap;
      if (selectedQuantity.value < minQty) {
        selectedQuantity.value = minQty;
      } else if (selectedQuantity.value > cap) {
        selectedQuantity.value = cap;
      }
      selectedImageIndex.value = 0;
      recordRecentlyViewed();
      if (isVisible && Get.isRegistered<WishlistService>()) {
        isWishlisted.value = WishlistService.to
            .isWishlisted(selectedVariant?.id, product.value?.id);
      }
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

  void setQuantity(int newQty) {
    final minQty = minPurchaseQty;
    final cap = effectiveCap;

    if (newQty < minQty) {
      selectedQuantity.value = minQty;
      if (minQty > 1) {
        Get.snackbar(
          'Minimum Purchase',
          'Minimum purchase for this item is $minQty',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.black87,
          colorText: AppColor.white,
        );
      }
      return;
    }

    if (newQty > cap) {
      selectedQuantity.value = cap;
      final msg = maxPurchaseQty != null && newQty > maxPurchaseQty!
          ? 'Maximum purchase for this item is $maxPurchaseQty'
          : 'Only $cap units available';
      Get.snackbar(
        'Limit Reached',
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.black87,
        colorText: AppColor.white,
      );
      return;
    }

    selectedQuantity.value = newQty;
  }

  Map<String, dynamic> _buildCartPayload(
    ProductDetailsModel p,
    String? fallbackVariantId,
  ) {
    final sv = selectedVariant;
    return <String, dynamic>{
      'id': p.id,
      'productId': p.id,
      'variantId': fallbackVariantId,
      'variantLabel':
          sv?.label ?? (p.variants.isNotEmpty ? p.variants.first.label : null),
      'brand': p.displayBrand,
      'title': p.name,
      'price': activePriceValue,
      'image': imagesList.first,
      'slug': p.slug,
      'variants': p.variants.map((v) => v.toJson()).toList(),
      if (minPurchaseQty > 1) 'minPurchaseQty': minPurchaseQty,
      if (maxPurchaseQty != null) 'maxPurchaseQty': maxPurchaseQty,
    };
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

    final p = product.value;
    if (p == null) return;

    final bagCtrl = BagController.to;
    final sv = selectedVariant;
    final fallbackVariantId =
        sv?.id ?? (p.variants.isNotEmpty ? p.variants.first.id : null);
    final itemPayload = _buildCartPayload(p, fallbackVariantId);

    final effectiveQty = selectedQuantity.value < minPurchaseQty
        ? minPurchaseQty
        : selectedQuantity.value;
    await bagCtrl.addItemToBag(itemPayload, quantity: effectiveQty);
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

    final p = product.value;
    if (p == null) return;

    final bagCtrl = BagController.to;
    final sv = selectedVariant;
    final fallbackVariantId =
        sv?.id ?? (p.variants.isNotEmpty ? p.variants.first.id : null);
    final itemPayload = _buildCartPayload(p, fallbackVariantId);

    final effectiveQty = selectedQuantity.value < minPurchaseQty
        ? minPurchaseQty
        : selectedQuantity.value;

    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final bool hasAuth = (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);

    bagCtrl.addOptimisticItem(
      itemPayload,
      quantity: effectiveQty,
      resolvedVariantId: fallbackVariantId,
    );

    Get.toNamed(Routes.BAG);

    if (hasAuth && fallbackVariantId != null && fallbackVariantId.isNotEmpty) {
      bagCtrl.syncItemToServerBackground(fallbackVariantId, effectiveQty);
    }
  }
}
