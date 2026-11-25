import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../models/product_review_model.dart';

mixin ProductReviewsMixin on GetxController {
  final reviewsData = Rxn<ProductReviewsResponse>();
  final isLoadingReviews = false.obs;
  final reviewsSectionKey = GlobalKey();
  final scrollController = ScrollController();

  Future<void> fetchProductReviews(String slug) async {
    if (slug.isEmpty) return;
    try {
      isLoadingReviews.value = true;
      final res = await dioGet('catalog/products/$slug/reviews');
      if (res.statusCode == 200 && res.data != null) {
        final payload = res.data['data'] ?? res.data;
        if (payload is Map<String, dynamic>) {
          reviewsData.value = ProductReviewsResponse.fromJson(payload);
        } else if (payload is Map) {
          reviewsData.value = ProductReviewsResponse.fromJson(
            Map<String, dynamic>.from(payload),
          );
        }
      }
    } catch (_) {
      // Non-blocking for product display
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void scrollToReviews() {
    final ctx = reviewsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
