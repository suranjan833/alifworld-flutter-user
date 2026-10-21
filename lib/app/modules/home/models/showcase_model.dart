import 'package:flutter/material.dart';

Color? parseHexColor(dynamic hexString) {
  if (hexString == null) return null;
  String hex = hexString.toString().trim();
  if (hex.isEmpty || hex.toLowerCase() == 'null') return null;
  if (hex.toLowerCase() == 'black') return const Color(0xFF000000);
  if (hex.toLowerCase() == 'white') return const Color(0xFFFFFFFF);

  if (hex.startsWith('#')) {
    hex = hex.replaceFirst('#', '');
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  } else if (hex.length == 3) {
    hex = 'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
  } else if (hex.length != 8) {
    return null;
  }
  final val = int.tryParse(hex, radix: 16);
  if (val != null) {
    return Color(val);
  }
  return null;
}

class BrandModel {
  final String id;
  final String name;
  final String slug;
  final String logoUrl;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? json['logo']?.toString() ?? '',
    );
  }

  String get fullLogoUrl {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return logoUrl;
    }
    return 'https://alifworld.vercel.app$logoUrl';
  }

  bool get isSvg => fullLogoUrl.toLowerCase().contains('.svg');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logoUrl': logoUrl,
    };
  }
}

class ShowcaseMiniBannerModel {
  final String id;
  final String name;
  final String slug;
  final String imageUrl;
  final String? tagline;
  final String? badge;

  ShowcaseMiniBannerModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.tagline,
    this.badge,
  });

  factory ShowcaseMiniBannerModel.fromJson(Map<String, dynamic> json) {
    return ShowcaseMiniBannerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      tagline: json['tagline']?.toString(),
      badge: json['badge']?.toString(),
    );
  }

  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return 'https://alifworld.vercel.app$imageUrl';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'tagline': tagline,
      'badge': badge,
    };
  }
}

class ShowcaseProductModel {
  final String id;
  final String name;
  final String slug;
  final String? brandName;
  final String? categoryName;
  final double price;
  final double? originalPrice;
  final String discount;
  final List<String> images;
  final String? sellerShopName;
  final Map<String, dynamic>? seller;
  final List<Map<String, dynamic>> variants;
  final double? rating;
  final int? reviews;
  final int? stockQty;
  final String? description;
  bool isFavorite;

  ShowcaseProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.brandName,
    this.categoryName,
    required this.price,
    this.originalPrice,
    this.discount = '',
    this.images = const [],
    this.sellerShopName,
    this.seller,
    this.variants = const [],
    this.rating,
    this.reviews,
    this.stockQty,
    this.description,
    this.isFavorite = false,
  });

  String get displayImage {
    if (images.isEmpty) return '';
    final first = images.first;
    if (first.startsWith('http://') || first.startsWith('https://')) return first;
    return 'https://alifworld.vercel.app$first';
  }

  factory ShowcaseProductModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    double? parsedOriginalPrice;

    // Check direct priceMinor or variants[0].priceMinor (money in minor units / 100)
    final rawPriceMinor = json['priceMinor'];
    final rawComparePriceMinor = json['compareAtPriceMinor'];

    if (rawPriceMinor is num) {
      parsedPrice = rawPriceMinor / 100.0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    }

    if (rawComparePriceMinor is num) {
      parsedOriginalPrice = rawComparePriceMinor / 100.0;
    } else if (json['originalPrice'] is num) {
      parsedOriginalPrice = (json['originalPrice'] as num).toDouble();
    }

    List<Map<String, dynamic>> parsedVariants = [];
    if (json['variants'] is List) {
      for (var v in json['variants'] as List) {
        if (v is Map) {
          parsedVariants.add(Map<String, dynamic>.from(v));
        }
      }
    }

    // Fallback to first variant if product-level price is null
    if (parsedPrice == 0.0 && parsedVariants.isNotEmpty) {
      final firstVar = parsedVariants.first;
      if (firstVar['priceMinor'] is num) {
        parsedPrice = (firstVar['priceMinor'] as num) / 100.0;
      }
      if (firstVar['compareAtPriceMinor'] is num) {
        parsedOriginalPrice = (firstVar['compareAtPriceMinor'] as num) / 100.0;
      }
    }

    // Calculate discount text if compareAtPrice is greater
    String calcDiscount = '';
    if (parsedOriginalPrice != null && parsedOriginalPrice > parsedPrice && parsedPrice > 0) {
      final pct = (((parsedOriginalPrice - parsedPrice) / parsedOriginalPrice) * 100).round();
      if (pct > 0) {
        calcDiscount = '$pct% OFF';
      }
    }

    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['image'] != null) {
      parsedImages = [json['image'].toString()];
    }

    if (parsedImages.isEmpty && parsedVariants.isNotEmpty) {
      for (var v in parsedVariants) {
        if (v['images'] is List) {
          for (var img in v['images'] as List) {
            if (img != null && img.toString().isNotEmpty) {
              parsedImages.add(img.toString());
            }
          }
        }
      }
    }

    String? shopName;
    Map<String, dynamic>? sellerObj;
    if (json['seller'] is Map<String, dynamic>) {
      sellerObj = json['seller'] as Map<String, dynamic>;
      shopName = sellerObj['shopName']?.toString();
    }

    double? parsedRating;
    if (json['ratingAvg'] is num) {
      parsedRating = (json['ratingAvg'] as num).toDouble();
    } else if (json['rating'] is num) {
      parsedRating = (json['rating'] as num).toDouble();
    }

    int? parsedReviews;
    if (json['ratingCount'] is int) {
      parsedReviews = json['ratingCount'] as int;
    } else if (json['reviews'] is int) {
      parsedReviews = json['reviews'] as int;
    }

    int? parsedStock;
    if (json['stockQty'] is int) {
      parsedStock = json['stockQty'] as int;
    }

    return ShowcaseProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Product',
      slug: json['slug']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? json['brand']?.toString(),
      categoryName: json['categoryName']?.toString(),
      price: parsedPrice > 0 ? parsedPrice : 0.0,
      originalPrice: parsedOriginalPrice,
      discount: calcDiscount.isNotEmpty ? calcDiscount : (json['discount']?.toString() ?? ''),
      images: parsedImages,
      sellerShopName: shopName,
      seller: sellerObj,
      variants: parsedVariants,
      rating: parsedRating,
      reviews: parsedReviews,
      stockQty: parsedStock,
      description: json['description']?.toString(),
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toDetailsMap() {
    String? defaultVariantId;
    if (variants.isNotEmpty) {
      final fv = variants.first;
      if (fv['id'] != null) {
        defaultVariantId = fv['id']?.toString();
      }
    }
    return {
      'id': id,
      'productId': id,
      'variantId': defaultVariantId,
      'title': name,
      'name': name,
      'slug': slug,
      'brand': brandName ?? 'Alif',
      'brandName': brandName ?? 'Alif',
      'categoryName': categoryName,
      'price': '৳${price.toStringAsFixed(2)}',
      'rawPrice': price,
      'originalPrice': originalPrice != null
          ? '৳${originalPrice!.toStringAsFixed(2)}'
          : null,
      'discount': discount,
      'image': displayImage,
      'images': images,
      'variants': variants,
      'seller': seller ?? (sellerShopName != null ? {'name': sellerShopName, 'shopName': sellerShopName} : null),
      'rating': rating ?? 4.8,
      'reviews': reviews ?? 24,
      'stockQty': stockQty,
      'description': description,
      'isFavorite': isFavorite,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'brandName': brandName,
      'categoryName': categoryName,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'images': images,
      'sellerShopName': sellerShopName,
      'seller': seller,
      'variants': variants,
      'rating': rating,
      'reviews': reviews,
      'stockQty': stockQty,
      'description': description,
      'isFavorite': isFavorite,
    };
  }
}

class ShowcaseRailModel {
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final List<ShowcaseProductModel> products;

  ShowcaseRailModel({
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    this.products = const [],
  });

  factory ShowcaseRailModel.fromJson(Map<String, dynamic> json) {
    String cId = '';
    String cName = 'Featured';
    String cSlug = '';

    if (json['category'] is Map<String, dynamic>) {
      final cat = json['category'] as Map<String, dynamic>;
      cId = cat['id']?.toString() ?? '';
      cName = cat['name']?.toString() ?? 'Featured';
      cSlug = cat['slug']?.toString() ?? '';
    }

    List<ShowcaseProductModel> prodList = [];
    if (json['products'] is List) {
      prodList = (json['products'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ShowcaseProductModel.fromJson(e))
          .toList();
    }

    return ShowcaseRailModel(
      categoryId: cId,
      categoryName: cName,
      categorySlug: cSlug,
      products: prodList,
    );
  }
}

class ShowcaseModel {
  final String? headerBgMobileUrl;
  final String? headerBgDesktopUrl;
  final String? allCategoryIconUrl;
  final String? categoryName;
  final String? categorySlug;
  final Color? navTapColor;
  final Color? navIdleColor;
  final List<BrandModel> brands;
  final List<ShowcaseMiniBannerModel> miniBanners;
  final List<ShowcaseRailModel> rails;
  final List<Map<String, dynamic>> rawCategories;

