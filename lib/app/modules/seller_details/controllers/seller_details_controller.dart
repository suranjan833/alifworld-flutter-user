import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../routes/app_pages.dart';

class ShopProductItem {
  final String id;
  final String name;
  final String slug;
  final int priceMinor;
  final int productPoints;
  final int stockQty;
  final String imageUrl;
  final int? campaignSaleMinor;
  final int? campaignDiscountMinor;
  final String? campaignName;

  ShopProductItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceMinor,
    required this.productPoints,
    required this.stockQty,
    required this.imageUrl,
    this.campaignSaleMinor,
    this.campaignDiscountMinor,
    this.campaignName,
  });

  double get price {
    if (campaignSaleMinor != null && campaignSaleMinor! > 0) {
      return campaignSaleMinor! / 100.0;
    }
    return priceMinor / 100.0;
  }

  double? get originalPrice {
    if (campaignSaleMinor != null && campaignSaleMinor! > 0 && priceMinor > campaignSaleMinor!) {
      return priceMinor / 100.0;
    }
    return null;
  }

  String get formattedPrice =>
      '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';

  String? get formattedOriginalPrice {
    final orig = originalPrice;
    if (orig != null && orig > price) {
      return '৳${orig.toStringAsFixed(orig.truncateToDouble() == orig ? 0 : 2)}';
    }
    return null;
  }

  String get discount {
    final orig = originalPrice;
    if (orig != null && orig > price && price > 0) {
      final pct = (((orig - price) / orig) * 100).round();
      if (pct > 0) return '$pct% OFF';
    }
    return '';
  }

  factory ShopProductItem.fromJson(Map<String, dynamic> json) {
    String img = json['imageUrl']?.toString() ??
        json['image']?.toString() ??
        json['thumbnail']?.toString() ??
        '';
    if (img.isNotEmpty) img = resolveImageUrl(img);

    return ShopProductItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Product',
      slug: json['slug']?.toString() ?? '',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      productPoints: (json['productPoints'] as num?)?.toInt() ?? 0,
      stockQty: (json['stockQty'] as num?)?.toInt() ?? 0,
      imageUrl: img,
      campaignSaleMinor: (json['campaignSaleMinor'] as num?)?.toInt(),
      campaignDiscountMinor: (json['campaignDiscountMinor'] as num?)?.toInt(),
      campaignName: json['campaignName']?.toString(),
    );
  }

  Map<String, dynamic> toDetailsMap() => {
        'id': id,
        'productId': id,
        'name': name,
        'title': name,
        'slug': slug,
        'price': formattedPrice,
        'originalPrice': formattedOriginalPrice,
        'discount': discount,
        'image': imageUrl,
        'productPoints': productPoints,
        'stockQty': stockQty,
      };
}

class ShopInfoModel {
  final String id;
  final String shopName;
  final String slug;
  final String logoUrl;
  final String bannerUrl;
  final String description;

  ShopInfoModel({
    required this.id,
    required this.shopName,
    required this.slug,
    required this.logoUrl,
    required this.bannerUrl,
    required this.description,
  });

  String get fullLogoUrl => logoUrl.isNotEmpty ? resolveImageUrl(logoUrl) : '';
  String get fullBannerUrl =>
      bannerUrl.isNotEmpty ? resolveImageUrl(bannerUrl) : '';

  factory ShopInfoModel.fromJson(Map<String, dynamic> json) {
    return ShopInfoModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? 'Store',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? json['logo']?.toString() ?? '',
      bannerUrl:
          json['bannerUrl']?.toString() ?? json['banner']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class SellerDetailsController extends GetxController {
  final shopSlug = ''.obs;
  final shop = Rxn<ShopInfoModel>();
  final products = <ShopProductItem>[].obs;
  final nextCursor = RxnString();

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isNotFound = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String) {
      shopSlug.value = args;
    } else if (args is Map) {
      final s = args['slug']?.toString() ?? '';
      shopSlug.value = s;
      if (args['shopName'] != null || args['name'] != null) {
        shop.value = ShopInfoModel.fromJson(Map<String, dynamic>.from(args));
      }
    }
    if (shopSlug.value.isNotEmpty) {
      fetchShop(refresh: true);
    }
  }

  /// GET /api/v1/catalog/shops/[slug]?limit=20
  Future<void> fetchShop({bool refresh = true}) async {
    final slug = shopSlug.value;
    if (slug.isEmpty) return;

    if (refresh) {
      isLoading.value = true;
      isNotFound.value = false;
      nextCursor.value = null;
    } else {
      if (nextCursor.value == null || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      String query = 'limit=20';
      if (!refresh && nextCursor.value != null) {
        query += '&cursor=${nextCursor.value}';
      }

      final res = await dioGet('catalog/shops/$slug?$query');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }

        if (raw is Map<String, dynamic>) {
          if (raw['shop'] is Map<String, dynamic>) {
            shop.value = ShopInfoModel.fromJson(
              Map<String, dynamic>.from(raw['shop']),
            );
          }

          final prods = (raw['products'] as List<dynamic>?)
                  ?.map((e) =>
                      ShopProductItem.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];

          if (refresh) {
            products.assignAll(prods);
          } else {
            products.addAll(prods);
          }

          nextCursor.value = raw['nextCursor']?.toString();
        }
      } else if (res.statusCode == 404) {
        isNotFound.value = true;
      }
    } catch (e) {
      debugPrint('Error fetching shop $slug: $e');
      if (refresh && shop.value == null) {
        isNotFound.value = true;
      }
    } finally {
      if (refresh) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  void loadMore() {
    fetchShop(refresh: false);
  }

  void openProductDetails(ShopProductItem product) {
    Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product.toDetailsMap());
  }
}

