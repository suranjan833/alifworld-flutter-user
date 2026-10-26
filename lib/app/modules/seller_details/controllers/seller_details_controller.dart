import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../routes/app_pages.dart';
import '../../home/models/showcase_model.dart';

class SellerDetailsController extends GetxController {
  final seller = <String, dynamic>{}.obs;
  final isFollowing = false.obs;
  final sellerProducts = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      seller.value = Map<String, dynamic>.from(args);
    } else {
      seller.value = {
        'name': 'Alif Store',
        'rating': 4.9,
        'reviewsCount': '1.8k',
        'joinedDate': 'Member since 2024',
        'location': 'Dhaka, Bangladesh',
        'responseRate': '99%',
        'isVerified': true,
        'avatar':
            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
        'bio':
            'Official verified seller offering authentic products on Alif.',
      };
    }
    fetchSellerProducts();
  }

  Future<void> fetchSellerProducts() async {
    isLoading.value = true;
    try {
      final res = await dioGet('catalog/search');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is List) {
          final list = <Map<String, dynamic>>[];
          for (var p in raw) {
            if (p is Map<String, dynamic>) {
              final prod = ShowcaseProductModel.fromJson(p);
              list.add(prod.toDetailsMap());
            }
          }
          sellerProducts.assignAll(list);
        } else {
          sellerProducts.clear();
        }
      } else {
        sellerProducts.clear();
      }
    } catch (_) {
      sellerProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFollow() {
    isFollowing.value = !isFollowing.value;
    Get.snackbar(
      isFollowing.value ? 'Following Store' : 'Unfollowed Store',
      isFollowing.value
          ? 'You are now following ${seller['name']}'
          : 'You unfollowed ${seller['name']}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.textPrimary,
      colorText: AppColor.white,
      duration: const Duration(seconds: 2),
    );
  }

  void openProductDetails(Map<String, dynamic> product) {
    Get.toNamed(Routes.PRODUCT_DETAILS, arguments: product);
  }
}