  ShowcaseModel({
    this.headerBgMobileUrl,
    this.headerBgDesktopUrl,
    this.allCategoryIconUrl,
    this.categoryName,
    this.categorySlug,
    this.navTapColor,
    this.navIdleColor,
    this.brands = const [],
    this.miniBanners = const [],
    this.rails = const [],
    this.rawCategories = const [],
  });

  String get fullHeaderBgMobileUrl {
    final url = headerBgMobileUrl ?? headerBgDesktopUrl;
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://alifworld.vercel.app$url';
  }

  String get fullAllCategoryIconUrl {
    if (allCategoryIconUrl == null || allCategoryIconUrl!.isEmpty) return '';
    if (allCategoryIconUrl!.startsWith('http://') ||
        allCategoryIconUrl!.startsWith('https://')) {
      return allCategoryIconUrl!;
    }
    return 'https://alifworld.vercel.app$allCategoryIconUrl';
  }

  factory ShowcaseModel.fromJson(Map<String, dynamic> json) {
    String? mobUrl;
    String? deskUrl;
    String? catName;
    String? catSlug;

    if (json['category'] is Map<String, dynamic>) {
      final cat = json['category'] as Map<String, dynamic>;
      mobUrl = cat['headerBgMobileUrl']?.toString();
      deskUrl = cat['headerBgDesktopUrl']?.toString();
      catName = cat['name']?.toString();
      catSlug = cat['slug']?.toString();
    } else {
      mobUrl = json['headerBgMobileUrl']?.toString();
      deskUrl = json['headerBgDesktopUrl']?.toString();
    }

    if (mobUrl == null || mobUrl.isEmpty) {
      if (json['allCategoryHeaderBg'] is Map<String, dynamic>) {
        final allBg = json['allCategoryHeaderBg'] as Map<String, dynamic>;
        mobUrl = allBg['mobileUrl']?.toString();
        deskUrl = allBg['desktopUrl']?.toString();
      }
    }

    List<BrandModel> parsedBrands = [];
    if (json['brands'] is List) {
      parsedBrands = (json['brands'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => BrandModel.fromJson(e))
          .toList();
    }

    List<ShowcaseMiniBannerModel> parsedBanners = [];
    if (json['miniBanners'] is List) {
      parsedBanners = (json['miniBanners'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ShowcaseMiniBannerModel.fromJson(e))
          .toList();
    }

    List<ShowcaseRailModel> parsedRails = [];
    if (json['rails'] is List) {
      parsedRails = (json['rails'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ShowcaseRailModel.fromJson(e))
          .toList();
    }

    List<Map<String, dynamic>> parsedCategories = [];
    if (json['categories'] is List) {
      parsedCategories = (json['categories'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    Color? tapColor;
    Color? idleColor;

    if (json['catNavColors'] is Map<String, dynamic>) {
      final cnc = json['catNavColors'] as Map<String, dynamic>;
      tapColor = parseHexColor(
        cnc['selected'] ?? cnc['tapColor'] ?? cnc['active'] ?? cnc['tap'],
      );
      idleColor = parseHexColor(cnc['idle'] ?? cnc['inactive']);
    }

    if (tapColor == null && json['category'] is Map<String, dynamic>) {
      final catObj = json['category'] as Map<String, dynamic>;
      if (catObj['catNavColors'] is Map<String, dynamic>) {
        final cnc = catObj['catNavColors'] as Map<String, dynamic>;
        tapColor = parseHexColor(
          cnc['selected'] ?? cnc['tapColor'] ?? cnc['active'] ?? cnc['tap'],
        );
        idleColor = parseHexColor(cnc['idle'] ?? cnc['inactive']);
      } else if (catObj['tapColor'] != null) {
        tapColor = parseHexColor(catObj['tapColor']);
      }
    }

    return ShowcaseModel(
      headerBgMobileUrl: mobUrl,
      headerBgDesktopUrl: deskUrl,
      allCategoryIconUrl: json['allCategoryIconUrl']?.toString(),
      categoryName: catName,
      categorySlug: catSlug,
      navTapColor: tapColor,
      navIdleColor: idleColor,
      brands: parsedBrands,
      miniBanners: parsedBanners,
      rails: parsedRails,
      rawCategories: parsedCategories,
    );
  }
}
