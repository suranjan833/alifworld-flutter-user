import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String area;
  final String zone;
  final String pincode;
  final String type; // Home, Work, Other
  bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    this.state = '',
    this.area = '',
    this.zone = '',
    required this.pincode,
    required this.type,
    this.isDefault = false,
  });

  String get formattedAddress {
    final parts = [street, area, zone, city, state]
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    final base = parts.isNotEmpty ? parts.join(', ') : street;
    if (pincode.isNotEmpty) {
      return '$base - $pincode';
    }
    return base;
  }
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
              final area = item['area']?.toString() ??
                  item['upazila']?.toString() ??
                  '';
              final zone = item['zone']?.toString() ?? '';
              final city = item['city']?.toString() ??
                  item['district']?.toString() ??
                  '';
              final division = item['division']?.toString() ?? '';

              final parts = [street, area, zone, city, division]
                  .where((s) => s.trim().isNotEmpty)
                  .toSet()
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
                  street: street.isNotEmpty ? street : fullAddress,
                  area: area,
                  zone: zone,
                  city: city.isNotEmpty ? city : zone,
                  state: division.isNotEmpty
                      ? division
                      : (zone.isNotEmpty ? zone : city),
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
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.textPrimary,
          colorText: AppColor.white,
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
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Connection error while removing address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
    }
  }

  void confirmDeleteAddress(BuildContext context, String addressId) {
    Get.defaultDialog(
      title: 'Delete Address',
      titleStyle: GoogleFonts.lato(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.textPrimary,
      ),
      middleText: 'Are you sure you want to remove this delivery address?',
      middleTextStyle: GoogleFonts.lato(
        fontSize: 14.sp,
        color: AppColor.textSecondary,
      ),
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: AppColor.white,
      buttonColor: AppColor.error,
      cancelTextColor: AppColor.textPrimary,
      onConfirm: () {
        Get.back();
        deleteAddress(addressId);
      },
    );
  }

  void openAddAddressSheet(BuildContext context) => openAddressSheet(context);

  void openAddressSheet(BuildContext context, {AddressModel? address}) {
    final isEditing = address != null;
    final nameCtrl = TextEditingController(text: isEditing ? address.name : '');
    final phoneCtrl =
        TextEditingController(text: isEditing ? address.phone : '');
    final streetCtrl =
        TextEditingController(text: isEditing ? address.street : '');
    final postalCodeCtrl =
        TextEditingController(text: isEditing ? address.pincode : '');
    final searchCtrl = TextEditingController();
    final isSaving = false.obs;
    final isSearching = false.obs;
    final selectedType = (isEditing ? address.type : 'Home').obs;

    // Pathao 3-level Geo state: City -> Zone -> Area
    final cities = <Map<String, dynamic>>[].obs;
    final zones = <Map<String, dynamic>>[].obs;
    final areas = <Map<String, dynamic>>[].obs;
    final searchResults = <Map<String, dynamic>>[].obs;

    final selectedCityId = Rxn<String>();
    final selectedZoneId = Rxn<String>();
    final selectedAreaId = Rxn<String>();

    final isLoadingCities = false.obs;
    final isLoadingZones = false.obs;
    final isLoadingAreas = false.obs;

    Future<void> loadAreas(String zoneId,
        {String? targetAreaId, String? targetAreaName}) async {
      isLoadingAreas.value = true;
      areas.clear();
      selectedAreaId.value = null;
      try {
        final res = await dioGet('geo/areas?zoneId=$zoneId');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final rawList = (data is Map && data['areas'] is List)
              ? data['areas'] as List
              : (res.data is Map && res.data['areas'] is List)
                  ? res.data['areas'] as List
                  : null;
          if (rawList != null) {
            final list = List<Map<String, dynamic>>.from(rawList);
            areas.assignAll(list);
            if (targetAreaId != null &&
                list.any((a) => a['id']?.toString() == targetAreaId)) {
              selectedAreaId.value = targetAreaId;
            } else if (targetAreaName != null &&
                targetAreaName.isNotEmpty &&
                list.any((a) =>
                    a['name']?.toString().toLowerCase().trim() ==
                    targetAreaName.toLowerCase().trim())) {
              final match = list.firstWhere((a) =>
                  a['name']?.toString().toLowerCase().trim() ==
                  targetAreaName.toLowerCase().trim());
              selectedAreaId.value = match['id']?.toString();
            } else if (list.isNotEmpty) {
              selectedAreaId.value = list.first['id']?.toString();
            }
          }
        }
      } catch (_) {}
      isLoadingAreas.value = false;
    }

    Future<void> loadZones(String cityId,
        {String? targetZoneId,
        String? targetZoneName,
        String? targetAreaId,
        String? targetAreaName}) async {
      isLoadingZones.value = true;
      zones.clear();
      areas.clear();
      selectedZoneId.value = null;
      selectedAreaId.value = null;
      try {
        final res = await dioGet('geo/zones?cityId=$cityId');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final rawList = (data is Map && data['zones'] is List)
              ? data['zones'] as List
              : (res.data is Map && res.data['zones'] is List)
                  ? res.data['zones'] as List
                  : null;
          if (rawList != null) {
            final list = List<Map<String, dynamic>>.from(rawList);
            zones.assignAll(list);
            if (targetZoneId != null &&
                list.any((z) => z['id']?.toString() == targetZoneId)) {
              selectedZoneId.value = targetZoneId;
              await loadAreas(targetZoneId,
                  targetAreaId: targetAreaId, targetAreaName: targetAreaName);
            } else if (targetZoneName != null &&
                targetZoneName.isNotEmpty &&
                list.any((z) =>
                    z['name']?.toString().toLowerCase().trim() ==
                    targetZoneName.toLowerCase().trim())) {
              final match = list.firstWhere((z) =>
                  z['name']?.toString().toLowerCase().trim() ==
                  targetZoneName.toLowerCase().trim());
              selectedZoneId.value = match['id']?.toString();
              await loadAreas(match['id'].toString(),
                  targetAreaId: targetAreaId, targetAreaName: targetAreaName);
            } else if (list.isNotEmpty) {
              selectedZoneId.value = list.first['id']?.toString();
              await loadAreas(list.first['id'].toString());
            }
          }
        }
      } catch (_) {}
      isLoadingZones.value = false;
    }

    Future<void> loadCities() async {
      isLoadingCities.value = true;
      try {
        final res = await dioGet('geo/cities');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final rawList = (data is Map && data['cities'] is List)
              ? data['cities'] as List
              : (res.data is Map && res.data['cities'] is List)
                  ? res.data['cities'] as List
                  : null;
          if (rawList != null) {
            final list = List<Map<String, dynamic>>.from(rawList);
            cities.assignAll(list);
            if (list.isNotEmpty) {
              Map<String, dynamic>? selectedCity;
              if (isEditing && address.city.isNotEmpty) {
                selectedCity = list.firstWhereOrNull((c) =>
                    c['name']?.toString().toLowerCase().trim() ==
                    address.city.toLowerCase().trim());
              }
              selectedCity ??= list.firstWhereOrNull((c) =>
                      c['name']?.toString().toLowerCase() == 'dhaka') ??
                  list.first;

              selectedCityId.value = selectedCity['id']?.toString();
              await loadZones(
                selectedCity['id'].toString(),
                targetZoneName: isEditing ? address.zone : null,
                targetAreaName: isEditing ? address.area : null,
              );
            }
          }
        }
      } catch (_) {}
      isLoadingCities.value = false;
    }

    Future<void> performGeoSearch(String q) async {
      final query = q.trim();
      if (query.length < 2) {
        searchResults.clear();
        return;
      }
      isSearching.value = true;
      try {
        final res = await dioGet('geo/search?q=${Uri.encodeComponent(query)}');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final rawList = (data is Map && data['results'] is List)
              ? data['results'] as List
              : (res.data is Map && res.data['results'] is List)
                  ? res.data['results'] as List
                  : null;
          if (rawList != null) {
            searchResults.assignAll(List<Map<String, dynamic>>.from(rawList));
          }
        }
      } catch (_) {}
      isSearching.value = false;
    }

    void selectSearchResult(Map<String, dynamic> item) async {
      searchResults.clear();
      searchCtrl.clear();
      final city = item['city'];
      final zone = item['zone'];
      final area = item['area'];

      final cityId = city?['id']?.toString();
      final zoneId = zone?['id']?.toString();
      final areaId = area?['id']?.toString();

      if (cityId != null) {
        selectedCityId.value = cityId;
        await loadZones(cityId, targetZoneId: zoneId, targetAreaId: areaId);
      }
    }

    loadCities();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColor.white,
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
                  isEditing ? 'Edit Address' : 'Add New Address',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 14.h),

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
                                ? AppColor.white
                                : AppColor.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 14.h),

                // Full Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Phone Number
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number (11 digits) *',
                    hintText: '01XXXXXXXXX',
                    labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Quick Geo Search
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Area, Zone, or City...',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 13.sp,
                      color: AppColor.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18.r,
                      color: AppColor.textSecondary,
                    ),
                    suffixIcon: Obx(
                      () => isSearching.value
                          ? SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  ),
                  onChanged: (q) => performGeoSearch(q),
                ),
                Obx(() {
                  if (searchResults.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: EdgeInsets.only(top: 6.h, bottom: 6.h),
                    constraints: BoxConstraints(maxHeight: 180.h),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColor.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: AppColor.border),
                        itemBuilder: (context, idx) {
                          final hit = searchResults[idx];
                          final areaName =
                              hit['area']?['name'] ?? hit['name'] ?? '';
                          final zoneName = hit['zone']?['name'] ?? '';
                          final cityName = hit['city']?['name'] ?? '';
                          final breadcrumb = [areaName, zoneName, cityName]
                              .where((s) => s.toString().trim().isNotEmpty)
                              .join(' › ');
                          return ListTile(
                            dense: true,
                            title: Text(
                              breadcrumb,
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            onTap: () => selectSearchResult(hit),
                          );
                        },
                      ),
                    ),
                  );
                }),
                SizedBox(height: 10.h),

                // City Dropdown
                Obx(() {
                  if (isLoadingCities.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    key: ValueKey('city_${selectedCityId.value}'),
                    initialValue: selectedCityId.value,
                    decoration: InputDecoration(
                      labelText: 'City *',
                      labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: cities.map((c) {
                      final name = c['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: c['id']?.toString(),
                        child: Text(
                          name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedCityId.value = val;
                        loadZones(val);
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                // Zone Dropdown
                Obx(() {
                  if (isLoadingZones.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    key: ValueKey('zone_${selectedZoneId.value}'),
                    initialValue: selectedZoneId.value,
                    decoration: InputDecoration(
                      labelText: 'Zone *',
                      labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: zones.map((z) {
                      final name = z['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: z['id']?.toString(),
                        child: Text(
                          name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedZoneId.value = val;
                        loadAreas(val);
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                // Area Dropdown
                Obx(() {
                  if (isLoadingAreas.value) {
                    return Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (areas.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return DropdownButtonFormField<String>(
                    key: ValueKey('area_${selectedAreaId.value}'),
                    initialValue: selectedAreaId.value,
                    decoration: InputDecoration(
                      labelText: 'Area (Selection / Sub-area) *',
                      labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                    isExpanded: true,
                    items: areas.map((a) {
                      final name = a['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: a['id']?.toString(),
                        child: Text(
                          name,
                          style: GoogleFonts.lato(fontSize: 13.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedAreaId.value = val;
                      }
                    },
                  );
                }),
                SizedBox(height: 10.h),

                // Street / House / Road Details
                TextField(
                  controller: streetCtrl,
                  decoration: InputDecoration(
                    labelText: 'House / Road / Flat / Area Details *',
                    labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Postal Code
                TextField(
                  controller: postalCodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Postal Code *',
                    hintText: 'Enter postal code',
                    labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
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
                              final postal = postalCodeCtrl.text.trim();

                              if (name.isEmpty ||
                                  rawPhone.isEmpty ||
                                  street.isEmpty ||
                                  postal.isEmpty) {
                                Get.snackbar(
                                  'Missing Information',
                                  'Please fill in all required fields',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: AppColor.white,
                                );
                                return;
                              }

                              var phone = rawPhone.replaceAll(RegExp(r'\D'), '');
                              if (phone.startsWith('880')) {
                                phone = phone.substring(3);
                              }

                              if (phone.length != 11) {
                                Get.snackbar(
                                  'Invalid Phone Number',
                                  'Phone number must be exactly 11 digits',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: AppColor.white,
                                );
                                return;
                              }

                              final cityItem = cities.firstWhere(
                                (c) =>
                                    c['id']?.toString() ==
                                    selectedCityId.value,
                                orElse: () => {},
                              );
                              final zoneItem = zones.firstWhere(
                                (z) =>
                                    z['id']?.toString() ==
                                    selectedZoneId.value,
                                orElse: () => {},
                              );
                              final areaItem = areas.firstWhere(
                                (a) =>
                                    a['id']?.toString() ==
                                    selectedAreaId.value,
                                orElse: () => {},
                              );

                              final cityName =
                                  cityItem['name']?.toString() ?? '';
                              final zoneName =
                                  zoneItem['name']?.toString() ?? '';
                              final areaName =
                                  areaItem['name']?.toString() ??
                                      (areas.isEmpty ? zoneName : '');

                              if (cityName.isEmpty || zoneName.isEmpty) {
                                Get.snackbar(
                                  'Location Required',
                                  'Please select City and Zone',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: AppColor.white,
                                );
                                return;
                              }

                              isSaving.value = true;
                              try {
                                final payload = {
                                  'label': selectedType.value,
                                  'fullName': name,
                                  'phone': phone,
                                  'addressLine': street,
                                  'city': cityName,
                                  'zone': zoneName,
                                  'area': areaName.isNotEmpty
                                      ? areaName
                                      : zoneName,
                                  'postalCode': postal,
                                };

                                final res = isEditing
                                    ? await dioPatch(
                                        endUrl: 'addresses/${address.id}',
                                        data: payload,
                                        isJson: true,
                                      )
                                    : await dioPost(
                                        endUrl: 'addresses',
                                        data: {
                                          ...payload,
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
                                    isEditing
                                        ? 'Address updated successfully'
                                        : 'Address added successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        const Color(0xFF16A34A),
                                    colorText: AppColor.white,
                                  );
                                } else {
                                  String errMsg = isEditing
                                      ? 'Failed to update address'
                                      : 'Failed to save address';
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
                                    colorText: AppColor.white,
                                  );
                                }
                              } catch (_) {
                                isSaving.value = false;
                                Get.snackbar(
                                  'Error',
                                  'Connection error while saving address',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: AppColor.white,
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
                                color: AppColor.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Address' : 'Save Address',
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
