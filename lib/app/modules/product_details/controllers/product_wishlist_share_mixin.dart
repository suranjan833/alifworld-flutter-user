import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routes/app_pages.dart';
import '../../my_wishlist/controllers/my_wishlist_controller.dart';
import '../models/product_details_model.dart';

mixin ProductWishlistShareMixin {
  Rx<ProductDetailsModel?> get product;
  RxList<ProductVariantModel> get variants;
  Rx<ProductSellerModel?> get seller;
  RxBool get isWishlisted;
  bool get isVisible;
  ProductVariantModel? get selectedVariant;
  int get activePriceMinor;
  int? get activeCompareAtPriceMinor;
  bool get isCampaignActive;
  int get activeProductPoints;

  void recordRecentlyViewed() {
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

  Future<void> checkWishlistStatus() async {
    if (!isVisible || !Get.isRegistered<WishlistService>()) return;
    final wishlistSvc = WishlistService.to;
    if (!wishlistSvc.hasAuth) {
      isWishlisted.value = false;
      return;
    }

    final p = product.value;
    if (p == null) return;

    final sv = selectedVariant;
    if (wishlistSvc.isWishlisted(sv?.id, p.id)) {
      isWishlisted.value = true;
    }

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
    final activeVId = sv?.id ??
        (targetVariantIds.isNotEmpty ? targetVariantIds.first : '');
    final serverWish = wishlistSvc.isWishlisted(activeVId, p.id);
    isWishlisted.value = serverWish;
    if (serverWish && p.id.isNotEmpty) {
      wishlistSvc.wishlistedProductIds.add(p.id);
    }
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
    final newStatus = await wishlistSvc.toggleWishlist(vId, productId: p?.id);
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
