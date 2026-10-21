import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String type; // Home, Work, Other
  bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
    this.isDefault = false,
  });
}

class ManageAddressesController extends GetxController
    with SkeletonLoadingMixin {
  final addresses = <AddressModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
    fetchAddresses();
  }

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
              final street = item['addressLine']?.toString() ??
                  item['address']?.toString() ??
                  '';
              final upazila = item['upazila']?.toString() ?? '';
              final district = item['district']?.toString() ??
                  item['city']?.toString() ??
                  '';
              final division = item['division']?.toString() ?? '';

              final parts = [street, upazila, district, division]
                  .where((s) => s.trim().isNotEmpty)
                  .toList();
              final fullAddress = parts.isNotEmpty ? parts.join(', ') : street;

              list.add(
                AddressModel(
                  id: item['id']?.toString() ?? '',
                  name: item['fullName']?.toString() ??
                      item['recipientName']?.toString() ??
                      item['name']?.toString() ??
                      'Customer',
                  phone: item['phone']?.toString() ?? '',
                  street: fullAddress,
                  city: district,
                  state: division,
                  pincode: item['postalCode']?.toString() ?? '',
                  type: item['label']?.toString() ??
                      item['type']?.toString() ??
                      'Home',
                  isDefault: item['isDefault'] == true,
                ),
              );
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

  Future<void> setDefaultAddress(String addressId) async {
    try {
      final res = await dioPatch(
        endUrl: 'addresses/$addressId',
        data: {'isDefault': true},
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
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.textPrimary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {}
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      final res = await dioDelete('addresses/$addressId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        addresses.removeWhere((addr) => addr.id == addressId);
        Get.snackbar(
          'Address Removed',
          'Address has been removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.error,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Connection error while removing address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: Colors.white,
      );
    }
  }

  void openAddAddressSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final postalCodeCtrl = TextEditingController(text: '1205');
    final isSaving = false.obs;
    final selectedType = 'Home'.obs;

    final divisions = <Map<String, dynamic>>[].obs;
    final districts = <Map<String, dynamic>>[].obs;
    final upazilas = <Map<String, dynamic>>[].obs;
    final selectedDivisionId = Rxn<String>();
    final selectedDistrictId = Rxn<String>();
    final selectedUpazilaId = Rxn<String>();
    final isLoadingDivisions = false.obs;
    final isLoadingDistricts = false.obs;
    final isLoadingUpazilas = false.obs;

    Future<void> loadUpazilas(String distId) async {
      isLoadingUpazilas.value = true;
      upazilas.clear();
      selectedUpazilaId.value = null;
      try {
        final res = await dioGet('geo/upazilas?districtId=$distId');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          if (data is Map && data['upazilas'] is List) {
            final list = List<Map<String, dynamic>>.from(data['upazilas']);
            upazilas.assignAll(list);
            if (list.isNotEmpty) {
              selectedUpazilaId.value = list.first['id']?.toString();
            }
          }
        }
      } catch (_) {}
      isLoadingUpazilas.value = false;
    }

    Future<void> loadDistricts(String divId) async {
      isLoadingDistricts.value = true;
      districts.clear();
      upazilas.clear();
      selectedDistrictId.value = null;
      selectedUpazilaId.value = null;
      try {
        final res = await dioGet('geo/districts?divisionId=$divId');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          if (data is Map && data['districts'] is List) {
            final list = List<Map<String, dynamic>>.from(data['districts']);
            districts.assignAll(list);
            if (list.isNotEmpty) {
              final defaultDist = list.firstWhere(
                (d) => d['name']?.toString().toLowerCase() == 'dhaka',
                orElse: () => list.first,
              );
              selectedDistrictId.value = defaultDist['id']?.toString();
              await loadUpazilas(defaultDist['id'].toString());
            }
          }
        }
      } catch (_) {}
      isLoadingDistricts.value = false;
    }

    Future<void> loadDivisions() async {
      isLoadingDivisions.value = true;
      try {
        final res = await dioGet('geo/divisions');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          if (data is Map && data['divisions'] is List) {
            final list = List<Map<String, dynamic>>.from(data['divisions']);
            divisions.assignAll(list);
            if (list.isNotEmpty) {
              final defaultDiv = list.firstWhere(
                (d) => d['name']?.toString().toLowerCase() == 'dhaka',
                orElse: () => list.first,
              );
              selectedDivisionId.value = defaultDiv['id']?.toString();
              await loadDistricts(defaultDiv['id'].toString());
            }
          }
        }
      } catch (_) {}
      isLoadingDivisions.value = false;
    }

    loadDivisions();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Add New Address',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),

                // Address Type Selector
                Obx(
                  () => Row(
                    children: ['Home', 'Work', 'Other'].map((type) {
                      final isSel = selectedType.value == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: (val) => selectedType.value = type,
                          selectedColor: AppColor.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.lato(
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel
                                ? AppColor.textPrimary
                                : AppColor.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 14.h),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (e.g. 017xxxxxxxx) *',
                    hintText: '01XXXXXXXXX',
                  ),
                ),
                SizedBox(height: 10.h),

                // Division Dropdown
                Obx(() {
                  if (isLoadingDivisions.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedDivisionId.value,
                    decoration: InputDecoration(
                      labelText: 'Division *',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: divisions.map((d) {
                      final name = d['name']?.toString() ?? '';
                      final bnName = d['bnName']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: d['id']?.toString(),
                        child: Text(
                          bnName.isNotEmpty ? '$name ($bnName)' : name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedDivisionId.value = val;
                        loadDistricts(val);
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                // District Dropdown
                Obx(() {
                  if (isLoadingDistricts.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedDistrictId.value,
                    decoration: InputDecoration(
                      labelText: 'District *',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: districts.map((d) {
                      final name = d['name']?.toString() ?? '';
                      final bnName = d['bnName']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: d['id']?.toString(),
                        child: Text(
                          bnName.isNotEmpty ? '$name ($bnName)' : name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedDistrictId.value = val;
                        loadUpazilas(val);
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                // Upazila Dropdown
                Obx(() {
                  if (isLoadingUpazilas.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedUpazilaId.value,
                    decoration: InputDecoration(
                      labelText: 'Upazila / Area *',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: upazilas.map((u) {
                      final name = u['name']?.toString() ?? '';
                      final bnName = u['bnName']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: u['id']?.toString(),
                        child: Text(
                          bnName.isNotEmpty ? '$name ($bnName)' : name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedUpazilaId.value = val;
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'House / Road / Flat / Area Details *',
                  ),
                ),
                SizedBox(height: 10.h),

                TextField(
                  controller: postalCodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code (e.g. 1205)',
                  ),
                ),
                SizedBox(height: 24.h),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isSaving.value
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final rawPhone = phoneCtrl.text.trim();
                              final street = streetCtrl.text.trim();
                              final postal =
                                  postalCodeCtrl.text.trim().isNotEmpty
                                      ? postalCodeCtrl.text.trim()
                                      : '1000';

                              if (name.isEmpty ||
                                  rawPhone.isEmpty ||
                                  street.isEmpty) {
                                Get.snackbar(
                                  'Missing Information',
                                  'Please fill in all required fields',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              var phone = rawPhone.replaceAll(
                                  RegExp(r'[\s\-\(\)]'), '');
                              if (phone.startsWith('+880')) {
                                phone = phone.substring(3);
                              } else if (phone.startsWith('880')) {
                                phone = phone.substring(2);
                              } else if (phone.length == 10 &&
                                  phone.startsWith('1')) {
                                phone = '0$phone';
                              }

                              if (!RegExp(r'^01[3-9]\d{8}$')
                                  .hasMatch(phone)) {
                                Get.snackbar(
                                  'Invalid Phone Number',
                                  'Please enter a valid 11-digit mobile number (01XXXXXXXXX)',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              final divItem = divisions.firstWhere(
                                (d) =>
                                    d['id']?.toString() ==
                                    selectedDivisionId.value,
                                orElse: () => {},
                              );
                              final distItem = districts.firstWhere(
                                (d) =>
                                    d['id']?.toString() ==
                                    selectedDistrictId.value,
                                orElse: () => {},
                              );
                              final upazilaItem = upazilas.firstWhere(
                                (u) =>
                                    u['id']?.toString() ==
                                    selectedUpazilaId.value,
                                orElse: () => {},
                              );

                              final divName =
                                  divItem['name']?.toString() ?? '';
                              final distName =
                                  distItem['name']?.toString() ?? '';
                              final upazilaName =
                                  upazilaItem['name']?.toString() ?? '';

                              if (divName.isEmpty ||
                                  distName.isEmpty ||
                                  upazilaName.isEmpty) {
                                Get.snackbar(
                                  'Location Required',
                                  'Please select Division, District, and Upazila',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              isSaving.value = true;
                              try {
                                final res = await dioPost(
                                  endUrl: 'addresses',
                                  data: {
                                    'label': selectedType.value,
                                    'fullName': name,
                                    'phone': phone,
                                    'addressLine': street,
                                    'division': divName,
                                    'district': distName,
                                    'upazila': upazilaName,
                                    'postalCode': postal,
                                    'isDefault': addresses.isEmpty,
                                  },
                                  isJson: true,
                                );
                                isSaving.value = false;

                                if (res.statusCode == 200 ||
                                    res.statusCode == 201) {
                                  Get.back();
                                  await fetchAddresses();
                                  Get.snackbar(
                                    'Success',
                                    'Address added successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        const Color(0xFF16A34A),
                                    colorText: Colors.white,
                                  );
                                } else {
                                  String errMsg = 'Failed to save address';
                                  if (res.data is Map) {
                                    final d = res.data as Map;
                                    if (d['error'] is Map &&
                                        d['error']['message'] != null) {
                                      errMsg =
                                          d['error']['message'].toString();
                                    } else if (d['message'] != null) {
                                      errMsg = d['message'].toString();
                                    }
                                  }
                                  Get.snackbar(
                                    'Unable to Save Address',
                                    errMsg,
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColor.error,
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (_) {
                                isSaving.value = false;
                                Get.snackbar(
                                  'Error',
                                  'Connection error while saving address',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Address',
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
