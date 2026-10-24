import 'package:flutter/material.dart';

import '../../../data/config/functions/dio_function/app_config.dart';

class HomeCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String searchHint;
  final String bannerTitle;
  final String bannerSubtitle;
  final String bannerImage;
  final Color bgColor;
  final Color accentColor;
  final Color buttonColor;
  final Color subtitleColor;
  final bool isScriptSubtitle;
  final String headerBgMobileUrl;
  final String? imageUrl;
  List<Map<String, dynamic>> products;

  HomeCategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon = 'all',
    this.searchHint = 'Search Products',
    this.bannerTitle = 'DISCOVER ALIF',
    this.bannerSubtitle = 'Best Deals For You',
    this.bannerImage = 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?q=80&w=1200&auto=format&fit=crop',
    this.headerBgMobileUrl = '/category-headers/all-mobile.png',
    this.imageUrl,
    this.bgColor = const Color(0xFFFAF9F6),
    this.accentColor = const Color(0xFF3760A5),
    this.buttonColor = const Color(0xFF3760A5),
    this.subtitleColor = const Color(0xFF5A6578),
    this.isScriptSubtitle = false,
    this.products = const [],
  });

  String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    return resolveImageUrl(imageUrl);
  }

  bool get isSvgIcon {
    final url = fullImageUrl.toLowerCase();
    return url.endsWith('.svg') || url.contains('.svg?');
  }

  HomeCategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    String? searchHint,
    String? bannerTitle,
    String? bannerSubtitle,
    String? bannerImage,
    String? headerBgMobileUrl,
    String? imageUrl,
    Color? bgColor,
    Color? accentColor,
    Color? buttonColor,
    Color? subtitleColor,
    bool? isScriptSubtitle,
    List<Map<String, dynamic>>? products,
  }) {
    return HomeCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      searchHint: searchHint ?? this.searchHint,
      bannerTitle: bannerTitle ?? this.bannerTitle,
      bannerSubtitle: bannerSubtitle ?? this.bannerSubtitle,
      bannerImage: bannerImage ?? this.bannerImage,
      headerBgMobileUrl: headerBgMobileUrl ?? this.headerBgMobileUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      bgColor: bgColor ?? this.bgColor,
      accentColor: accentColor ?? this.accentColor,
      buttonColor: buttonColor ?? this.buttonColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      isScriptSubtitle: isScriptSubtitle ?? this.isScriptSubtitle,
      products: products ?? this.products,
    );
  }

  factory HomeCategoryModel.fromApiCategory({
    required String id,
    required String name,
    required String slug,
    String? headerBgMobile,
    String? imageUrl,
    int index = 0,
    List<Map<String, dynamic>>? products,
  }) {
    final palettes = [
      {
        'bgColor': const Color(0xFFFAF9F6),
        'accentColor': const Color(0xFF3760A5),
        'buttonColor': const Color(0xFF3760A5),
        'subtitleColor': const Color(0xFF5A6578),
      },
      {
        'bgColor': const Color(0xFFFBF6EE),
        'accentColor': const Color(0xFF8A3814),
        'buttonColor': const Color(0xFF8A3814),
        'subtitleColor': const Color(0xFF8A3814),
      },
      {
        'bgColor': const Color(0xFFF3F6FA),
        'accentColor': const Color(0xFF102A43),
        'buttonColor': const Color(0xFF102A43),
        'subtitleColor': const Color(0xFF334E68),
      },
      {
        'bgColor': const Color(0xFFFAF3F3),
        'accentColor': const Color(0xFF9E2A2B),
        'buttonColor': const Color(0xFF9E2A2B),
        'subtitleColor': const Color(0xFFB04142),
      },
      {
        'bgColor': const Color(0xFFFAF2F5),
        'accentColor': const Color(0xFFA4133C),
        'buttonColor': const Color(0xFFA4133C),
        'subtitleColor': const Color(0xFFC9184A),
      },
    ];

    final pal = palettes[index % palettes.length];

    String mobileHeader = '';
    if (headerBgMobile != null && headerBgMobile.isNotEmpty) {
      mobileHeader = resolveImageUrl(headerBgMobile);
    } else {
      mobileHeader = resolveImageUrl('/category-headers/all-mobile.png');
    }

    final bannerImages = {
      'all': 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?q=80&w=1200&auto=format&fit=crop',
      'electronics': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1200&auto=format&fit=crop',
      'fashion': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?q=80&w=1200&auto=format&fit=crop',
      'home-living': 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1200&auto=format&fit=crop',
      'beauty': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=1200&auto=format&fit=crop',
      'grocery': 'https://images.unsplash.com/photo-1563227812-0ea4c22e6cc8?q=80&w=1200&auto=format&fit=crop',
      'sports': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=1200&auto=format&fit=crop',
    };

    final bannerImg = bannerImages[slug] ?? mobileHeader;

    return HomeCategoryModel(
      id: id,
      name: name,
      slug: slug,
      icon: slug.isEmpty ? 'all' : slug,
      searchHint: 'Search "$name"',
      bannerTitle: name.toUpperCase(),
      bannerSubtitle: 'Crafted For You',
      bannerImage: bannerImg,
      headerBgMobileUrl: mobileHeader,
      imageUrl: imageUrl,
      bgColor: pal['bgColor'] as Color,
      accentColor: pal['accentColor'] as Color,
      buttonColor: pal['buttonColor'] as Color,
      subtitleColor: pal['subtitleColor'] as Color,
      isScriptSubtitle: true,
      products: products ?? [],
    );
  }
}
