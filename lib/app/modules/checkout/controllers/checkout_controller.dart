import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final selectedPaymentMethod = 'COD'.obs; // COD, Wallet
  final promoCodeController = TextEditingController();
  final appliedPromoCode = ''.obs;
  final isProcessingPayment = false.obs;
  final isLoadingAddresses = false.obs;

  final addresses = <Map<String, dynamic>>[].obs;

  // Wallets & Gateways (§3 & §4 of checkout_flow.txt)
  final userWallets = <Map<String, dynamic>>[].obs;
  final isLoadingWallets = false.obs;
  final walletMaxPercent = 62.obs;
  final enabledGateways = <String>['cod'].obs;

  double get mainWalletBalance {
    final w = userWallets.firstWhereOrNull(
      (item) => item['kind'] == 'customer_main',
    );
    final minor = (w?['balanceMinor'] as num?)?.toDouble() ?? 0.0;
    return minor / 100.0;
  }

  double get shoppingWalletBalance {
    final w = userWallets.firstWhereOrNull(
      (item) => item['kind'] == 'customer_shopping',
    );
    final minor = (w?['balanceMinor'] as num?)?.toDouble() ?? 0.0;
    return minor / 100.0;
  }

  double get advanceWalletBalance {
    final w = userWallets.firstWhereOrNull(
      (item) => item['kind'] == 'customer_advanced_shopping',
    );
    final minor = (w?['balanceMinor'] as num?)?.toDouble() ?? 0.0;
    return minor / 100.0;
  }

  double get combinedWalletBalance =>
      mainWalletBalance + shoppingWalletBalance + advanceWalletBalance;

  // Selected wallet kinds (default: customer_main)
  final selectedWalletKinds = <String>{'customer_main'}.obs;

  void toggleWalletKind(String kind) {
    if (selectedWalletKinds.contains(kind)) {
      selectedWalletKinds.remove(kind);
    } else {
      selectedWalletKinds.add(kind);
    }
    fetchQuote();
  }

  bool isWalletKindSelected(String kind) => selectedWalletKinds.contains(kind);

  double get orderTotal =>
      (subtotal.value + deliveryFee.value + tax.value - discount.value).clamp(
        0.0,
        double.infinity,
      );

  double get walletCap {
    final total = orderTotal;
    final totalMinor = (total * 100).round();
    final capMinor = (totalMinor * walletMaxPercent.value / 100).floor();
    return capMinor / 100.0;
  }

  double get mainWalletWillUse {
    if (selectedPaymentMethod.value != 'Wallet' ||
        !selectedWalletKinds.contains('customer_main')) {
      return 0.0;
    }
    final cap = walletCap;
    final use = mainWalletBalance >= cap ? cap : mainWalletBalance;
    return (use * 100).floorToDouble() / 100.0;
  }

  double get shoppingWalletWillUse {
    if (selectedPaymentMethod.value != 'Wallet' ||
        !selectedWalletKinds.contains('customer_shopping')) {
      return 0.0;
    }
    final cap = walletCap;
    final remainingCap = (cap - mainWalletWillUse).clamp(0.0, double.infinity);
    final use = shoppingWalletBalance >= remainingCap
        ? remainingCap
        : shoppingWalletBalance;
    return (use * 100).floorToDouble() / 100.0;
  }

  double get advanceWalletWillUse {
    if (selectedPaymentMethod.value != 'Wallet' ||
        !selectedWalletKinds.contains('customer_advanced_shopping')) {
      return 0.0;
    }
    final cap = walletCap;
    final remainingCap =
        (cap - mainWalletWillUse - shoppingWalletWillUse).clamp(0.0, double.infinity);
    final use = advanceWalletBalance >= remainingCap
        ? remainingCap
        : advanceWalletBalance;
    return (use * 100).floorToDouble() / 100.0;
  }

  double get walletDeductionAmount {
    if (selectedPaymentMethod.value != 'Wallet') return 0.0;
    return mainWalletWillUse + shoppingWalletWillUse + advanceWalletWillUse;
  }

  double get remainingPayable =>
      (orderTotal - walletDeductionAmount).clamp(0.0, double.infinity);

  double get finalPayable =>
      selectedPaymentMethod.value == 'Wallet' ? remainingPayable : orderTotal;

  String? get selectedAddressId {
    if (addresses.isNotEmpty && selectedAddressIndex.value < addresses.length) {
      final id = addresses[selectedAddressIndex.value]['id']?.toString();
      if (id != null && id.isNotEmpty && !id.startsWith('addr_')) return id;
    }
    return null;
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
    fetchGateways();
    fetchUserWallets();
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
    if (method == 'Wallet') {
      fetchUserWallets();
    }
  }

  /// GET /payments/gateways - (§3 of checkout_flow.txt)
  Future<void> fetchGateways() async {
    try {
      final res = await dioGet('payments/gateways');
      if (res.statusCode == 200 && res.data != null) {
        dynamic rawData = res.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData['items'] is List) {
          final keys = (rawData['items'] as List)
              .map((e) => e is Map ? e['key']?.toString() : null)
              .whereType<String>()
              .toList();
          if (keys.isNotEmpty) {
            enabledGateways.assignAll(keys);
          }
        }
      }
    } catch (_) {}
  }

  /// GET /wallets - (§4 of checkout_flow.txt)
  Future<void> fetchUserWallets() async {
    isLoadingWallets.value = true;
    try {
      final res = await dioGet('wallets');
      if (res.statusCode == 200 && res.data != null) {
        dynamic rawData = res.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map) {
          if (rawData['items'] is List) {
            final list = (rawData['items'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            userWallets.assignAll(list);
          }
          if (rawData['walletMaxPercent'] is num) {
            walletMaxPercent.value = (rawData['walletMaxPercent'] as num)
                .toInt();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user wallets: $e');
    } finally {
      isLoadingWallets.value = false;
    }
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
              final area = item['area']?.toString() ?? item['upazila']?.toString() ?? '';
              final zone = item['zone']?.toString() ?? '';
              final city = item['city']?.toString() ?? item['district']?.toString() ?? '';
              final division = item['division']?.toString() ?? '';

              final parts = [
                street,
                area,
                zone,
                city,
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
                'area': area,
                'zone': zone,
                'city': city,
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
      final isWallet = selectedPaymentMethod.value == 'Wallet';
      final reqData = <String, dynamic>{
        'paymentMethod': isWallet ? 'wallet' : 'cod',
        if (selectedAddressId != null) 'addressId': selectedAddressId,
        if (appliedPromoCode.value.isNotEmpty)
          'couponCode': appliedPromoCode.value,
        if (isWallet) 'walletKinds': selectedWalletKinds.toList(),
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

    // Dynamic Pathao 3-level Geo States (City -> Zone -> Area)
    final cities = <Map<String, dynamic>>[].obs;
    final zones = <Map<String, dynamic>>[].obs;
    final areas = <Map<String, dynamic>>[].obs;
    final selectedCityId = Rxn<String>();
    final selectedZoneId = Rxn<String>();
    final selectedAreaId = Rxn<String>();
    final isLoadingCities = false.obs;
    final isLoadingZones = false.obs;
    final isLoadingAreas = false.obs;

    // Quick Geo Search
    final searchCtrl = TextEditingController();
    final searchResults = <Map<String, dynamic>>[].obs;
    final isSearching = false.obs;

    Future<void> loadAreas(String zoneId) async {
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
            if (list.isNotEmpty) {
              selectedAreaId.value = list.first['id']?.toString();
            }
          }
        }
      } catch (_) {}
      isLoadingAreas.value = false;
    }

    Future<void> loadZones(String cityId, {String? targetZoneId, String? targetAreaId}) async {
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
            if (list.isNotEmpty) {
              final zId = targetZoneId ?? list.first['id']?.toString();
              selectedZoneId.value = zId;
              if (zId != null) {
                await loadAreas(zId);
                if (targetAreaId != null) {
                  selectedAreaId.value = targetAreaId;
                }
              }
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
              final defaultCity = list.firstWhere(
                (c) => c['name']?.toString().toLowerCase() == 'dhaka',
                orElse: () => list.first,
              );
              selectedCityId.value = defaultCity['id']?.toString();
              await loadZones(defaultCity['id'].toString());
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
                            color: isSel ? AppColor.white : AppColor.textPrimary,
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

                // Quick Search Picker
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Area, Zone, or City...',
                    hintStyle: GoogleFonts.lato(fontSize: 13.sp, color: AppColor.textHint),
                    prefixIcon: Icon(Icons.search, size: 18.r, color: AppColor.textSecondary),
                    suffixIcon: Obx(
                      () => isSearching.value
                          ? SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                      border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: AppColor.border),
                      itemBuilder: (context, idx) {
                        final hit = searchResults[idx];
                        final areaName = hit['area']?['name'] ?? hit['name'] ?? '';
                        final zoneName = hit['zone']?['name'] ?? '';
                        final cityName = hit['city']?['name'] ?? '';
                        final breadcrumb = [areaName, zoneName, cityName]
                            .where((s) => s.toString().trim().isNotEmpty)
                            .join(' › ');
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.location_on_outlined, size: 18.r, color: AppColor.primary),
                          title: Text(
                            breadcrumb,
                            style: GoogleFonts.lato(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                          ),
                          onTap: () => selectSearchResult(hit),
                        );
                      },
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
                                  colorText: AppColor.white,
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

                              if (phone.length != 11) {
                                Get.snackbar(
                                  'Invalid Phone Number',
                                  'Phone number must be exactly 11 digits',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColor.error,
                                  colorText: AppColor.white,
                                  duration: const Duration(seconds: 4),
                                );
                                return;
                              }

                              // Resolve selected Pathao geo names (City -> Zone -> Area)
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

                              final cityName = cityItem['name']?.toString() ?? '';
                              final zoneName =
                                  zoneItem['name']?.toString() ?? '';
                              final areaName =
                                  areaItem['name']?.toString() ?? (areas.isEmpty ? zoneName : '');

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
                                final response = await dioPost(
                                  endUrl: 'addresses',
                                  data: {
                                    'label': selectedType.value,
                                    'fullName': name,
                                    'phone': phone,
                                    'addressLine': street,
                                    'city': cityName,
                                    'zone': zoneName,
                                    'area': areaName.isNotEmpty ? areaName : zoneName,
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
                                    colorText: AppColor.white,
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
                                    colorText: AppColor.white,
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
                              'Save & Deliver Here',
                              style: GoogleFonts.lato(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.white,
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
      colorText: AppColor.white,
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
        colorText: AppColor.white,
      );
      if (Get.context != null) {
        openAddAddressModal(Get.context!);
      }
      return;
    }

    _executePlaceOrder();
  }

  Future<void> _executePlaceOrder() async {
    if (selectedAddressId == null || selectedAddressId!.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please select a valid delivery address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    isProcessingPayment.value = true;
    final isWallet = selectedPaymentMethod.value == 'Wallet';
    final apiPayment = isWallet ? 'wallet' : 'cod';
    final idempotencyKey =
        'ALF_IDEMP_${DateTime.now().millisecondsSinceEpoch}_${selectedAddressId!}';

    final payload = <String, dynamic>{
      'addressId': selectedAddressId,
      'paymentMethod': apiPayment,
      if (appliedPromoCode.value.isNotEmpty)
        'couponCode': appliedPromoCode.value,
      if (isWallet) ...{
        'walletKinds': selectedWalletKinds.toList(),
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
        String? paymentStatus;
        if (rawData is Map<String, dynamic>) {
          if (rawData['orders'] is List &&
              (rawData['orders'] as List).isNotEmpty) {
            final firstOrder = (rawData['orders'] as List).first;
            if (firstOrder is Map && firstOrder['orderNumber'] != null) {
              orderId = firstOrder['orderNumber'].toString();
            }
          }
          if (rawData['batch'] is Map) {
            final b = rawData['batch'] as Map;
            if (b['batchNumber'] != null) {
              batchNumber = b['batchNumber'].toString();
            }
            if (b['paymentStatus'] != null) {
              paymentStatus = b['paymentStatus'].toString();
            }
          }
        }

        final paymentLabel = isWallet
            ? (remainingPayable > 0
                  ? 'Pay from Wallet (COD Remainder)'
                  : 'Alif Wallet')
            : 'Cash on Delivery';

        _processSuccessfulOrder(
          paymentId: isWallet ? 'WALLET_DEBIT' : 'COD_PENDING',
          paymentMethod: paymentLabel,
          customOrderId: orderId,
          batchNumber: batchNumber,
          paymentStatus: paymentStatus,
        );
      } else {
        // Handle error status per §7 of checkout_flow.txt
        String errorCode = '';
        String errorMsg = 'Failed to place order. Please try again.';
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['error'] is Map) {
            final errObj = data['error'] as Map;
            errorCode = errObj['code']?.toString() ?? '';
            errorMsg = errObj['message']?.toString() ?? errorMsg;
          } else if (data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        }

        if (response.statusCode == 401 || errorCode == 'UNAUTHENTICATED') {
          Get.snackbar(
            'Login Required',
            'Please log in to your account to place an order',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
            mainButton: TextButton(
              onPressed: () => Get.toNamed(Routes.LOGIN),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else if (errorCode == 'WALLET_INSUFFICIENT') {
          await fetchUserWallets();
          await fetchQuote();
          Get.snackbar(
            'Wallet Balance Changed',
            'Your wallet balance has changed. Please review before placing order.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFD97706),
            colorText: AppColor.white,
          );
        } else if (errorCode == 'CART_EMPTY') {
          Get.snackbar(
            'Cart is Empty',
            'Your shopping bag is empty. Please add items to order.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
          );
        } else if (errorCode == 'INVENTORY_FAILED') {
          Get.snackbar(
            'Out of Stock',
            'Some items are currently unavailable. Please adjust quantity.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
          );
        } else {
          Get.snackbar(
            'Order Placement Error',
            errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
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
        colorText: AppColor.white,
      );
    }
  }

  void _processSuccessfulOrder({
    required String paymentId,
    required String paymentMethod,
    String? customOrderId,
    String? batchNumber,
    String? paymentStatus,
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
        'batchNumber': batchNumber ?? '',
        'paymentStatus': paymentStatus ?? '',
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
