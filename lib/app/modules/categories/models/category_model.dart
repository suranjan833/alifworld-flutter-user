import 'package:flutter/material.dart';

import '../../../data/config/functions/dio_function/app_config.dart';

class CategoryModel {
  final String? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? image;
  final String? imageUrl;
  final String? icon;
  final String? parentId;
  final int count;
  final int productCount;
  final int subcategoryCount;
  final String? headerBgDesktopUrl;
  final String? headerBgMobileUrl;
  final bool miniBannerEnabled;
  final String? miniBannerImageUrl;
  final String? miniBannerTagline;
  final String? miniBannerBadge;
  final bool pinnedInAll;
  final int pinnedSort;
  final Color? accent;
  final List<CategoryModel>? children;

  CategoryModel({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.image,
    this.imageUrl,
    this.icon,
    this.parentId,
    this.count = 0,
    this.productCount = 0,
    this.subcategoryCount = 0,
    this.headerBgDesktopUrl,
    this.headerBgMobileUrl,
    this.miniBannerEnabled = false,
    this.miniBannerImageUrl,
    this.miniBannerTagline,
    this.miniBannerBadge,
    this.pinnedInAll = false,
    this.pinnedSort = 0,
    this.accent,
    this.children,
  });

  String get fullImageUrl => resolveImageUrl(imageUrl ?? image);
  String get fullHeaderBgMobileUrl => resolveImageUrl(headerBgMobileUrl);
  String get fullHeaderBgDesktopUrl => resolveImageUrl(headerBgDesktopUrl);
  String get fullMiniBannerImageUrl => resolveImageUrl(miniBannerImageUrl);

  bool get isSvg {
    final lower = fullImageUrl.toLowerCase();
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<CategoryModel>? childList;
    if (json['children'] != null && json['children'] is List) {
      childList = (json['children'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final slug = json['slug']?.toString();
    final rawImageUrl =
        json['imageUrl']?.toString() ?? json['image']?.toString();
    final headerBgMobile = json['headerBgMobileUrl']?.toString();
    final headerBgDesktop = json['headerBgDesktopUrl']?.toString();
    final miniBannerImg = json['miniBannerImageUrl']?.toString();

    // For raster display (in category card photo), prefer mobile header / image / fallback photo
    String? displayImage = headerBgMobile ?? json['banner']?.toString();
    if (displayImage == null || displayImage.isEmpty) {
      if (rawImageUrl != null && !rawImageUrl.toLowerCase().endsWith('.svg')) {
        displayImage = rawImageUrl;
      } else {
        displayImage = getFallbackImageForSlug(slug);
      }
    }
    displayImage = resolveImageUrl(displayImage);

    final pCount = json['productCount'] is int
        ? json['productCount'] as int
        : (json['count'] is int
            ? json['count'] as int
            : int.tryParse(json['count']?.toString() ?? '0') ?? 0);

    final subCount = json['subcategoryCount'] is int
        ? json['subcategoryCount'] as int
        : (childList?.length ?? 0);

    return CategoryModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['title']?.toString(),
      slug: slug,
      description: json['description']?.toString(),
      image: displayImage,
      imageUrl: rawImageUrl,
      icon: json['icon']?.toString(),
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      count: pCount,
      productCount: pCount,
      subcategoryCount: subCount,
      headerBgDesktopUrl: headerBgDesktop,
      headerBgMobileUrl: headerBgMobile,
      miniBannerEnabled: json['miniBannerEnabled'] == true,
      miniBannerImageUrl: miniBannerImg,
      miniBannerTagline: json['miniBannerTagline']?.toString(),
      miniBannerBadge: json['miniBannerBadge']?.toString(),
      pinnedInAll: json['pinnedInAll'] == true,
      pinnedSort: json['pinnedSort'] is int
          ? json['pinnedSort'] as int
          : int.tryParse(json['pinnedSort']?.toString() ?? '0') ?? 0,
      children: childList,
    );
  }

  static String getFallbackImageForSlug(String? slug) {
    switch (slug?.toLowerCase()) {
      case 'electronics':
        return 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=400&auto=format&fit=crop';
      case 'fashion':
        return 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?q=80&w=400&auto=format&fit=crop';
      case 'home-living':
        return 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=400&auto=format&fit=crop';
      case 'beauty':
        return 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400&auto=format&fit=crop';
      case 'health':
        return 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400&auto=format&fit=crop';
      case 'grocery':
        return 'https://images.unsplash.com/photo-1563227812-0ea4c22e6cc8?q=80&w=400&auto=format&fit=crop';
      case 'baby-kids':
        return 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?q=80&w=400&auto=format&fit=crop';
      case 'sports':
        return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=400&auto=format&fit=crop';
      case 'automotive':
        return 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=400&auto=format&fit=crop';
      case 'books':
        return 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?q=80&w=400&auto=format&fit=crop';
      case 'toys':
        return 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?q=80&w=400&auto=format&fit=crop';
      case 'jewelry':
        return 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?q=80&w=400&auto=format&fit=crop';
      case 'pets':
        return 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?q=80&w=400&auto=format&fit=crop';
      case 'tools':
        return 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?q=80&w=400&auto=format&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=400&auto=format&fit=crop';
    }
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? image,
    String? imageUrl,
    String? icon,
    String? parentId,
    int? count,
    int? productCount,
    int? subcategoryCount,
    String? headerBgDesktopUrl,
    String? headerBgMobileUrl,
    bool? miniBannerEnabled,
    String? miniBannerImageUrl,
    String? miniBannerTagline,
    String? miniBannerBadge,
    bool? pinnedInAll,
    int? pinnedSort,
    Color? accent,
    List<CategoryModel>? children,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      count: count ?? this.count,
      productCount: productCount ?? this.productCount,
      subcategoryCount: subcategoryCount ?? this.subcategoryCount,
      headerBgDesktopUrl: headerBgDesktopUrl ?? this.headerBgDesktopUrl,
      headerBgMobileUrl: headerBgMobileUrl ?? this.headerBgMobileUrl,
      miniBannerEnabled: miniBannerEnabled ?? this.miniBannerEnabled,
      miniBannerImageUrl: miniBannerImageUrl ?? this.miniBannerImageUrl,
      miniBannerTagline: miniBannerTagline ?? this.miniBannerTagline,
      miniBannerBadge: miniBannerBadge ?? this.miniBannerBadge,
      pinnedInAll: pinnedInAll ?? this.pinnedInAll,
      pinnedSort: pinnedSort ?? this.pinnedSort,
      accent: accent ?? this.accent,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': (image != null && image!.isNotEmpty) ? image : imageUrl,
      'imageUrl': (imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl : image,
      'icon': icon,
      'parentId': parentId,
      'count': count,
      'productCount': productCount,
      'subcategoryCount': subcategoryCount,
      'headerBgDesktopUrl': headerBgDesktopUrl,
      'headerBgMobileUrl': headerBgMobileUrl,
      'miniBannerEnabled': miniBannerEnabled,
      'miniBannerImageUrl': miniBannerImageUrl,
      'miniBannerTagline': miniBannerTagline,
      'miniBannerBadge': miniBannerBadge,
      'pinnedInAll': pinnedInAll,
      'pinnedSort': pinnedSort,
      'children': children?.map((x) => x.toJson()).toList(),
    };
  }
}
