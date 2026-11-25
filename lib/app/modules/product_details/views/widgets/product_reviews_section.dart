import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/product_details_controller.dart';
import '../../models/product_review_model.dart';

class ProductReviewsSection extends GetView<ProductDetailsController> {
  const ProductReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingReviews.value && controller.reviewsData.value == null) {
        return _buildSkeletonLoader();
      }
      final data = controller.reviewsData.value;
      final summary = data?.summary;
      final reviews = data?.reviews ?? [];
      final hasReviews = summary != null && summary.count > 0;

      return Container(
        key: controller.reviewsSectionKey,
        width: double.infinity,
        color: AppColor.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.star1, size: 20.r, color: const Color(0xFFF59E0B)),
                SizedBox(width: 8.w),
                Text(
                  hasReviews ? 'Ratings & Reviews (${summary.count})' : 'Ratings & Reviews',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (!hasReviews)
              _buildEmptyState()
            else ...[
              _buildRatingBreakdown(summary),
              SizedBox(height: 16.h),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              SizedBox(height: 14.h),
              _buildReviewList(reviews),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: Icon(Iconsax.message_favorite, size: 28.r, color: const Color(0xFFF59E0B)),
          ),
          SizedBox(height: 10.h),
          Text(
            'No reviews yet for this product',
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            'Be the first to review after purchase!',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown(ReviewSummary summary) {
    final avg = summary.average;
    final total = summary.count;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 95.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: AppColor.textPrimary, height: 1.1),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 15.r,
                  color: (i + 1) <= avg.round() ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                )),
              ),
              SizedBox(height: 4.h),
              Text('$total Ratings', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColor.textSecondary)),
            ],
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final cnt = summary.distribution[star.toString()] ?? 0;
              final pct = total > 0 ? (cnt / total).clamp(0.0, 1.0) : 0.0;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Row(
                  children: [
                    Text('$star', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColor.textSecondary)),
                    SizedBox(width: 2.w),
                    Icon(Icons.star_rounded, size: 12.r, color: const Color(0xFFF59E0B)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          minHeight: 6.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 24.w,
                      child: Text('$cnt', textAlign: TextAlign.end, style: GoogleFonts.inter(fontSize: 10.5.sp, color: AppColor.textSecondary)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewList(List<ProductReviewItem> reviews) {
    return Column(
      children: List.generate(reviews.length, (idx) {
        final r = reviews[idx];
        return Padding(
          padding: EdgeInsets.only(bottom: idx == reviews.length - 1 ? 0 : 14.h),
          child: _buildReviewCard(r),
        );
      }),
    );
  }

  Widget _buildReviewCard(ProductReviewItem r) {
    final dateStr = '${r.createdAt.day.toString().padLeft(2, '0')}/${r.createdAt.month.toString().padLeft(2, '0')}/${r.createdAt.year}';
    final name = (r.authorName != null && r.authorName!.trim().isNotEmpty) ? r.authorName!.trim() : 'Verified Buyer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColor.primary)),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                      Row(
                        children: [
                          Icon(Iconsax.verify, size: 11.r, color: const Color(0xFF16A34A)),
                          SizedBox(width: 3.w),
                          Text('Verified Purchase', style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF16A34A), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 11.sp, color: AppColor.textSecondary)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded,
              size: 16.r,
              color: i < r.rating ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            )),
          ),
          if (r.title != null && r.title!.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(r.title!.trim(), style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
          ],
          if (r.body != null && r.body!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(r.body!.trim(), style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF334155), height: 1.4)),
          ],
          if (r.photos.isNotEmpty) ...[
            SizedBox(height: 10.h),
            SizedBox(
              height: 56.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: r.photos.length,
                separatorBuilder: (context, index) => SizedBox(width: 8.w),
                itemBuilder: (context, pIdx) => ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    r.photos[pIdx],
                    width: 56.h,
                    height: 56.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56.h,
                      height: 56.h,
                      color: const Color(0xFFE2E8F0),
                      child: Icon(Iconsax.image, size: 18.r, color: AppColor.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (r.reply != null && r.reply!.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8.r),
                border: const Border(left: BorderSide(color: AppColor.primary, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.message_text_1, size: 13.r, color: AppColor.primary),
                      SizedBox(width: 5.w),
                      Text('Seller Response', style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: AppColor.primary)),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(r.reply!.trim(), style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF431407), height: 1.35)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      width: double.infinity,
      color: AppColor.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 140.w, height: 18.h, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6.r))),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(width: 90.w, height: 60.h, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8.r))),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  children: List.generate(4, (i) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    child: Container(height: 8.h, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4.r))),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
