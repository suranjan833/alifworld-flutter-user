import '../../../data/config/functions/dio_function/app_config.dart';
import '../../product_details/models/product_details_model.dart';

class ProductModel {
  final String? id;
  final String? brand;
  final String? title;
  final String? slug;
  final String? description;
  final double price;
  final double? originalPrice;
  final String? discount;
  final String? image;
  final List<String>? images;
  final String? badge;
  final String? subCategoryId;
  final double? rating;

  final List<Map<String, dynamic>>? variants;
  final Map<String, dynamic>? seller;
  final String? categoryName;
  final int? stockQty;

  ProductModel({
    this.id,
    this.brand,
    this.title,
    this.slug,
    this.description,
    this.price = 0.0,
    this.originalPrice,
    this.discount,
    this.image,
    this.images,
    this.badge,
    this.subCategoryId,
    this.rating,
    this.variants,
    this.seller,
    this.categoryName,
    this.stockQty,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['priceMinor'] is num) {
      parsedPrice = (json['priceMinor'] as num) / 100.0;
    } else if (json['price'] != null) {
      parsedPrice = json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0;
    }

    double? parsedOriginalPrice;
    if (json['compareAtPriceMinor'] is num) {
      parsedOriginalPrice = (json['compareAtPriceMinor'] as num) / 100.0;
    } else if (json['originalPrice'] != null ||
        json['compareAtPrice'] != null) {
      final orig = json['originalPrice'] ?? json['compareAtPrice'];
      parsedOriginalPrice = orig is num
          ? orig.toDouble()
          : double.tryParse(orig.toString());
    }

    List<Map<String, dynamic>>? parsedVariants;
    if (json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    // Check first variant if price is 0
    if (parsedPrice == 0.0 && parsedVariants != null && parsedVariants.isNotEmpty) {
      final firstVar = parsedVariants.first;
      if (firstVar['priceMinor'] is num) {
        parsedPrice = (firstVar['priceMinor'] as num) / 100.0;
      }
      if (firstVar['compareAtPriceMinor'] is num) {
        parsedOriginalPrice =
            (firstVar['compareAtPriceMinor'] as num) / 100.0;
      }
    }

    // Calculate discount if not present
    String? discountStr = json['discount']?.toString();
    if ((discountStr == null || discountStr.isEmpty) &&
        parsedOriginalPrice != null &&
        parsedOriginalPrice > parsedPrice &&
        parsedPrice > 0) {
      final pct =
          (((parsedOriginalPrice - parsedPrice) / parsedOriginalPrice) * 100)
              .round();
      if (pct > 0) discountStr = '$pct% OFF';
    }

    List<String> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      for (var e in json['images'] as List) {
        if (e != null &&
            e.toString().trim().isNotEmpty &&
            e.toString() != 'null') {
          parsedImages.add(resolveImageUrl(e.toString().trim()));
        }
      }
    } else if (json['image'] != null &&
        json['image'].toString().trim().isNotEmpty &&
        json['image'].toString() != 'null') {
      parsedImages.add(resolveImageUrl(json['image'].toString().trim()));
    } else if (json['thumbnail'] != null &&
        json['thumbnail'].toString().trim().isNotEmpty &&
        json['thumbnail'].toString() != 'null') {
      parsedImages.add(resolveImageUrl(json['thumbnail'].toString().trim()));
    }

    // Fallback to variant images if product-level images list is empty
    if (parsedImages.isEmpty &&
        parsedVariants != null &&
        parsedVariants.isNotEmpty) {
      for (var v in parsedVariants) {
        if (v['images'] is List) {
          for (var img in v['images'] as List) {
            if (img != null &&
                img.toString().trim().isNotEmpty &&
                img.toString() != 'null') {
              parsedImages.add(resolveImageUrl(img.toString().trim()));
            }
          }
        }
      }
    }

    String? primaryImage = parsedImages.isNotEmpty ? parsedImages.first : null;
    if (primaryImage == null) {
      final raw = json['image']?.toString() ?? json['thumbnail']?.toString();
      if (raw != null && raw != 'null' && raw.trim().isNotEmpty) {
        primaryImage = resolveImageUrl(raw.trim());
      }
    }

    Map<String, dynamic>? parsedSeller;
    if (json['seller'] is Map<String, dynamic>) {
      parsedSeller = json['seller'] as Map<String, dynamic>;
    }

    return ProductModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      brand: json['brand']?.toString() ?? json['brandName']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      price: parsedPrice > 0 ? parsedPrice : 999.0,
      originalPrice: parsedOriginalPrice,
      discount: discountStr,
      image: primaryImage,
      images: parsedImages.isNotEmpty ? parsedImages : null,
      badge: json['badge']?.toString(),
      subCategoryId:
          json['subCategoryId']?.toString() ??
          json['category_id']?.toString() ??
          json['categoryId']?.toString(),
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : null,
      variants: parsedVariants,
      seller: parsedSeller,
      categoryName: json['categoryName']?.toString(),
      stockQty: json['stockQty'] is int ? json['stockQty'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'image': image,
      'images': images,
      'badge': badge,
      'subCategoryId': subCategoryId,
      'rating': rating,
      'variants': variants,
      'seller': seller,
      'categoryName': categoryName,
      'stockQty': stockQty,
    };
  }

  ProductDetailsModel toProductDetails() {
    return ProductDetailsModel.fromJson(toJson());
  }
}
