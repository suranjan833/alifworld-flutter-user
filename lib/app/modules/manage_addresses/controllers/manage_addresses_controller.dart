import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/models/address_model.dart';
import '../../../data/widgets/address_form_modal.dart';

export '../../../data/models/address_model.dart';

class ManageAddressesController extends GetxController
    with SkeletonLoadingMixin {
  final addresses = <AddressModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
    fetchAddresses();
  }

  /// 1. GET /addresses - List customer's saved addresses
  Future<void> fetchAddresses() async {
    isLoading.value = true;
    try {
      final response = await dioGet('addresses');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        List? addrList;
        if (rawData is Map<String, dynamic> &&
            rawData.containsKey('addresses')) {
          addrList = rawData['addresses'] as List?;
        } else if (rawData is List) {
          addrList = rawData;
        }

        if (addrList != null) {
          final list = <AddressModel>[];
          for (var item in addrList) {
            if (item is Map<String, dynamic>) {
              list.add(AddressModel.fromJson(item));
            }
          }
          addresses.assignAll(list);
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. POST /addresses/{id}/default - Mark address as default
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final res = await dioPost(
        endUrl: 'addresses/$addressId/default',
        data: {},
        isJson: true,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        for (var addr in addresses) {
          addr.isDefault = (addr.id == addressId);
        }
        addresses.refresh();
        Get.snackbar(
          'Default Address',
          'Default delivery address updated',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.textPrimary,
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {}
  }

  /// 3. DELETE /addresses/{id} - Remove address
  Future<void> deleteAddress(String addressId) async {
    try {
      final res = await dioDelete('addresses/$addressId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        addresses.removeWhere((addr) => addr.id == addressId);
        fetchAddresses(); // Re-fetch to ensure the promoted default is updated
        Get.snackbar(
          'Address Removed',
          'Address has been removed',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove address',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Connection error while removing address',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
    }
  }

  void confirmDeleteAddress(BuildContext context, String addressId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: AppColor.white,
        elevation: 10,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.trash,
                  color: const Color(0xFFDC2626),
                  size: 26.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Address?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to remove this delivery address?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.5.sp,
                  color: AppColor.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        deleteAddress(addressId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void openAddAddressSheet(BuildContext context) => openAddressSheet(context);

  /// Opens the 5-Level Bangladesh Delivery Hierarchy Address Form Modal
  void openAddressSheet(BuildContext context, {AddressModel? address}) {
    AddressFormModal.show(
      context,
      address: address,
      onSaved: (saved) {
        fetchAddresses();
      },
    );
  }
}
