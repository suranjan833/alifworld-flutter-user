import '../../home/models/showcase_model.dart';
import 'product_seller_model.dart';
import 'product_variant_model.dart';

export 'product_seller_model.dart';
export 'product_variant_model.dart';

class ProductDetailsModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int? priceMinor;
  final int? compareAtPriceMinor;
  final int? productPoints;
  final int? stockQty;
  final List<String> images;
  final List<ProductVariantModel> variants;
  final ProductSellerModel seller;
  final String? categoryId;
  final String? categoryName;
  final String? brandName;
  final double? ratingAvg;
  final int? ratingCount;
  final bool openBoxDelivery;
  final bool isFavorite;
  final int? minPurchaseQty;
  final int? maxPurchaseQty;
  final bool isVisible;

  ProductDetailsModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.priceMinor,
    this.compareAtPriceMinor,
    this.productPoints,
    this.stockQty,
    this.images = const [],
    this.variants = const [],
    required this.seller,
    this.categoryId,
    this.categoryName,
    this.brandName,
    this.ratingAvg,
    this.ratingCount,
    this.openBoxDelivery = false,
    this.isFavorite = false,
    this.minPurchaseQty,
    this.maxPurchaseQty,
    this.isVisible = true,
  });

  int get effectiveMinQty {
    final vMin = variants.isNotEmpty ? variants.first.minPurchaseQty : null;
    final m = minPurchaseQty ?? vMin;
    return (m != null && m > 0) ? m : 1;
  }

  int? get effectiveMaxQty {
    final vMax = variants.isNotEmpty ? variants.first.maxPurchaseQty : null;
    return maxPurchaseQty ?? vMax;
  }

  int get effectiveCap {
    final s = stockQty;
    final m = effectiveMaxQty;
    if (s != null && m != null) return s < m ? s : m;
    return m ?? s ?? 999999;
  }

  bool get hasPurchaseLimits =>
      (effectiveMinQty > 1) || effectiveMaxQty != null;

  String? get purchaseLimitsText {
    final minQ = effectiveMinQty;
    final maxQ = effectiveMaxQty;
    if (minQ > 1 && maxQ != null) {
      return 'Min: $minQ • Max: $maxQ';
    } else if (minQ > 1) {
      return 'Minimum purchase: $minQ';
    } else if (maxQ != null) {
      return 'Maximum purchase: $maxQ';
    }
    return null;
  }

  double get price {
    if (priceMinor != null && priceMinor! > 0) {
      return priceMinor! / 100.0;
    }
    if (variants.isNotEmpty && variants.first.priceMinor != null) {
      return variants.first.price;
    }
    return 0.0;
  }

  double? get originalPrice {
    if (compareAtPriceMinor != null && compareAtPriceMinor! > 0) {
      return compareAtPriceMinor! / 100.0;
    }
    if (variants.isNotEmpty && variants.first.compareAtPriceMinor != null) {
      return variants.first.originalPrice;
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
    final orig = originalPrice;
    if (orig != null && orig > price && price > 0) {
      final pct = (((orig - price) / orig) * 100).round();
      if (pct > 0) return '$pct% OFF';
    }
    return '';
  }

  String get displayTitle => name;

  String titleWithVariant(ProductVariantModel? variant) {
    if (variant == null || variants.length <= 1) return name;
    final vLabel = variant.label.trim();
    if (vLabel.isEmpty ||
        vLabel.toLowerCase() == name.toLowerCase() ||
        vLabel.toLowerCase() == 'default') {
      return name;
    }
    return '$name ($vLabel)';
  }

  String get displayBrand => brandName ?? 'Alif';

  String get displayCategory => categoryName ?? '';

  double get displayRating => ratingAvg ?? 4.8;

  int get displayReviewsCount => ratingCount ?? 128;

  String get displayImage => images.isNotEmpty
      ? images.first
      : (variants.isNotEmpty && variants.first.images.isNotEmpty
            ? variants.first.images.first
            : '');

  bool get inStock =>
      (stockQty != null && stockQty! > 0) ||
      (variants.isNotEmpty && variants.any((v) => v.inStock));

  String get cleanDescription {
    if (description.isEmpty) {
      return 'Experience genuine quality with $name. Certified authentic product directly from ${seller.shopName} on Alif with fast and secure shipping.';
    }
    if (!description.contains('<')) {
      return description;
    }
    return description
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  factory ProductDetailsModel.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = rawJson;
    if (json.containsKey('product') && json['product'] is Map) {
      json = Map<String, dynamic>.from(json['product'] as Map);
    } else if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
      if (json.containsKey('product') && json['product'] is Map) {
        json = Map<String, dynamic>.from(json['product'] as Map);
      }
    }

    final resolvedName =
        json['name']?.toString() ??
        json['title']?.toString() ??
        'Product Details';

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

    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] is List) {
      for (var v in json['variants'] as List) {
        if (v is Map) {
          parsedVariants.add(
            ProductVariantModel.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }

    int? pMinor = json['priceMinor'] is num
        ? (json['priceMinor'] as num).toInt()
        : null;
    if (pMinor == null) {
      final rawPrice = json['rawPrice'] ?? json['price'];
      if (rawPrice is num) {
        pMinor = (rawPrice * 100).toInt();
      } else if (rawPrice is String) {
        final clean = rawPrice
            .replaceAll('৳', '')
            .replaceAll('₹', '')
            .replaceAll('\$', '')
            .replaceAll(',', '')
            .trim();
        final parsed = double.tryParse(clean);
        if (parsed != null) pMinor = (parsed * 100).toInt();
      }
    }
    if (pMinor == null &&
        parsedVariants.isNotEmpty &&
        parsedVariants.first.priceMinor != null) {
      pMinor = parsedVariants.first.priceMinor;
    }

    int? cMinor = json['compareAtPriceMinor'] is num
        ? (json['compareAtPriceMinor'] as num).toInt()
        : null;
    if (cMinor == null) {
      final rawOrig = json['originalPrice'];
      if (rawOrig is num) {
        cMinor = (rawOrig * 100).toInt();
      } else if (rawOrig is String) {
        final clean = rawOrig
            .replaceAll('৳', '')
            .replaceAll('₹', '')
            .replaceAll('\$', '')
            .replaceAll(',', '')
            .trim();
        final parsed = double.tryParse(clean);
        if (parsed != null) cMinor = (parsed * 100).toInt();
      }
    }
    if (cMinor == null &&
        parsedVariants.isNotEmpty &&
        parsedVariants.first.compareAtPriceMinor != null) {
      cMinor = parsedVariants.first.compareAtPriceMinor;
    }

    ProductSellerModel parsedSeller;
    if (json['seller'] is Map) {
      parsedSeller = ProductSellerModel.fromJson(
        Map<String, dynamic>.from(json['seller'] as Map),
      );
    } else {
      parsedSeller = ProductSellerModel(
        shopName: json['sellerShopName']?.toString() ?? 'Alif Official Store',
      );
    }

    String desc = json['description']?.toString() ?? '';
    if (desc.isEmpty) {
      desc =
          'Experience genuine quality with $resolvedName. Certified authentic product directly from ${parsedSeller.shopName} on Alif with fast and secure shipping.';
    }

    String? bName;
    if (json['brand'] is Map) {
      bName = (json['brand'] as Map)['name']?.toString();
    } else if (json['brand'] != null) {
      bName = json['brand'].toString();
    } else if (json['brandName'] != null) {
      bName = json['brandName'].toString();
    }
    if (bName == null || bName.isEmpty) {
      final lowerName = resolvedName.toLowerCase();
      if (lowerName.contains('iphone') ||
          lowerName.contains('apple') ||
          lowerName.contains('macbook') ||
          lowerName.contains('ipad')) {
        bName = 'Apple';
      } else if (lowerName.contains('samsung') ||
          lowerName.contains('galaxy')) {
        bName = 'Samsung';
      } else if (lowerName.contains('sony')) {
        bName = 'Sony';
      }
    }

    String? cName;
    if (json['category'] is Map) {
      cName = (json['category'] as Map)['name']?.toString();
    } else if (json['category'] != null) {
      cName = json['category'].toString();
    } else if (json['categoryName'] != null) {
      cName = json['categoryName'].toString();
    }

    int? minQty = json['minPurchaseQty'] is num
        ? (json['minPurchaseQty'] as num).toInt()
        : (parsedVariants.isNotEmpty ? parsedVariants.first.minPurchaseQty : null);

    int? maxQty = json['maxPurchaseQty'] is num
        ? (json['maxPurchaseQty'] as num).toInt()
        : (parsedVariants.isNotEmpty ? parsedVariants.first.maxPurchaseQty : null);

    return ProductDetailsModel(
      id: json['id']?.toString() ?? '',
      name: resolvedName,
      slug: json['slug']?.toString() ?? '',
      description: desc,
      priceMinor: pMinor,
      compareAtPriceMinor: cMinor,
      productPoints: json['productPoints'] is num
          ? (json['productPoints'] as num).toInt()
          : null,
      stockQty: json['stockQty'] is int
          ? json['stockQty'] as int
          : (json['stock'] is int ? json['stock'] as int : null),
      images: imgs,
      variants: parsedVariants,
      seller: parsedSeller,
      categoryId: json['categoryId']?.toString(),
      categoryName: cName,
      brandName: bName,
      ratingAvg: json['ratingAvg'] is num
          ? (json['ratingAvg'] as num).toDouble()
          : (json['rating'] is num ? (json['rating'] as num).toDouble() : null),
      ratingCount: json['ratingCount'] is int
          ? json['ratingCount'] as int
          : (json['reviews'] is int ? json['reviews'] as int : null),
      openBoxDelivery: json['openBoxDelivery'] == true,
      isFavorite: json['isFavorite'] == true || json['isWishlisted'] == true,
      minPurchaseQty: minQty,
      maxPurchaseQty: maxQty,
      isVisible:
          (json['isVisible'] != false) && (rawJson['isVisible'] != false),
    );
  }

  factory ProductDetailsModel.fromShowcase(ShowcaseProductModel showcase) {
    return ProductDetailsModel.fromJson(showcase.toDetailsMap());
  }

  ProductDetailsModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    int? priceMinor,
    int? compareAtPriceMinor,
    int? productPoints,
    int? stockQty,
    List<String>? images,
    List<ProductVariantModel>? variants,
    ProductSellerModel? seller,
    String? categoryId,
    String? categoryName,
    String? brandName,
    double? ratingAvg,
    int? ratingCount,
    bool? openBoxDelivery,
    bool? isFavorite,
    int? minPurchaseQty,
    int? maxPurchaseQty,
    bool? isVisible,
  }) {
    return ProductDetailsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      priceMinor: priceMinor ?? this.priceMinor,
      compareAtPriceMinor: compareAtPriceMinor ?? this.compareAtPriceMinor,
      productPoints: productPoints ?? this.productPoints,
      stockQty: stockQty ?? this.stockQty,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      seller: seller ?? this.seller,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      openBoxDelivery: openBoxDelivery ?? this.openBoxDelivery,
      isFavorite: isFavorite ?? this.isFavorite,
      minPurchaseQty: minPurchaseQty ?? this.minPurchaseQty,
      maxPurchaseQty: maxPurchaseQty ?? this.maxPurchaseQty,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': name,
      'slug': slug,
      'description': description,
      'priceMinor': priceMinor,
      'compareAtPriceMinor': compareAtPriceMinor,
      'productPoints': productPoints,
      'stockQty': stockQty,
      'images': images,
      'image': displayImage,
      'variants': variants.map((v) => v.toJson()).toList(),
      'seller': seller.toJson(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandName': brandName,
      if (minPurchaseQty != null) 'minPurchaseQty': minPurchaseQty,
      if (maxPurchaseQty != null) 'maxPurchaseQty': maxPurchaseQty,
      'brand': brandName,
      'ratingAvg': ratingAvg,
      'rating': ratingAvg,
      'ratingCount': ratingCount,
      'reviews': ratingCount,
      'openBoxDelivery': openBoxDelivery,
      'isFavorite': isFavorite,
      'isVisible': isVisible,
      'price': priceFormatted,
      'originalPrice': originalPriceFormatted,
      'discount': discount,
    };
  }
}
