import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../models/country_model.dart';

class CountryPickerController extends GetxController {
  final searchController = TextEditingController();
  final filteredCountries = CountryModel.defaultCountries.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      filteredCountries.value = CountryModel.defaultCountries;
    } else {
      filteredCountries.value = CountryModel.defaultCountries.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.dialCode.contains(query) ||
            c.code.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }
}

class CountryPickerDialog extends GetView<CountryPickerController> {
  final CountryModel selectedCountry;
  final ValueChanged<CountryModel> onSelect;

  const CountryPickerDialog({
    super.key,
    required this.selectedCountry,
    required this.onSelect,
  });

  static void show(
    BuildContext context,
    CountryModel current,
    ValueChanged<CountryModel> onSelect,
  ) {
    if (!Get.isRegistered<CountryPickerController>()) {
      Get.put(CountryPickerController());
    } else {
      Get.find<CountryPickerController>().searchController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CountryPickerDialog(selectedCountry: current, onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 0.70.sh,
        child: Column(
          children: [
            // Top Drag Handle
            SizedBox(height: 10.h),
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),

            // Dialog Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Country',
                    style: GoogleFonts.lato(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(4.r),
                    icon: Icon(
                      Icons.close,
                      color: AppColor.textSecondary,
                      size: 20.r,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: TextField(
                controller: controller.searchController,
                style: GoogleFonts.lato(
                  fontSize: 14.sp,
                  color: AppColor.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country or dial code...',
                  hintStyle: GoogleFonts.lato(
                    color: AppColor.textHint,
                    fontSize: 13.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColor.textSecondary,
                    size: 18.r,
                  ),
                  filled: true,
                  fillColor: AppColor.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColor.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Reactive Country List
            Expanded(
              child: Obx(() {
                final list = controller.filteredCountries;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No countries found',
                      style: GoogleFonts.lato(
                        color: AppColor.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: AppColor.divider, height: 1.h),
                  itemBuilder: (context, index) {
                    final country = list[index];
                    final isSelected = selectedCountry.code == country.code;

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                        onTap: () {
                          onSelect(country);
                          Get.back();
                        },
                        leading: Text(
                          country.flag,
                          style: TextStyle(fontSize: 22.sp),
                        ),
                        title: Text(
                          country.name,
                          style: GoogleFonts.lato(
                            fontSize: 14.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColor.primary
                                : AppColor.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country.dialCode,
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.check_circle,
                                color: AppColor.primary,
                                size: 16.r,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
