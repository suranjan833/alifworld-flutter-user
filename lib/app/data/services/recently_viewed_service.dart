import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../config/functions/dio_function/app_config.dart';

class RecentlyViewedItem {
  final String slug;
  final String productId;
  final String name;
  final String? brandName;
  final String? variantId;
  final String? variantLabel;
  final String imageUrl;
  final int priceMinor;
  final int? compareAtPriceMinor;
  final bool campaignActive;
  final int productPoints;
  final String? sellerName;

  RecentlyViewedItem({
    required this.slug,
    required this.productId,
    required this.name,
    this.brandName,
    this.variantId,
    this.variantLabel,
    required this.imageUrl,
    required this.priceMinor,
    this.compareAtPriceMinor,
    this.campaignActive = false,
    this.productPoints = 0,
    this.sellerName,
  });

  double get price => priceMinor / 100.0;
  double? get originalPrice =>
      compareAtPriceMinor != null ? compareAtPriceMinor! / 100.0 : null;

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
    if (compareAtPriceMinor != null &&
        compareAtPriceMinor! > priceMinor &&
        priceMinor > 0) {
      final pct =
          (((compareAtPriceMinor! - priceMinor) / compareAtPriceMinor!) * 100)
              .round();
      if (pct > 0) return '$pct% OFF';
    }
    return '';
  }

  String get displayTitle {
    if (variantLabel != null &&
        variantLabel!.trim().isNotEmpty &&
        variantLabel!.toLowerCase() != name.toLowerCase() &&
        variantLabel!.toLowerCase() != 'default') {
      return '$name ($variantLabel)';
    }
    return name;
  }

  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedItem(
      slug: json['slug']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      brandName: json['brandName']?.toString(),
      variantId: json['variantId']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      compareAtPriceMinor: (json['compareAtPriceMinor'] as num?)?.toInt(),
      campaignActive: json['campaignActive'] == true,
      productPoints: (json['productPoints'] as num?)?.toInt() ?? 0,
      sellerName: json['sellerName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'productId': productId,
        'name': name,
        'brandName': brandName,
        'variantId': variantId,
        'variantLabel': variantLabel,
        'imageUrl': imageUrl,
        'priceMinor': priceMinor,
        'compareAtPriceMinor': compareAtPriceMinor,
        'campaignActive': campaignActive,
        'productPoints': productPoints,
        'sellerName': sellerName,
      };

  Map<String, dynamic> toDetailsMap() => {
        'id': productId,
        'productId': productId,
        'slug': slug,
        'title': displayTitle,
        'name': name,
        'image': imageUrl,
        'price': formattedPrice,
        'originalPrice': formattedOriginalPrice,
        'discount': discount,
        'productPoints': productPoints,
        'variantId': variantId,
        'variantLabel': variantLabel,
        'seller': sellerName != null ? {'shopName': sellerName} : null,
      };
}

class RecentlyViewedService extends GetxService {
  static RecentlyViewedService get to => Get.find<RecentlyViewedService>();

  static const String _storageKey = 'recently_viewed_products';
  static const int _maxItems = 12;

  final items = <RecentlyViewedItem>[].obs;
  late final GetStorage _box;

  @override
  void onInit() {
    super.onInit();
    _box = GetStorage();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      final raw = _box.read<List>(_storageKey);
      if (raw != null) {
        final list = raw
            .whereType<Map>()
            .map((e) => RecentlyViewedItem.fromJson(Map<String, dynamic>.from(e)))
            .where((i) => i.slug.isNotEmpty)
            .toList();
        items.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error loading recently viewed: $e');
    }
  }

  void _saveToStorage() {
    try {
      final list = items.map((e) => e.toJson()).toList();
      _box.write(_storageKey, list);
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
    }
  }

  /// Records a viewed product. Newest first, max 12 items, one entry per slug.
  void recordView({
    required String slug,
    required String productId,
    required String name,
    String? brandName,
    String? variantId,
    String? variantLabel,
    required String imageUrl,
    required int priceMinor,
    int? compareAtPriceMinor,
    bool campaignActive = false,
    int productPoints = 0,
    String? sellerName,
  }) {
    if (slug.isEmpty) return;

    final entry = RecentlyViewedItem(
      slug: slug,
      productId: productId,
      name: name,
      brandName: brandName,
      variantId: variantId,
      variantLabel: variantLabel,
      imageUrl: resolveImageUrl(imageUrl),
      priceMinor: priceMinor,
      compareAtPriceMinor: compareAtPriceMinor,
      campaignActive: campaignActive,
      productPoints: productPoints,
      sellerName: sellerName,
    );

    // Remove existing entry for the same slug so it moves to front
    items.removeWhere((i) => i.slug == slug);
    items.insert(0, entry);

    // Cap at max items
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    _saveToStorage();
  }

  List<RecentlyViewedItem> getItemsExcept(String? currentSlug) {
    if (currentSlug == null || currentSlug.isEmpty) return items.toList();
    return items.where((i) => i.slug != currentSlug).toList();
  }
}
