import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';

class BrandLogoWidget extends StatelessWidget {
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

  String get _normalizedUrl => resolveImageUrl(logoUrl);

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
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => Center(
          child: SizedBox(
            width: 22.r,
            height: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColor.primary,
            ),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 22.r,
            height: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColor.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback() {
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
