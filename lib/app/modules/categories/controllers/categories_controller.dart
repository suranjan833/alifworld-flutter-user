import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../models/category_model.dart';

class CategoriesController extends GetxController {
  final categories = <CategoryModel>[].obs;
  final isLoading = true.obs;

  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  /// API Function code placed directly in Controller
  Future<void> _loadCategories() async {
    isLoading.value = true;
    try {
      final response = await dioGet('catalog/categories');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? categoryList;
        if (rawData is Map<String, dynamic> && rawData.containsKey('categories')) {
          categoryList = rawData['categories'] as List?;
        } else if (rawData is List) {
          categoryList = rawData;
        }

        if (categoryList != null && categoryList.isNotEmpty) {
          final pastelColors = [
            const Color(0xFFE8EDF5),
            const Color(0xFFFDF0DC),
            const Color(0xFFE9E2F7),
            const Color(0xFFFCE1E7),
            const Color(0xFFDFF2EA),
            const Color(0xFFDDEBFA),
            const Color(0xFFFCE8D8),
            const Color(0xFFEAE6DC),
            const Color(0xFFE0F0F5),
            const Color(0xFFF4E4DC),
          ];

          final parsed = <CategoryModel>[];
          for (int i = 0; i < categoryList.length; i++) {
            final item = categoryList[i];
            if (item is Map<String, dynamic>) {
              final cat = CategoryModel.fromJson(item);
              parsed.add(CategoryModel(
                id: cat.id,
                name: cat.name,
                slug: cat.slug,
                description: cat.description,
                image: cat.image,
                icon: cat.icon,
                parentId: cat.parentId,
                count: cat.count,
                accent: pastelColors[i % pastelColors.length],
                children: cat.children,
              ));
            }
          }
          categories.assignAll(parsed);
        } else {
          categories.clear();
        }
      } else {
        categories.clear();
      }
    } catch (_) {
      categories.clear();
    } finally {
      isLoading.value = false;
      _hasLoadedOnce = true;
    }
  }

  Future<void> refreshCategories() async {
    await _loadCategories();
  }

  bool get hasLoadedOnce => _hasLoadedOnce;
}
