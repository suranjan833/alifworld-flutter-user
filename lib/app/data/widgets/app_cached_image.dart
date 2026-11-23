import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../config/functions/dio_function/app_config.dart';
import '../services/app_image_cache_service.dart';
import 'skeleton_box.dart';

class AppCachedImage extends GetView<AppImageCacheService> {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? color;
  final BlendMode? colorBlendMode;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.color,
    this.colorBlendMode,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// Utility to pre-cache image permanently to disk and warm up RAM cache
  static Future<void> precache(BuildContext context, String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) return;
    try {
      final resolved = resolveImageUrl(rawUrl);
      if (resolved.isNotEmpty &&
          (resolved.startsWith('http://') || resolved.startsWith('https://'))) {
        final lower = resolved.toLowerCase();
        if (lower.contains('.svg')) return;

        if (Get.isRegistered<AppImageCacheService>()) {
          final file = await AppImageCacheService.to.getOrDownloadFile(resolved);
          if (file != null && context.mounted) {
            await precacheImage(
              FileImage(file),
              context,
              onError: (e, stackTrace) {},
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) {
      return _wrapBorderRadius(placeholder ?? _buildSkeletonPlaceholder());
    }

    final resolved = resolveImageUrl(raw);
    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      return _wrapBorderRadius(placeholder ?? _buildSkeletonPlaceholder());
    }

    // 1. Instant Synchronous Check: if already cached on disk, render immediately
    final existingFile = controller.getExistingFile(resolved);
    if (existingFile != null) {
      return _wrapBorderRadius(_buildFileImage(existingFile));
    }

    // 2. Not cached on disk yet: trigger background download and display placeholder/image
    return _wrapBorderRadius(
      FutureBuilder<File?>(
        future: controller.getOrDownloadFile(resolved),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              return _buildFileImage(snapshot.data!);
            }
            return errorWidget ?? placeholder ?? _buildSkeletonPlaceholder();
          }

          if (snapshot.hasError) {
            return errorWidget ?? placeholder ?? _buildSkeletonPlaceholder();
          }

          return placeholder ?? _buildSkeletonPlaceholder();
        },
      ),
    );
  }

  Widget _buildFileImage(File file) {
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheWidth: memCacheWidth,
      cacheHeight: memCacheHeight,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? placeholder ?? _buildSkeletonPlaceholder(),
    );
  }

  Widget _wrapBorderRadius(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _buildSkeletonPlaceholder() {
    return SkeletonShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF3),
          borderRadius: borderRadius ?? BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
