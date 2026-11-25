import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/order_details_controller.dart';
import '../../models/order_model.dart';

class ProductReviewBottomSheet extends GetView<OrderDetailsController> {
  final OrderItemModel item;

  const ProductReviewBottomSheet({
    super.key,
    required this.item,
  });

  static void show(BuildContext context, OrderItemModel item) {
    final controller = Get.find<OrderDetailsController>();
    controller.prepareReview(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductReviewBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Write a Review',
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColor.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildProductHeader(),
              SizedBox(height: 16.h),
              Center(child: _buildStarPicker()),
              SizedBox(height: 18.h),
              _buildTextField(
                controller: controller.reviewTitleController,
                label: 'Headline / Summary',
                hint: 'e.g. Excellent build quality and fast delivery',
                maxLines: 1,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: controller.reviewBodyController,
                label: 'Your Review',
                hint: 'What did you like or dislike about this product?',
                maxLines: 4,
              ),
              SizedBox(height: 14.h),
              _buildPhotoPickerSection(),
              SizedBox(height: 20.h),
              _buildSubmitButton(),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    width: 46.r,
                    height: 46.r,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholderThumb(),
                  )
                : _placeholderThumb(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                if (item.variantName.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.variantName,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 46.r,
      height: 46.r,
      color: const Color(0xFFE2E8F0),
      child: Icon(Iconsax.image, size: 20.r, color: AppColor.textSecondary),
    );
  }

  Widget _buildStarPicker() {
    const labels = {
      1: 'Terrible',
      2: 'Poor',
      3: 'Average',
      4: 'Good',
      5: 'Excellent',
    };

    return Obx(() {
      final current = controller.reviewRating.value;
      return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (idx) {
              final starVal = idx + 1;
              final isFilled = starVal <= current;
              return GestureDetector(
                onTap: () => controller.reviewRating.value = starVal,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Icon(
                    Icons.star_rounded,
                    size: 38.r,
                    color: isFilled
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 6.h),
          Text(
            labels[current] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPickerSection() {
    return Obx(() {
      final images = controller.reviewLocalImages;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Photos (Max 5)',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                '${images.length}/5',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 64.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (images.length < 5)
                  GestureDetector(
                    onTap: controller.pickReviewImages,
                    child: Container(
                      width: 64.h,
                      height: 64.h,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.camera,
                            size: 20.r,
                            color: AppColor.primary,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Add',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...List.generate(images.length, (idx) {
                  final path = images[idx];
                  return Stack(
                    children: [
                      Container(
                        width: 64.h,
                        height: 64.h,
                        margin: EdgeInsets.only(right: 8.w),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Image.file(
                          File(path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => controller.removeReviewImage(idx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 13.r,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final isSubmitting = controller.isSubmittingReview.value;
      return SizedBox(
        width: double.infinity,
        height: 48.h,
        child: ElevatedButton(
          onPressed: isSubmitting
              ? null
              : () => controller.submitProductReview(
                    productId: item.productId,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Submit Review',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    });
  }
}
