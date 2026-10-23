import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../account/views/account_view.dart';
import '../../bag/controllers/bag_controller.dart';
import '../../bag/views/bag_view.dart';
import '../../categories/views/categories_view.dart';
import '../../discover/views/discover_view.dart';
import '../../home/views/home_view.dart';
import '../bindings/main_navigation_binding.dart';
import '../controllers/main_navigation_controller.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  MainNavigationController get controller {
    if (!Get.isRegistered<MainNavigationController>()) {
      MainNavigationBinding().dependencies();
    }
    return Get.find<MainNavigationController>();
  }

  static const List<Widget> _views = [
    HomeView(),
    CategoriesView(),
    DiscoverView(),
    BagView(),
    AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: _views,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColor.background,
          border: Border(
            top: BorderSide(color: AppColor.border, width: 1.w),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  activeIcon: Iconsax.home_15,
                  inactiveIcon: Iconsax.home,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Categories',
                  activeIcon: Iconsax.box_1,
                  inactiveIcon: Iconsax.box_1,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Discover',
                  activeIcon: Iconsax.video_square,
                  inactiveIcon: Iconsax.video_square,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Bag',
                  activeIcon: Iconsax.shopping_bag,
                  inactiveIcon: Iconsax.shopping_bag,
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Account',
                  activeIcon: Iconsax.user,
                  inactiveIcon: Iconsax.user,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final activeColor = AppColor.textPrimary;
      final inactiveColor = AppColor.textSecondary;

      Widget iconWidget = Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected ? activeColor : inactiveColor,
        size: 24.r,
      );

      // If Bag tab (index 3), show live cart count badge
      if (index == 3) {
        if (!Get.isRegistered<BagController>()) {
          Get.put(BagController());
        }
        final bagCtrl = Get.find<BagController>();
        final count = bagCtrl.totalItemCount;

        if (count > 0) {
          iconWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                top: -5.h,
                right: -8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? 4.5.w : 5.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A00),
                    shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: count > 9 ? BorderRadius.circular(10.r) : null,
                    border: Border.all(color: AppColor.white, width: 1.5.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5A00).withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.r,
                    minHeight: 16.r,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      }

      return Expanded(
        child: InkWell(
          onTap: () => controller.changeTab(index),
          splashColor: AppColor.transparent,
          highlightColor: AppColor.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
