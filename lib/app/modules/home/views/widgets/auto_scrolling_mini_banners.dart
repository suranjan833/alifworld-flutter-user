import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../data/config/app_color.dart';
import '../../../../data/widgets/app_cached_image.dart';
import '../../../../data/widgets/skeleton_box.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/mini_banners_controller.dart';
import '../../models/showcase_model.dart';

class AutoScrollingMiniBanners extends GetView<MiniBannersController> {
  final List<ShowcaseMiniBannerModel> miniBanners;

  const AutoScrollingMiniBanners({
    super.key,
    required this.miniBanners,
  });

  List<ShowcaseMiniBannerModel> get _banners =>
      miniBanners.isNotEmpty ? miniBanners : MiniBannersController.fallbackBanners;

  @override
  MiniBannersController get controller {
    if (!Get.isRegistered<MiniBannersController>()) {
      Get.put(MiniBannersController());
    }
    return Get.find<MiniBannersController>();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MiniBannersController>()) {
      Get.put(MiniBannersController());
    }

    final banners = _banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateBannerCount(banners.length);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) => controller.onUserTouchDown(),
          onPointerUp: (_) => controller.onUserTouchUp(),
          onPointerCancel: (_) => controller.onUserTouchUp(),
          child: SizedBox(
            height: 185.h,
            child: PageView.builder(
              controller: controller.pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (pageIndex) {
                controller.onPageChanged(pageIndex, banners.length);
              },
              itemBuilder: (context, index) {
                final mb = banners[index % banners.length];
                return _buildBannerItem(mb);
              },
            ),
          ),
        ),
        if (banners.length > 1) ...[
          SizedBox(height: 10.h),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (dotIndex) {
                final isSelected = dotIndex == controller.currentIndex.value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                  width: isSelected ? 16.w : 5.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primary
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBannerItem(ShowcaseMiniBannerModel mb) {
    final skeleton = SkeletonShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF3),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.CATEGORY_PRODUCTS,
          arguments: {
            'name': mb.name,
            'slug': mb.slug,
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: AspectRatio(
            aspectRatio: 1.46, // matches 1515 x 1038 minibanner aspect ratio
            child: mb.fullImageUrl.isNotEmpty
                ? AppCachedImage(
                    imageUrl: mb.fullImageUrl,
                    fit: BoxFit.cover,
                    placeholder: skeleton,
                    errorWidget: skeleton,
                  )
                : skeleton,
          ),
        ),
      ),
    );
  }
}
