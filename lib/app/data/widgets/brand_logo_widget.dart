import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../services/app_image_cache_service.dart';
import 'app_cached_image.dart';

class BrandLogoWidget extends GetView<AppImageCacheService> {
  final String logoUrl;
  final String brandName;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BrandLogoWidget({
    super.key,
    required this.logoUrl,
    required this.brandName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  String get _normalizedUrl {
    final trimmed = logoUrl.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '';
    return resolveImageUrl(trimmed);
  }

  bool get _isSvg {
    final lower = _normalizedUrl.toLowerCase();
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  @override
  Widget build(BuildContext context) {
    final url = _normalizedUrl;

    if (url.isEmpty) {
      return _buildFallback();
    }

    if (_isSvg) {
      return Padding(
        padding: EdgeInsets.all(3.r),
        child: SvgPicture.network(
          url,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) => _buildFallback(),
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }

    return AppCachedImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: _buildFallback(),
      errorWidget: _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final isCompact =
        (width != null && width! <= 48) || (height != null && height! <= 48);

    if (isCompact) {
      final initial = brandName.trim().isNotEmpty
          ? brandName.trim()[0].toUpperCase()
          : '';
      return Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFEFF6FF),
          child: Center(
            child: initial.isNotEmpty
                ? Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.primary,
                    ),
                  )
                : Icon(
                    Icons.category_outlined,
                    size: 18.r,
                    color: AppColor.primary,
                  ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Text(
          brandName.isNotEmpty ? brandName : 'Brand',
          style: GoogleFonts.montserrat(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
