import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../routes/app_pages.dart';
import '../../home/models/showcase_model.dart';

class TopBrandsController extends GetxController with SkeletonLoadingMixin {
  final allBrands = <BrandModel>[].obs;
  final filteredBrands = <BrandModel>[].obs;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;



  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchBrands();
    });
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text.trim();
    _applyFilter();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilter();
  }

  void _applyFilter() {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      filteredBrands.assignAll(allBrands);
    } else {
      filteredBrands.assignAll(
        allBrands.where((brand) => brand.name.toLowerCase().contains(query)),
      );
    }
  }

  /// GET /catalog/brands
  Future<void> fetchBrands() async {
    initSkeletonLoading();
    try {
      final response = await dioGet('catalog/brands');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        List? brandList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('brands')) {
          brandList = rawData['brands'] as List?;
        } else if (rawData is List) {
          brandList = rawData;
        }

        if (brandList != null && brandList.isNotEmpty) {
          final parsed = <BrandModel>[];
          for (var item in brandList) {
            if (item is Map<String, dynamic>) {
              parsed.add(BrandModel.fromJson(item));
            }
          }
          allBrands.assignAll(parsed);
          _applyFilter();
          return;
        }
      }
      allBrands.clear();
      _applyFilter();
    } catch (_) {
      allBrands.clear();
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onBrandTap(BrandModel brand) {
    Get.toNamed(
      Routes.CATEGORY_PRODUCTS,
      arguments: {
        'name': brand.name,
        'brand': brand.name,
        'slug': brand.slug,
        'brandSlug': brand.slug,
        'image': brand.fullLogoUrl,
      },
    );
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }
}
