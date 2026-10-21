import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/shopping_list_controller.dart';

class ShoppingListView extends GetView<ShoppingListController> {
  const ShoppingListView({super.key});

  @override
  Widget build(BuildContext context) {
    final textCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColor.textPrimary,
            size: 24.r,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Shopping List',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: const SkeletonList(itemCount: 4),
              )
            : Column(
        children: [
          // Input row
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add new item to list...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                ElevatedButton(
                  onPressed: () {
                    controller.addItem(textCtrl.text);
                    textCtrl.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isCompleted,
                          activeColor: AppColor.primary,
                          checkColor: Colors.black,
                          onChanged: (val) => controller.toggleItem(index),
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: item.isCompleted
                                ? AppColor.textHint
                                : AppColor.textPrimary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Iconsax.trash,
                            size: 18.r,
                            color: AppColor.error,
                          ),
                          onPressed: () => controller.removeItem(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }
}
