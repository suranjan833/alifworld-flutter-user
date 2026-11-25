import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../models/order_model.dart';
import 'my_orders_controller.dart';

class OrderDetailsController extends GetxController {
  final orderRx = OrderModel.placeholder().obs;
  final isLoading = false.obs;
  final isCancelling = false.obs;

  final reviewedProductIds = <String>{}.obs;
  final reviewRating = 5.obs;
  final isSubmittingReview = false.obs;
  final reviewLocalImages = <String>[].obs;
  final reviewTitleController = TextEditingController();
  final reviewBodyController = TextEditingController();
  final imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    initOrder();
  }

  void initOrder({OrderModel? explicitOrder}) {
    OrderModel initialOrder;
    if (explicitOrder != null) {
      initialOrder = explicitOrder;
    } else if (Get.arguments is OrderModel) {
      initialOrder = Get.arguments as OrderModel;
    } else if (Get.arguments is Map<String, dynamic>) {
      initialOrder = OrderModel.fromJson(Get.arguments as Map<String, dynamic>);
    } else if (Get.arguments is String) {
      initialOrder = OrderModel.placeholder(id: Get.arguments as String);
    } else if (Get.parameters['id'] != null) {
      initialOrder = OrderModel.placeholder(id: Get.parameters['id']!);
    } else {
      initialOrder = OrderModel.placeholder();
    }

    orderRx.value = initialOrder;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncLatestOrderDetails();
    });
  }

  Future<void> syncLatestOrderDetails() async {
    final cur = orderRx.value;
    final lookupId = cur.id.isNotEmpty ? cur.id : cur.orderId;
    if (lookupId.isEmpty || lookupId == '#ALF-PENDING') return;

    if (cur.items.isEmpty) {
      isLoading.value = true;
    }

    if (!Get.isRegistered<MyOrdersController>()) {
      Get.put(MyOrdersController());
    }

    try {
      final fresh =
          await Get.find<MyOrdersController>().fetchOrderDetails(lookupId);
      if (fresh != null) {
        orderRx.value = fresh;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String lookupId, {String? reason}) async {
    if (!Get.isRegistered<MyOrdersController>()) {
      Get.put(MyOrdersController());
    }
    isCancelling.value = true;
    try {
      final success = await Get.find<MyOrdersController>()
          .cancelOrder(lookupId, reason: reason ?? '');
      if (success) {
        orderRx.value = orderRx.value.copyWith(
          status: 'Cancelled',
          backendStatus: 'cancelled',
        );
      }
      return success;
    } finally {
      isCancelling.value = false;
    }
  }

  void prepareReview(OrderItemModel item) {
    reviewRating.value = 5;
    reviewTitleController.clear();
    reviewBodyController.clear();
    reviewLocalImages.clear();
    isSubmittingReview.value = false;
  }

  Future<void> pickReviewImages() async {
    if (reviewLocalImages.length >= 5) {
      Get.snackbar(
        'Limit Reached',
        'You can upload a maximum of 5 images.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 75,
      );
      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - reviewLocalImages.length;
        final toAdd = pickedFiles.take(remainingSlots).map((x) => x.path);
        reviewLocalImages.addAll(toAdd);
      }
    } catch (_) {}
  }

  void removeReviewImage(int index) {
    if (index >= 0 && index < reviewLocalImages.length) {
      reviewLocalImages.removeAt(index);
    }
  }

  Future<String?> _uploadSingleImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final fileName = filePath.split(Platform.pathSeparator).last;
      final multipart =
          await dio.MultipartFile.fromFile(filePath, filename: fileName);
      final res = await dioPost(
        endUrl: 'account/uploads',
        data: {'file': multipart, 'kind': 'review'},
        isJson: false,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final resData = res.data is Map ? res.data : {};
        final url = resData['url'] ??
            (resData['data'] is Map ? resData['data']['url'] : null);
        if (url != null) return url.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> submitProductReview({required String productId}) async {
    if (productId.trim().isEmpty) return false;
    isSubmittingReview.value = true;
    try {
      final uploadedUrls = <String>[];
      for (final path in reviewLocalImages) {
        final url = await _uploadSingleImage(path);
        if (url != null) uploadedUrls.add(url);
      }

      final payload = <String, dynamic>{
        'productId': productId.trim(),
        'rating': reviewRating.value,
        if (reviewTitleController.text.trim().isNotEmpty)
          'title': reviewTitleController.text.trim(),
        if (reviewBodyController.text.trim().isNotEmpty)
          'body': reviewBodyController.text.trim(),
        if (uploadedUrls.isNotEmpty) 'photos': uploadedUrls,
      };

      final response = await dioPost(
        endUrl: 'account/reviews',
        data: payload,
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        reviewedProductIds.add(productId.trim());
        Get.back();
        Get.snackbar(
          'Success',
          'Thank you! Your review has been submitted for approval.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF16A34A),
          colorText: Colors.white,
        );
        return true;
      } else {
        final msg =
            response.data is Map ? response.data['message']?.toString() : null;
        Get.snackbar(
          'Notice',
          msg ?? 'Failed to submit review. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to submit review. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
    } finally {
      isSubmittingReview.value = false;
    }
    return false;
  }

  bool isItemReviewed(OrderItemModel item) {
    return item.isReviewed ||
        (item.productId.isNotEmpty &&
            reviewedProductIds.contains(item.productId));
  }

  @override
  void onClose() {
    reviewTitleController.dispose();
    reviewBodyController.dispose();
    super.onClose();
  }
}
