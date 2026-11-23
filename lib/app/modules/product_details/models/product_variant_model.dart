class ProductVariantModel {
  final String id;
  final String sku;
  final String label;
  final int? priceMinor;
  final int? compareAtPriceMinor;
  final int? productPoints;
  final int? stockQty;
  final int? campaignSaleMinor;
  final int? campaignDiscountMinor;
  final String? campaignName;
  final List<String> images;
  final Map<String, dynamic>? attributes;
  final List<Map<String, dynamic>> dimensions;
  final int? minPurchaseQty;
  final int? maxPurchaseQty;

  ProductVariantModel({
    required this.id,
    required this.sku,
    required this.label,
    this.priceMinor,
    this.compareAtPriceMinor,
    this.productPoints,
    this.stockQty,
    this.campaignSaleMinor,
    this.campaignDiscountMinor,
    this.campaignName,
    this.images = const [],
    this.attributes,
    this.dimensions = const [],
    this.minPurchaseQty,
    this.maxPurchaseQty,
  });

  bool get isCampaignActive =>
      campaignSaleMinor != null && campaignSaleMinor! > 0;

  int get effectivePriceMinor =>
      isCampaignActive ? campaignSaleMinor! : (priceMinor ?? 0);

  double get price => effectivePriceMinor / 100.0;

  double? get originalPrice {
    if (compareAtPriceMinor != null) {
      return compareAtPriceMinor! / 100.0;
    }
    if (isCampaignActive &&
        priceMinor != null &&
        priceMinor! > effectivePriceMinor) {
      return priceMinor! / 100.0;
    }
    return null;
  }

  String get priceFormatted =>
      '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';

  String? get originalPriceFormatted {
    final orig = originalPrice;
    if (orig != null && orig > price) {
      return '৳${orig.toStringAsFixed(orig.truncateToDouble() == orig ? 0 : 2)}';
    }
    return null;
  }

  String get discount {
    final origMinor =
        compareAtPriceMinor ??
        (isCampaignActive && priceMinor != null ? priceMinor : null);
    if (origMinor != null &&
        origMinor > effectivePriceMinor &&
        effectivePriceMinor > 0) {
      final pct = (((origMinor - effectivePriceMinor) / origMinor) * 100)
          .round();
      if (pct > 0) return '$pct% OFF';
    }
    return '';
  }

  bool get inStock => stockQty == null || stockQty! > 0;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    int? pMinor = json['priceMinor'] is num
        ? (json['priceMinor'] as num).toInt()
        : null;
    if (pMinor == null && json['price'] is num) {
      pMinor = ((json['price'] as num) * 100).toInt();
    }

    int? cMinor = json['compareAtPriceMinor'] is num
        ? (json['compareAtPriceMinor'] as num).toInt()
        : null;
    if (cMinor == null && json['originalPrice'] is num) {
      cMinor = ((json['originalPrice'] as num) * 100).toInt();
    }

    List<String> imgs = [];
    if (json['images'] is List) {
      for (var item in json['images'] as List) {
        if (item is Map) {
          final url =
              item['fileUrl'] ?? item['url'] ?? item['image'] ?? item['src'];
          if (url != null && url.toString().isNotEmpty) {
            imgs.add(url.toString());
          }
        } else if (item != null && item.toString().isNotEmpty) {
          imgs.add(item.toString());
        }
      }
    } else if (json['imageUrl'] != null &&
        json['imageUrl'].toString().isNotEmpty) {
      imgs = [json['imageUrl'].toString()];
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      imgs = [json['image'].toString()];
    }

    int? sQty = json['stockQty'] is num
        ? (json['stockQty'] as num).toInt()
        : (json['stock'] is num
              ? (json['stock'] as num).toInt()
              : (json['quantity'] is num
                    ? (json['quantity'] as num).toInt()
                    : null));

    List<Map<String, dynamic>> dims = [];
    if (json['dimensions'] is List) {
      dims = (json['dimensions'] as List)
          .whereType<Map>()
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    }

    final rawMin = json['minPurchaseQty'];
    final int? minQty = rawMin is num ? rawMin.toInt() : null;

    final rawMax = json['maxPurchaseQty'];
    final int? maxQty = rawMax is num ? rawMax.toInt() : null;

    return ProductVariantModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      label:
          json['label']?.toString() ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          'Default',
      priceMinor: pMinor,
      compareAtPriceMinor: cMinor,
      productPoints: json['productPoints'] is num
          ? (json['productPoints'] as num).toInt()
          : null,
      stockQty: sQty,
      campaignSaleMinor: (json['campaignSaleMinor'] as num?)?.toInt(),
      campaignDiscountMinor: (json['campaignDiscountMinor'] as num?)?.toInt(),
      campaignName: json['campaignName']?.toString(),
      images: imgs,
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : null,
      dimensions: dims,
      minPurchaseQty: minQty,
      maxPurchaseQty: maxQty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'label': label,
      'priceMinor': priceMinor,
      'compareAtPriceMinor': compareAtPriceMinor,
      'productPoints': productPoints,
      'stockQty': stockQty,
      'campaignSaleMinor': campaignSaleMinor,
      'campaignDiscountMinor': campaignDiscountMinor,
      'campaignName': campaignName,
      'images': images,
      'attributes': attributes,
      'dimensions': dimensions,
      if (minPurchaseQty != null) 'minPurchaseQty': minPurchaseQty,
      if (maxPurchaseQty != null) 'maxPurchaseQty': maxPurchaseQty,
    };
  }
}
