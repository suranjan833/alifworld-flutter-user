import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../controllers/address_form_controller.dart';
import '../models/address_model.dart';
import 'address_form_fields.dart';

export '../controllers/address_form_controller.dart';

class AddressFormModal extends GetView<AddressFormController> {
  const AddressFormModal({super.key});

  static Future<void> show(
    BuildContext context, {
    AddressModel? address,
    required ValueChanged<AddressModel> onSaved,
  }) {
    final ctrl = Get.isRegistered<AddressFormController>()
        ? Get.find<AddressFormController>()
        : Get.put(AddressFormController());

    ctrl.init(address: address, onSaved: onSaved);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (ctx) => const AddressFormModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editingAddress != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        isEditing ? Iconsax.edit_2 : Iconsax.location_add,
                        color: AppColor.primaryDark,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      isEditing ? 'Edit Address' : 'Add New Address',
                      style: GoogleFonts.lato(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColor.textSecondary, size: 22.r),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient & Address Details',
                    style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                  ),
                  SizedBox(height: 10.h),
                  AddressTextInputField(
                    inputController: controller.nameController,
                    label: 'Full Name *',
                    hint: 'Mohan Biswas',
                    icon: Iconsax.user,
                  ),
                  SizedBox(height: 10.h),
                  AddressTextInputField(
                    inputController: controller.phoneController,
                    label: 'Phone Number (01XXXXXXXXX) *',
                    hint: '01700000000',
                    icon: Iconsax.call,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      BdPhoneInputFormatter(),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Select Region (Division › District › Upazila › Union › Area)',
                    style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                  ),
                  SizedBox(height: 10.h),
                  _buildSearchBox(),
                  SizedBox(height: 16.h),
                  _buildGeoDropdowns(),
                  SizedBox(height: 18.h),
                  AddressTextInputField(
                    inputController: controller.addressLineController,
                    label: 'Full Street Address (House, Road, Block) *',
                    hint: 'House 12, Road 5, Block C',
                    icon: Iconsax.home_2,
                    maxLines: 2,
                  ),
                  SizedBox(height: 10.h),
                  AddressTextInputField(
                    inputController: controller.postalCodeController,
                    label: 'Postal Code (Optional)',
                    hint: '1340',
                    icon: Iconsax.code,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildLabelChips(),
                  SizedBox(height: 14.h),
                  _buildDefaultCheckbox(),
                  SizedBox(height: 24.h),
                  _buildSaveButton(context, isEditing),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.search_normal_1, size: 16.r, color: AppColor.primaryDark),
              SizedBox(width: 6.w),
              Text(
                'Quick Area Search (1-Tap Fill)',
                style: GoogleFonts.lato(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColor.primaryDark),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final isSearching = controller.isSearching.value;
            final results = controller.searchResults;

            return Column(
              children: [
                TextFormField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  style: GoogleFonts.lato(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search e.g. Savar, সাভার, Banani, Uttara...',
                    hintStyle: GoogleFonts.lato(fontSize: 12.5.sp, color: AppColor.textHint),
                    filled: true,
                    fillColor: AppColor.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
                    suffixIcon: isSearching
                        ? Transform.scale(
                            scale: 0.5,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: AppColor.primaryDark),
                          )
                        : (controller.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  controller.searchController.clear();
                                  controller.searchResults.clear();
                                },
                              )
                            : null),
                  ),
                ),
                if (results.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    constraints: BoxConstraints(maxHeight: 180.h),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, idx) {
                        final hit = results[idx];
                        return InkWell(
                          onTap: () => controller.handleSearchResult(hit),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Icon(Iconsax.location, size: 14.r, color: AppColor.primary),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    hit.breadcrumb,
                                    style: GoogleFonts.lato(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGeoDropdowns() {
    return Obx(() {
      final selectedDiv = controller.selectedDivision.value;
      final selectedDist = controller.selectedDistrict.value;
      final selectedUpz = controller.selectedUpazila.value;
      final selectedUn = controller.selectedUnion.value;
      final selectedAr = controller.selectedArea.value;

      return Column(
        children: [
          AddressDropdownField(
            label: 'Division *',
            hint: 'Select Division',
            isLoading: controller.isLoadingDivisions.value,
            value: selectedDiv?.displayName,
            items: controller.divisions.map((d) => d.displayName).toList(),
            onChanged: (displayName) {
              final match = controller.divisions.firstWhereOrNull((d) => d.displayName == displayName);
              if (match != null) controller.onSelectDivision(match);
            },
          ),
          SizedBox(height: 10.h),
          AddressDropdownField(
            label: 'District *',
            hint: selectedDiv == null ? 'Select division first' : 'Select District',
            isLoading: controller.isLoadingDistricts.value,
            value: selectedDist?.displayName,
            items: controller.districts.map((d) => d.displayName).toList(),
            onChanged: selectedDiv == null
                ? null
                : (displayName) {
                    final match = controller.districts.firstWhereOrNull((d) => d.displayName == displayName);
                    if (match != null) controller.onSelectDistrict(match);
                  },
          ),
          SizedBox(height: 10.h),
          AddressDropdownField(
            label: 'Thana / Upazila / City Corporation *',
            hint: selectedDist == null ? 'Select district first' : 'Select Thana / Upazila / City Corporation',
            isLoading: controller.isLoadingUpazilas.value,
            value: selectedUpz?.displayName,
            items: controller.upazilas.map((u) => u.displayName).toList(),
            onChanged: selectedDist == null
                ? null
                : (displayName) {
                    final match = controller.upazilas.firstWhereOrNull((u) => u.displayName == displayName);
                    if (match != null) controller.onSelectUpazila(match);
                  },
          ),
          SizedBox(height: 10.h),
          AddressDropdownField(
            label: 'Union / Pourashava / Word *',
            hint: selectedUpz == null
                ? 'Select upazila first'
                : (controller.unions.isEmpty ? 'No unions for this area' : 'Select Union / Pourashava / Word'),
            isLoading: controller.isLoadingUnions.value,
            value: selectedUn?.displayName,
            items: controller.unions.map((u) => u.displayName).toList(),
            onChanged: (selectedUpz == null || controller.unions.isEmpty)
                ? null
                : (displayName) {
                    final match = controller.unions.firstWhereOrNull((u) => u.displayName == displayName);
                    if (match != null) controller.onSelectUnion(match);
                  },
          ),
          SizedBox(height: 10.h),
          AddressDropdownField(
            label: 'Area *',
            hint: selectedUn == null
                ? 'Select union first'
                : (controller.isLoadingAreas.value ? 'Loading areas...' : 'Select Area'),
            isLoading: controller.isLoadingAreas.value,
            value: selectedAr?.displayName,
            items: controller.areas.isNotEmpty
                ? controller.areas.map((a) => a.displayName).toList()
                : (selectedAr != null ? [selectedAr.displayName] : const []),
            onChanged: (selectedUn == null || controller.areas.isEmpty)
                ? null
                : (displayName) {
                    final match = controller.areas.firstWhereOrNull((a) => a.displayName == displayName);
                    if (match != null) controller.selectedArea.value = match;
                  },
          ),
        ],
      );
    });
  }

  Widget _buildLabelChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Label',
          style: GoogleFonts.lato(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
        ),
        SizedBox(height: 8.h),
        Obx(() {
          final selected = controller.selectedLabel.value;
          return Row(
            children: ['Home', 'Work', 'Other'].map((label) {
              final isSelected = selected == label;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => controller.selectedLabel.value = label,
                  selectedColor: AppColor.primaryLight,
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: GoogleFonts.lato(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColor.primaryDark : AppColor.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(color: isSelected ? AppColor.primaryDark : const Color(0xFFE2E8F0)),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildDefaultCheckbox() {
    return Obx(() {
      final isDef = controller.isDefault.value;
      return Row(
        children: [
          Checkbox(
            value: isDef,
            activeColor: AppColor.primary,
            onChanged: (val) => controller.isDefault.value = val ?? false,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.isDefault.value = !controller.isDefault.value,
              child: Text(
                'Set as default delivery address',
                style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSaveButton(BuildContext context, bool isEditing) {
    return Obx(() {
      final isSaving = controller.isSaving.value;
      return SizedBox(
        width: double.infinity,
        height: 48.h,
        child: ElevatedButton(
          onPressed: isSaving ? null : () => controller.saveAddress(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: isSaving
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: AppColor.white),
                )
              : Text(
                  isEditing ? 'Save Changes' : 'Save Address',
                  style: GoogleFonts.lato(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColor.white),
                ),
        ),
      );
    });
  }
}
