import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';

class ShoppingListItem {
  final String id;
  final String title;
  bool isCompleted;

  ShoppingListItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class ShoppingListController extends GetxController
    with SkeletonLoadingMixin {
  final items = <ShoppingListItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
  }

  void toggleItem(int index) {
    items[index].isCompleted = !items[index].isCompleted;
    items.refresh();
  }

  void addItem(String title) {
    if (title.trim().isNotEmpty) {
      items.add(
        ShoppingListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.trim(),
        ),
      );
      Get.snackbar(
        'Added',
        'Item added to shopping list',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.textPrimary,
        colorText: AppColor.white,
      );
    }
  }

  void removeItem(int index) {
    items.removeAt(index);
  }
}
