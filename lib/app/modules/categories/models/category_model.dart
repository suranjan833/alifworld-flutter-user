import 'package:flutter/material.dart';

class CategoryModel {
  final String? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? image;
  final String? icon;
  final String? parentId;
  final int count;
  final Color? accent;
  final List<CategoryModel>? children;

  CategoryModel({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.image,
    this.icon,
    this.parentId,
    this.count = 0,
    this.accent,
    this.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<CategoryModel>? childList;
    if (json['children'] != null && json['children'] is List) {
      childList = (json['children'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final slug = json['slug']?.toString();
    String? imgUrl = json['image']?.toString() ??
        json['headerBgMobileUrl']?.toString() ??
        json['imageUrl']?.toString() ??
        json['banner']?.toString();

    // If null or an svg (not supported by raster Image.network), use high-res photo for the category
    if (imgUrl == null || imgUrl.isEmpty || imgUrl.endsWith('.svg')) {
      imgUrl = getFallbackImageForSlug(slug);
    } else if (imgUrl.startsWith('/')) {
      imgUrl = 'https://alifworld.vercel.app$imgUrl';
    }

    return CategoryModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['title']?.toString(),
      slug: slug,
      description: json['description']?.toString(),
      image: imgUrl,
      icon: json['icon']?.toString(),
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      count: json['productCount'] is int
          ? json['productCount']
          : (json['count'] is int
              ? json['count']
              : int.tryParse(json['count']?.toString() ?? '0') ?? 0),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'icon': icon,
      'parentId': parentId,
      'count': count,
      'children': children?.map((x) => x.toJson()).toList(),
    };
  }
}
