import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../models/checkout_quote_model.dart';

class CheckoutController extends GetxController {
  final items = <Map<String, dynamic>>[].obs;
  final subtotal = 0.0.obs;
  final deliveryFee = 0.0.obs;
  final tax = 0.0.obs;
  final discount = 0.0.obs;
  final isDirectBuy = false.obs;

  final selectedAddressIndex = 0.obs;
  final selectedPaymentMethod = 'COD'.obs; // COD, bKash, Nagad
  final promoCodeController = TextEditingController();
  final appliedPromoCode = ''.obs;
  final isProcessingPayment = false.obs;
  final isLoadingAddresses = false.obs;

  final addresses = <Map<String, dynamic>>[].obs;

  double get finalPayable =>
      (subtotal.value + deliveryFee.value + tax.value - discount.value).clamp(
        0.0,
        double.infinity,
      );

  String? get selectedAddressId {
    if (addresses.isNotEmpty && selectedAddressIndex.value < addresses.length) {
      final id = addresses[selectedAddressIndex.value]['id']?.toString();
      if (id != null && id.isNotEmpty && !id.startsWith('addr_')) return id;
    }
    return null;
  }

  String _mapPaymentMethodToApi(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return 'bkash';
      case 'nagad':
        return 'nagad';
      case 'wallet':
        return 'wallet';
      case 'cod':
      case 'cash on delivery':
      default:
        return 'cod';
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      if (args.containsKey('items')) {
        items.value = List<Map<String, dynamic>>.from(args['items']);
      }
      subtotal.value = (args['subtotal'] as num?)?.toDouble() ?? 0.0;
      deliveryFee.value = (args['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      tax.value = (args['tax'] as num?)?.toDouble() ?? 0.0;
      isDirectBuy.value = args['isDirectBuy'] as bool? ?? false;
    }

    // Fallback: If items is still empty, load from BagController
    if (items.isEmpty) {
      if (!Get.isRegistered<BagController>()) {
        Get.put(BagController());
      }
      final bag = Get.find<BagController>();
      if (bag.cartItems.isNotEmpty) {
        items.value = bag.cartItems.map((e) => e.toJson()).toList();
        subtotal.value = bag.subtotal;
        deliveryFee.value = bag.deliveryFee;
        tax.value = bag.tax;
        isDirectBuy.value = false;
      }
    }
    fetchUserAddresses();
    fetchQuote();
  }

  @override
  void onClose() {
    promoCodeController.dispose();
    super.onClose();
  }

  void selectAddress(int index) {
    selectedAddressIndex.value = index;
    fetchQuote();
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    fetchQuote();
  }

  /// 1. GET /addresses - Fetch saved addresses for user
  Future<void> fetchUserAddresses() async {
    isLoadingAddresses.value = true;
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

        if (addrList != null && addrList.isNotEmpty) {
          final parsed = <Map<String, dynamic>>[];
          for (var item in addrList) {
            if (item is Map<String, dynamic>) {
              final street =
                  item['addressLine']?.toString() ??
                  item['address']?.toString() ??
                  '';
              final upazila = item['upazila']?.toString() ?? '';
              final district =
                  item['district']?.toString() ??
                  item['city']?.toString() ??
                  '';
              final division = item['division']?.toString() ?? '';

              final parts = [
                street,
                upazila,
                district,
                division,
              ].where((s) => s.trim().isNotEmpty).toList();
              final fullAddress = parts.isNotEmpty ? parts.join(', ') : street;

              parsed.add({
                'id': item['id']?.toString() ?? '',
                'name':
                    item['fullName']?.toString() ??
                    item['recipientName']?.toString() ??
                    item['name']?.toString() ??
                    'Customer',
                'type':
                    item['label']?.toString() ??
                    item['type']?.toString() ??
                    'Home',
                'phone': item['phone']?.toString() ?? '',
                'address': fullAddress,
                'addressLine': street,
                'upazila': upazila,
                'city': district,
                'division': division,
                'postalCode': item['postalCode']?.toString() ?? '',
                'isDefault': item['isDefault'] == true,
              });
            }
          }
          if (parsed.isNotEmpty) {
            addresses.assignAll(parsed);
            final defaultIdx = parsed.indexWhere((a) => a['isDefault'] == true);
            if (defaultIdx != -1) {
              selectedAddressIndex.value = defaultIdx;
            } else if (selectedAddressIndex.value >= addresses.length) {
              selectedAddressIndex.value = 0;
            }
            fetchQuote();
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingAddresses.value = false;
    }
  }

  /// 2. POST /checkout/quote - Fetch price quote from API
  Future<void> fetchQuote() async {
    try {
      final reqData = <String, dynamic>{
        'paymentMethod': _mapPaymentMethodToApi(selectedPaymentMethod.value),
        if (selectedAddressId != null) 'addressId': selectedAddressId,
        if (appliedPromoCode.value.isNotEmpty)
          'couponCode': appliedPromoCode.value,
      };

      final response = await dioPost(
        endUrl: 'checkout/quote',
        data: reqData,
        isJson: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          final quote = CheckoutQuoteModel.fromJson(rawData);
          if (quote.subtotal > 0) subtotal.value = quote.subtotal;
          if (quote.deliveryFee >= 0) deliveryFee.value = quote.deliveryFee;
          if (quote.tax >= 0) tax.value = quote.tax;
          if (quote.discount >= 0) discount.value = quote.discount;

          // Sync lines from quote into items so Order Items matches Total Payable
          if (rawData['lines'] is List) {
            final lines = rawData['lines'] as List;
            if (lines.isNotEmpty) {
              final bagItems = Get.isRegistered<BagController>()
                  ? Get.find<BagController>().cartItems
                  : const [];

              final updatedItems = <Map<String, dynamic>>[];
              for (var line in lines) {
                if (line is Map) {
                  final pId = line['productId']?.toString() ?? '';
                  final vId = line['variantId']?.toString() ?? '';
                  final pMinor = line['unitPriceMinor'] ?? line['priceMinor'];
                  final priceVal = pMinor is num ? (pMinor / 100.0) : 0.0;
                  final qVal = line['qty'] is num
                      ? (line['qty'] as num).toInt()
                      : 1;

                  // Find matching image from existing items or bag items
                  String img = '';
                  final existingMatch = items.firstWhereOrNull(
                    (el) =>
                        (vId.isNotEmpty && el['variantId'] == vId) ||
                        (pId.isNotEmpty && el['productId'] == pId),
                  );
                  if (existingMatch != null && existingMatch['image'] != null) {
                    img = existingMatch['image'].toString();
                  }
                  if (img.isEmpty && bagItems.isNotEmpty) {
                    final bagMatch = bagItems.firstWhereOrNull(
                      (el) =>
                          (vId.isNotEmpty && el.variantId == vId) ||
                          (pId.isNotEmpty && el.productId == pId),
                    );
                    if (bagMatch != null) {
                      img = bagMatch.image;
                    }
                  }

                  updatedItems.add({
                    'id': vId.isNotEmpty ? vId : pId,
                    'productId': pId,
                    'variantId': vId,
                    'variantLabel': line['variantLabel']?.toString(),
                    'title':
                        line['productName']?.toString() ??
                        line['title']?.toString() ??
                        'Product',
                    'price': priceVal,
                    'quantity': qVal,
                    'image': img,
                  });
                }
              }
              if (updatedItems.isNotEmpty) {
                items.assignAll(updatedItems);
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Open modal to dynamically add an address with Bangladesh Geo Hierarchy
  void openAddAddressModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final postalCodeCtrl = TextEditingController(text: '1205');
    final isSaving = false.obs;
    final selectedType = 'Home'.obs;

    // Dynamic Geo States
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
                  'Add Delivery Address',
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 14.h),

                // Address Type
                Obx(
                  () => Row(
                    children: ['Home', 'Office', 'Other'].map((type) {
                      final isSel = selectedType.value == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: (val) => selectedType.value = type,
                          selectedColor: AppColor.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.lato(
                            fontSize: 12.sp,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSel ? Colors.white : AppColor.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12.h),

                // Recipient Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Recipient Full Name *',
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
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (e.g. 017xxxxxxxx) *',
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

                // Street / House / Road Details
                TextField(
                  controller: streetCtrl,
                  maxLines: 2,
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
                    labelText: 'Postal Code (e.g. 1205)',
                    labelStyle: GoogleFonts.lato(fontSize: 13.sp),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Save Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isSaving.value
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final rawPhoneInput = phoneCtrl.text.trim();
                              final street = streetCtrl.text.trim();
                              final postal =
                                  postalCodeCtrl.text.trim().isNotEmpty
                                  ? postalCodeCtrl.text.trim()
                                  : '1000';

                              if (name.isEmpty ||
                                  rawPhoneInput.isEmpty ||
                                  street.isEmpty) {
                                Get.snackbar(
                                  'Missing Information',
                                  'Please fill all required fields',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Format & validate Bangladesh mobile number
                              var phone = rawPhoneInput.replaceAll(
                                RegExp(r'[\s\-\(\)]'),
                                '',
                              );
                              if (phone.startsWith('+880')) {
                                phone = phone.substring(3);
                              } else if (phone.startsWith('880')) {
                                phone = phone.substring(2);
                              } else if (phone.length == 10 &&
                                  phone.startsWith('1')) {
                                phone = '0$phone';
                              }

                              if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
                                Get.snackbar(
                                  'Invalid Phone Number',
                                  'Please enter a valid 11-digit mobile number (e.g. 017XXXXXXXX)',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 4),
                                );
                                return;
                              }

                              // Resolve selected geo names
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

                              final divName = divItem['name']?.toString() ?? '';
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
                                final response = await dioPost(
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

                                if (response.statusCode == 200 ||
                                    response.statusCode == 201) {
                                  Get.back(); // close bottomsheet only on success!
                                  await fetchUserAddresses();
                                  fetchQuote();

                                  Get.snackbar(
                                    'Address Saved',
                                    'Delivery address added successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: const Color(0xFF16A34A),
                                    colorText: Colors.white,
                                  );
                                } else {
                                  String errMsg = 'Failed to save address';
                                  if (response.data is Map) {
                                    final d = response.data as Map;
                                    if (d['error'] is Map &&
                                        d['error']['message'] != null) {
                                      errMsg = d['error']['message'].toString();
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
                                    duration: const Duration(seconds: 4),
                                  );
                                }
                              } catch (_) {
                                isSaving.value = false;
                                Get.snackbar(
                                  'Error',
                                  'Network error while saving address',
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
                              'Save & Deliver Here',
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void applyPromoCode() {
    final code = promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    appliedPromoCode.value = code;
    fetchQuote();

    Get.snackbar(
      'Promo Applied!',
      'Coupon "$code" applied to order',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF16A34A),
      colorText: Colors.white,
    );
  }

  void removePromoCode() {
    appliedPromoCode.value = '';
    discount.value = 0.0;
    promoCodeController.clear();
    fetchQuote();
  }

  /// 3. POST /checkout/place - Place order
  Future<void> placeOrder() async {
    if (addresses.isEmpty ||
        selectedAddressId == null ||
        selectedAddressId!.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please add a delivery address to complete your order',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: Colors.white,
      );
      if (Get.context != null) {
        openAddAddressModal(Get.context!);
      }
      return;
    }

    if (selectedPaymentMethod.value == 'bKash' ||
        selectedPaymentMethod.value == 'Nagad') {
      openMobileBankingModal(selectedPaymentMethod.value);
    } else {
      _executePlaceOrder();
    }
  }

  Future<void> _executePlaceOrder({String? gatewayPaymentId}) async {
    if (selectedAddressId == null || selectedAddressId!.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please select a valid delivery address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: Colors.white,
      );
      return;
    }

    isProcessingPayment.value = true;
    final apiPayment = _mapPaymentMethodToApi(selectedPaymentMethod.value);
    final idempotencyKey =
        'ALF_IDEMP_${DateTime.now().millisecondsSinceEpoch}_${selectedAddressId!}';

    final payload = <String, dynamic>{
      'addressId': selectedAddressId,
      'paymentMethod': apiPayment,
      if (appliedPromoCode.value.isNotEmpty)
        'couponCode': appliedPromoCode.value,
      if (apiPayment == 'wallet') ...{
        'walletKinds': ['customer_main'],
        'remainderMethod': 'cod',
      },
      'returnUrl': 'https://alifworld.vercel.app/checkout/success',
    };

    try {
      final response = await dioPost(
        endUrl: 'checkout/place',
        data: payload,
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      isProcessingPayment.value = false;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        String orderId =
            '#ALF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        String? batchNumber;
        if (rawData is Map<String, dynamic>) {
          if (rawData['orders'] is List &&
              (rawData['orders'] as List).isNotEmpty) {
            final firstOrder = (rawData['orders'] as List).first;
            if (firstOrder is Map && firstOrder['orderNumber'] != null) {
              orderId = firstOrder['orderNumber'].toString();
            }
          }
          if (rawData['batch'] is Map &&
              rawData['batch']['batchNumber'] != null) {
            batchNumber = rawData['batch']['batchNumber'].toString();
          }
          if (orderId.startsWith('#ALF') && batchNumber != null) {
            orderId = batchNumber;
          }
        }

        String paymentId =
            gatewayPaymentId ??
            (apiPayment == 'cod'
                ? ''
                : '${apiPayment.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}');

        _processSuccessfulOrder(
          paymentId: paymentId,
          paymentMethod: selectedPaymentMethod.value,
          customOrderId: orderId,
        );
      } else {
        // Handle error status
        String errorMsg = 'Failed to place order. Please try again.';
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['message'] != null) {
            errorMsg = data['message'].toString();
          } else if (data['error'] != null) {
            if (data['error'] is Map && data['error']['message'] != null) {
              errorMsg = data['error']['message'].toString();
            } else {
              errorMsg = data['error'].toString();
            }
          }
        }

        if (response.statusCode == 401) {
          Get.snackbar(
            'Login Required',
            'Please log in to your account to place an order',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            mainButton: TextButton(
              onPressed: () => Get.toNamed(Routes.LOGIN),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          Get.snackbar(
            'Order Placement Error',
            errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      isProcessingPayment.value = false;
      Get.snackbar(
        'Connection Error',
        'Unable to reach server. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: Colors.white,
      );
    }
  }

  void openMobileBankingModal(String gateway) {
    final payableStr = '৳${finalPayable.toStringAsFixed(2)}';
    final isBkash = gateway.toLowerCase() == 'bkash';

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        color: isBkash
                            ? const Color(0xFFE2136E)
                            : const Color(0xFFF7941D),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$gateway Secure Payment',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        Text(
                          'Alif Official Store',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    payableStr,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Text(
              'Complete your purchase via $gateway wallet. You will be redirected to confirm.',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                color: AppColor.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _executeGatewayPayment(gateway);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBkash
                      ? const Color(0xFFE2136E)
                      : const Color(0xFFF7941D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Confirm & Pay $payableStr',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _executeGatewayPayment(String gateway) {
    isProcessingPayment.value = true;
    final isBkash = gateway.toLowerCase() == 'bkash';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.r,
                height: 48.r,
                child: CircularProgressIndicator(
                  color: isBkash
                      ? const Color(0xFFE2136E)
                      : const Color(0xFFF7941D),
                  strokeWidth: 3.5,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Connecting to $gateway Gateway',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Please do not refresh or close the app',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    Timer(const Duration(milliseconds: 1200), () {
      Get.back(); // close dialog
      final gatewayId =
          '${gateway.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';
      _executePlaceOrder(gatewayPaymentId: gatewayId);
    });
  }

  void _processSuccessfulOrder({
    required String paymentId,
    required String paymentMethod,
    String? customOrderId,
  }) {
    final orderId =
        customOrderId ??
        '#ALF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final selectedAddr =
        (addresses.isNotEmpty && selectedAddressIndex.value < addresses.length)
        ? addresses[selectedAddressIndex.value]
        : <String, dynamic>{'address': 'Customer Delivery Address'};

    // Clear Cart if order was placed from Shopping Bag
    if (!isDirectBuy.value && Get.isRegistered<BagController>()) {
      Get.find<BagController>().clearCart();
    }

    Get.offNamed(
      Routes.ORDER_SUCCESS,
      arguments: {
        'orderId': orderId,
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'totalAmount': finalPayable,
        'itemCount': items.length,
        'address': selectedAddr['address'] ?? '',
        'items': items,
      },
    );
  }
}
