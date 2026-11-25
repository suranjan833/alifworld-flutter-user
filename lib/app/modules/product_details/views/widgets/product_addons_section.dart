import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/config/app_color.dart';
import '../../controllers/product_details_controller.dart';
import '../../models/variant_addon_model.dart';

class ProductAddonsSection extends GetView<ProductDetailsController> {
  const ProductAddonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final variant = controller.selectedVariant;
      if (variant == null || variant.addons.isEmpty) {
        return const SizedBox.shrink();
      }

      final sortedAddons = List<VariantAddonModel>.from(variant.addons)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return Container(
        width: double.infinity,
        color: AppColor.white,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add-ons',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '(Optional extras)',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            ...sortedAddons.map((addon) {
              return Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: _buildAddonItem(addon),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildAddonItem(VariantAddonModel addon) {
    switch (addon.type.toLowerCase()) {
      case 'dropdown':
        return _buildDropdownAddon(addon);
      case 'checkbox':
        return _buildCheckboxAddon(addon);
      case 'radio':
        return _buildRadioAddon(addon);
      case 'multi_select':
        return _buildMultiSelectAddon(addon);
      default:
        return _buildCheckboxAddon(addon);
    }
  }

  Widget _buildDropdownAddon(VariantAddonModel addon) {
    return Obx(() {
      final currentVal = controller.addonSelections[addon.id] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            addon.name,
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: currentVal,
                hint: Text(
                  'None',
                  style: GoogleFonts.lato(
                    fontSize: 13.5.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColor.textSecondary,
                  size: 20.r,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'None',
                      style: GoogleFonts.lato(fontSize: 13.5.sp),
                    ),
                  ),
                  ...addon.options.map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.label,
                      child: Text(
                        '${opt.label} — ৳${opt.priceMajor.toStringAsFixed(0)}',
                        style: GoogleFonts.lato(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == null || val.isEmpty) {
                    controller.addonSelections.remove(addon.id);
                  } else {
                    controller.addonSelections[addon.id] = val;
                  }
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCheckboxAddon(VariantAddonModel addon) {
    return Obx(() {
      final isChecked = controller.addonSelections[addon.id] == true;

      return InkWell(
        onTap: () {
          if (isChecked) {
            controller.addonSelections.remove(addon.id);
          } else {
            controller.addonSelections[addon.id] = true;
          }
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color:
                isChecked ? const Color(0xFFFFF7ED) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isChecked ? AppColor.primary : const Color(0xFFE2E8F0),
              width: isChecked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18.r,
                height: 18.r,
                decoration: BoxDecoration(
                  color: isChecked ? AppColor.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color:
                        isChecked ? AppColor.primary : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? Icon(Icons.check, size: 14.r, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  addon.name,
                  style: GoogleFonts.lato(
                    fontSize: 13.5.sp,
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                    color:
                        isChecked ? AppColor.primaryDark : AppColor.textPrimary,
                  ),
                ),
              ),
              Text(
                '+৳${addon.priceMajor.toStringAsFixed(0)}',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color:
                      isChecked ? AppColor.primary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRadioAddon(VariantAddonModel addon) {
    return Obx(() {
      final selectedOpt = controller.addonSelections[addon.id] as String?;

      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.name,
              style: GoogleFonts.lato(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            _buildRadioOptionRow(
              label: 'None',
              priceText: null,
              isSelected: selectedOpt == null,
              onTap: () => controller.addonSelections.remove(addon.id),
            ),
            ...addon.options.map((opt) {
              final isSelected = selectedOpt == opt.label;
              return _buildRadioOptionRow(
                label: opt.label,
                priceText: '+৳${opt.priceMajor.toStringAsFixed(0)}',
                isSelected: isSelected,
                onTap: () {
                  controller.addonSelections[addon.id] = opt.label;
                },
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildRadioOptionRow({
    required String label,
    required String? priceText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColor.primary : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 9.r,
                        height: 9.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColor.primaryDark
                      : AppColor.textPrimary,
                ),
              ),
            ),
            if (priceText != null)
              Text(
                priceText,
                style: GoogleFonts.lato(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColor.primary
                      : const Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectAddon(VariantAddonModel addon) {
    return Obx(() {
      final currentVal = controller.addonSelections[addon.id];
      final chosen = (currentVal is List)
          ? List<String>.from(currentVal)
          : <String>[];

      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.name,
              style: GoogleFonts.lato(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            ...addon.options.map((opt) {
              final isSelected = chosen.contains(opt.label);

              return _buildCheckboxOptionRow(
                label: opt.label,
                priceText: '+৳${opt.priceMajor.toStringAsFixed(0)}',
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    chosen.remove(opt.label);
                  } else {
                    chosen.add(opt.label);
                  }
                  if (chosen.isEmpty) {
                    controller.addonSelections.remove(addon.id);
                  } else {
                    controller.addonSelections[addon.id] =
                        List<String>.from(chosen);
                  }
                },
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildCheckboxOptionRow({
    required String label,
    required String? priceText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                color: isSelected ? AppColor.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color:
                      isSelected ? AppColor.primary : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.r, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColor.primaryDark
                      : AppColor.textPrimary,
                ),
              ),
            ),
            if (priceText != null)
              Text(
                priceText,
                style: GoogleFonts.lato(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColor.primary
                      : const Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
