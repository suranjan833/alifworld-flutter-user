import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/redeem_model.dart';
import '../../../data/widgets/address_form_modal.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import '../../../routes/app_pages.dart';
import '../../bag/controllers/bag_controller.dart';
import '../models/checkout_quote_model.dart';

class CheckoutController extends GetxController {
  static const String _kCachedUserAddresses = 'cached_user_addresses';
  static const String _kCachedSelectedAddressIndex = 'cached_selected_address_idx';
  static const String _kCachedUserWallets = 'cached_user_wallets';

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
  final walletMaxPercent = 100.obs;
  final mainWalletCapPercent = 100.obs;
  final shoppingWalletCapPercent = 62.obs;
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
      mainWalletBalance + shoppingWalletBalance;

  // Selected wallet kinds
  final selectedWalletKinds = <String>{}.obs;

  List<String> get effectiveWalletKinds {
    final list = <String>[];
    if (selectedWalletKinds.contains('customer_main') && mainWalletBalance > 0) {
      list.add('customer_main');
    }
    if (selectedWalletKinds.contains('customer_shopping') &&
        shoppingWalletBalance > 0) {
      list.add('customer_shopping');
    }
    return list;
  }

  void _ensureValidWalletSelection() {
    selectedWalletKinds.removeWhere((kind) {
      if (kind == 'customer_main') return mainWalletBalance <= 0;
      if (kind == 'customer_shopping') return shoppingWalletBalance <= 0;
      return true;
    });

    if (selectedWalletKinds.isEmpty && combinedWalletBalance > 0) {
      if (mainWalletBalance > 0) {
        selectedWalletKinds.add('customer_main');
      } else if (shoppingWalletBalance > 0) {
        selectedWalletKinds.add('customer_shopping');
      }
    }
  }

  void toggleWalletKind(String kind) {
    final active = effectiveWalletKinds;
    if (active.contains(kind)) {
      if (active.length <= 1) {
        Get.snackbar(
          'Pay from Wallet',
          'At least one wallet must remain selected',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFD97706),
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      selectedWalletKinds.remove(kind);
    } else {
      final bal = kind == 'customer_main'
          ? mainWalletBalance
          : (kind == 'customer_shopping' ? shoppingWalletBalance : 0.0);
      if (bal <= 0) {
        Get.snackbar(
          'Pay from Wallet',
          'There is no balance in this wallet',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFDC2626),
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      selectedWalletKinds.add(kind);
    }
    fetchQuote();
  }

  bool isWalletKindSelected(String kind) {
    if (kind == 'customer_main' && mainWalletBalance <= 0) return false;
    if (kind == 'customer_shopping' && shoppingWalletBalance <= 0) return false;
    return selectedWalletKinds.contains(kind);
  }

  double get orderTotal =>
      (subtotal.value + deliveryFee.value + tax.value - discount.value).clamp(
        0.0,
        double.infinity,
      );

  double get mainWalletCap {
    final total = orderTotal;
    final totalMinor = (total * 100).round();
    final capMinor = (totalMinor * mainWalletCapPercent.value / 100).floor();
    return capMinor / 100.0;
  }

  double get shoppingWalletCap {
    final total = orderTotal;
    final totalMinor = (total * 100).round();
    final capMinor = (totalMinor * shoppingWalletCapPercent.value / 100).floor();
    return capMinor / 100.0;
  }

  double get walletCap {
    final total = orderTotal;
    final totalMinor = (total * 100).round();
    final capMinor = (totalMinor * walletMaxPercent.value / 100).floor();
    return capMinor / 100.0;
  }

  double get mainWalletWillUse {
    if (selectedPaymentMethod.value != 'Wallet' ||
        !isWalletKindSelected('customer_main')) {
      return 0.0;
    }
    final cap = mainWalletCap < walletCap ? mainWalletCap : walletCap;
    final maxAllowed = mainWalletBalance < cap ? mainWalletBalance : cap;
    final use = maxAllowed < orderTotal ? maxAllowed : orderTotal;
    return (use * 100).floorToDouble() / 100.0;
  }

  double get shoppingWalletWillUse {
    if (selectedPaymentMethod.value != 'Wallet' ||
        !isWalletKindSelected('customer_shopping')) {
      return 0.0;
    }
    final remainingOrder =
        (orderTotal - mainWalletWillUse).clamp(0.0, double.infinity);
    final remainingOverallCap =
        (walletCap - mainWalletWillUse).clamp(0.0, double.infinity);
    final cap = shoppingWalletCap < remainingOverallCap
        ? shoppingWalletCap
        : remainingOverallCap;
    final maxAllowed = shoppingWalletBalance < cap ? shoppingWalletBalance : cap;
    final use = maxAllowed < remainingOrder ? maxAllowed : remainingOrder;
    return (use * 100).floorToDouble() / 100.0;
  }

  int get totalEarnPoints {
    int total = 0;
    for (var item in items) {
      final rawQty = item['quantity'] ?? item['qty'];
      final qty = rawQty is num ? rawQty.toInt() : (int.tryParse(rawQty?.toString() ?? '') ?? 1);
      final rawPts = item['pointsPerUnit'] ?? item['productPoints'];
      final pts = rawPts is num ? rawPts.toInt() : (int.tryParse(rawPts?.toString() ?? '') ?? 0);
      final rawLinePts = item['linePoints'];
      final linePts = rawLinePts is num ? rawLinePts.toInt() : null;
      if (linePts != null && linePts > 0) {
        total += linePts;
      } else if (pts > 0) {
        total += pts * qty;
      }
    }
    return total;
  }

  double get advanceWalletWillUse => 0.0;

  double get walletDeductionAmount {
    if (selectedPaymentMethod.value != 'Wallet') return 0.0;
    return mainWalletWillUse + shoppingWalletWillUse;
  }

  double get remainingPayable =>
      (orderTotal - walletDeductionAmount).clamp(0.0, double.infinity);

  double get finalPayable =>
      selectedPaymentMethod.value == 'Wallet' ? remainingPayable : orderTotal;

  double get totalAddons {
    double total = 0.0;
    for (var item in items) {
      final q = (item['quantity'] ?? item['qty'] ?? 1) as num;
      final addonsMinor = item['addonsPerUnitMinor'] ?? item['addonPriceMinor'];
      if (addonsMinor is num && addonsMinor > 0) {
        total += (addonsMinor / 100.0) * q;
      } else if (item['addonsTotalMinor'] is num && item['addonsTotalMinor'] > 0) {
        total += (item['addonsTotalMinor'] as num) / 100.0;
      }
    }
    return total;
  }

  double get baseSubtotal => (subtotal.value - totalAddons).clamp(0.0, subtotal.value);

  String get dueMethodLabel {
    if (selectedPaymentMethod.value == 'COD') return 'Cash on delivery';
    if (selectedPaymentMethod.value == 'Wallet') {
      return remainingPayable > 0 ? 'Wallet + Cash on delivery' : 'Wallet';
    }
    if (selectedPaymentMethod.value == 'Online') return 'Online payment';
    return selectedPaymentMethod.value;
  }

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
    _loadCachedAddresses();
    _loadCachedWallets();
    fetchUserAddresses();
    fetchUserWallets();
    fetchQuote();
  }

  void _loadCachedAddresses() {
    try {
      final cached = getBox.read<List>(_kCachedUserAddresses);
      if (cached != null && cached.isNotEmpty) {
        final parsed = <Map<String, dynamic>>[];
        for (var item in cached) {
          if (item is Map) {
            parsed.add(Map<String, dynamic>.from(item));
          }
        }
        if (parsed.isNotEmpty) {
          addresses.assignAll(parsed);
          final savedIdx = getBox.read<int>(_kCachedSelectedAddressIndex);
          if (savedIdx != null && savedIdx >= 0 && savedIdx < addresses.length) {
            selectedAddressIndex.value = savedIdx;
          } else {
            final defaultIdx = parsed.indexWhere((a) => a['isDefault'] == true);
            selectedAddressIndex.value = defaultIdx != -1 ? defaultIdx : 0;
          }
          isLoadingAddresses.value = false;
        }
      }
    } catch (_) {}
  }

  void _loadCachedWallets() {
    try {
      final cached = getBox.read<List>(_kCachedUserWallets);
      if (cached != null && cached.isNotEmpty) {
        final list = <Map<String, dynamic>>[];
        for (var item in cached) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          }
        }
        if (list.isNotEmpty) {
          userWallets.assignAll(list);
          isLoadingWallets.value = false;
          _ensureValidWalletSelection();
        }
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    promoCodeController.dispose();
    super.onClose();
  }

  void selectAddress(int index) {
    selectedAddressIndex.value = index;
    getBox.write(_kCachedSelectedAddressIndex, index);
    fetchQuote();
  }

  void selectPaymentMethod(String method) {
    if (method == 'Wallet' && combinedWalletBalance <= 0) {
      Get.snackbar(
        'Pay from Wallet',
        'There is no balance in wallet',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFD97706),
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    selectedPaymentMethod.value = method;
    if (method == 'Wallet') {
      _ensureValidWalletSelection();
      fetchUserWallets();
    }
    fetchQuote();
  }

  /// GET /wallets - (§4 of checkout_flow.txt)
  Future<void> fetchUserWallets() async {
    if (userWallets.isEmpty) {
      isLoadingWallets.value = true;
    }
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
            getBox.write(_kCachedUserWallets, list);
          }
          if (rawData['walletCaps'] is Map) {
            final caps = rawData['walletCaps'] as Map;
            if (caps['customer_main'] is num) {
              mainWalletCapPercent.value =
                  (caps['customer_main'] as num).toInt();
            }
            if (caps['customer_shopping'] is num) {
              shoppingWalletCapPercent.value =
                  (caps['customer_shopping'] as num).toInt();
            }
          }
          if (rawData['walletMaxPercent'] is num) {
            walletMaxPercent.value = (rawData['walletMaxPercent'] as num)
                .toInt();
          } else {
            walletMaxPercent.value =
                (mainWalletCapPercent.value + shoppingWalletCapPercent.value)
                    .clamp(0, 100);
          }
        }
        if (combinedWalletBalance <= 0 &&
            selectedPaymentMethod.value == 'Wallet') {
          selectedPaymentMethod.value = 'COD';
          fetchQuote();
        } else {
          _ensureValidWalletSelection();
          if (selectedPaymentMethod.value == 'Wallet') {
            fetchQuote();
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
    if (addresses.isEmpty) {
      isLoadingAddresses.value = true;
    }
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
              final a = AddressModel.fromJson(item);
              parsed.add({
                'id': a.id,
                'name': a.fullName,
                'type': a.label,
                'phone': a.phone,
                'address': a.formattedAddress,
                'addressLine': a.addressLine,
                'division': a.division,
                'district': a.district,
                'upazila': a.upazila,
                'union': a.union,
                'area': a.area,
                'city': a.city,
                'zone': a.zone,
                'postalCode': a.postalCode,
                'isDefault': a.isDefault,
              });
            }
          }
          if (parsed.isNotEmpty) {
            addresses.assignAll(parsed);
            getBox.write(_kCachedUserAddresses, parsed);
            final savedIdx = getBox.read<int>(_kCachedSelectedAddressIndex);
            if (savedIdx != null && savedIdx >= 0 && savedIdx < addresses.length) {
              selectedAddressIndex.value = savedIdx;
            } else {
              final defaultIdx = parsed.indexWhere((a) => a['isDefault'] == true);
              if (defaultIdx != -1) {
                selectedAddressIndex.value = defaultIdx;
              } else if (selectedAddressIndex.value >= addresses.length) {
                selectedAddressIndex.value = 0;
              }
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
      final activeWallets = effectiveWalletKinds;
      final reqData = <String, dynamic>{
        'paymentMethod': isWallet ? 'wallet' : 'cod',
        if (selectedAddressId != null) 'addressId': selectedAddressId,
        if (appliedPromoCode.value.isNotEmpty)
          'couponCode': appliedPromoCode.value,
        if (isWallet && activeWallets.isNotEmpty)
          'walletKinds': activeWallets,
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
                  final rawAddonsMinor = line['addonsPerUnitMinor'];
                  final int addonsMinor =
                      rawAddonsMinor is num ? rawAddonsMinor.toInt() : 0;
                  final rawLineTotalMinor = line['lineTotalMinor'];
                  final qVal = line['qty'] is num
                      ? (line['qty'] as num).toInt()
                      : 1;

                  double priceVal = pMinor is num
                      ? ((pMinor + addonsMinor) / 100.0)
                      : 0.0;
                  if (rawLineTotalMinor is num && qVal > 0) {
                    final unitFromLine =
                        rawLineTotalMinor / (qVal * 100.0);
                    if (unitFromLine > priceVal) {
                      priceVal = unitFromLine;
                    }
                  }

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
                  final bagMatch = bagItems.isNotEmpty
                      ? bagItems.firstWhereOrNull(
                          (el) =>
                              (vId.isNotEmpty && el.variantId == vId) ||
                              (pId.isNotEmpty && el.productId == pId),
                        )
                      : null;
                  if (img.isEmpty && bagMatch != null) {
                    img = bagMatch.image;
                  }

                  final summary = line['addonsSummary']?.toString() ??
                      existingMatch?['addonsSummary']?.toString() ??
                      bagMatch?.addonsSummary;

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
                    if (summary != null && summary.isNotEmpty)
                      'addonsSummary': summary,
                  });
                }
              }
              if (updatedItems.isNotEmpty) {
                items.assignAll(updatedItems);
              }
            }
          }
        }
      } else if (response.statusCode == 400) {
        String errCode = '';
        String errMsg = 'Failed to fetch quote';
        if (response.data is Map) {
          final map = response.data as Map;
          if (map['error'] is Map) {
            errCode = map['error']['code']?.toString() ?? '';
            errMsg = map['error']['message']?.toString() ?? errMsg;
          } else if (map['message'] != null) {
            errMsg = map['message'].toString();
          }
        }
        if (errCode == 'PRODUCT_NOT_AVAILABLE' ||
            errMsg.toLowerCase().contains('not available')) {
          Get.snackbar(
            'Product Unavailable',
            'This product is not available right now.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
          );
          if (Get.isRegistered<BagController>()) {
            Get.find<BagController>().fetchCart(showLoading: false, force: true);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      final res = await dioDelete('addresses/$addressId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        addresses.removeWhere((addr) => addr['id'] == addressId);
        getBox.write(_kCachedUserAddresses, addresses.toList());
        if (selectedAddressIndex.value >= addresses.length) {
          selectedAddressIndex.value = addresses.isNotEmpty ? 0 : 0;
        }
        getBox.write(_kCachedSelectedAddressIndex, selectedAddressIndex.value);
        await fetchUserAddresses();
        fetchQuote();
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

  /// Open modal to dynamically add or edit an address with Bangladesh Geo Hierarchy
  /// Open modal to dynamically add or edit an address with 5-Level Bangladesh Geo Hierarchy
  void openAddAddressModal(BuildContext context, {Map<String, dynamic>? address}) {
    AddressModel? addrModel;
    if (address != null) {
      addrModel = AddressModel.fromJson(address);
    }
    AddressFormModal.show(
      context,
      address: addrModel,
      onSaved: (saved) {
        fetchUserAddresses();
      },
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
      snackPosition: SnackPosition.TOP,
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
    if (isProcessingPayment.value) return;

    if (addresses.isEmpty ||
        selectedAddressId == null ||
        selectedAddressId!.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please add a delivery address to complete your order',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      if (Get.context != null) {
        openAddAddressModal(Get.context!);
      }
      return;
    }

    final isWallet = selectedPaymentMethod.value == 'Wallet' &&
        combinedWalletBalance > 0 &&
        walletDeductionAmount > 0 &&
        effectiveWalletKinds.isNotEmpty;
    if (isWallet) {
      await _startWalletPinCheckout();
    } else {
      // Wallet e balance zero hole wallet pin chaibeii na
      await _executePlaceOrder();
    }
  }

  Future<void> _startWalletPinCheckout() async {
    if (Get.context == null || isProcessingPayment.value) return;

    Map<String, dynamic>? successOrderData;

    final pin = await WalletPinDialog.promptPin(
      Get.context!,
      title: 'Wallet Payment PIN',
      subtitle: 'Enter your 6-digit wallet PIN to complete payment',
      onConfirm: (pin) async {
        final result = await _executePlaceOrder(
          walletPin: pin,
          deferNavigation: true,
        );
        if (result['success'] == true) {
          successOrderData = result['data'] as Map<String, dynamic>?;
          return const WalletPinActionResult.success();
        }
        return (result['pinResult'] as WalletPinActionResult?) ??
            const WalletPinActionResult.failure(
              errorMessage: 'Failed to place order',
            );
      },
    );

    // If order was successfully placed and PIN sheet popped cleanly
    if (pin != null && successOrderData != null) {
      _processSuccessfulOrder(
        paymentId: successOrderData!['paymentId'] as String,
        paymentMethod: successOrderData!['paymentMethod'] as String,
        customOrderId: successOrderData!['customOrderId'] as String?,
        batchNumber: successOrderData!['batchNumber'] as String?,
        paymentStatus: successOrderData!['paymentStatus'] as String?,
      );
    } else if (pin != null && successOrderData == null) {
      // PIN was newly set and dialog closed cleanly, now execute place order
      await _executePlaceOrder(walletPin: pin);
    }
  }

  Future<Map<String, dynamic>> _executePlaceOrder({
    String? walletPin,
    bool deferNavigation = false,
  }) async {
    if (isProcessingPayment.value) {
      return {
        'success': false,
        'pinResult': const WalletPinActionResult.failure(
          errorCode: 'ALREADY_PROCESSING',
          errorMessage: 'Payment is already processing',
        ),
      };
    }

    if (selectedAddressId == null || selectedAddressId!.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please select a valid delivery address',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return {
        'success': false,
        'pinResult': const WalletPinActionResult.failure(
          errorCode: 'ADDRESS_REQUIRED',
          errorMessage: 'Please select a delivery address',
        ),
      };
    }

    isProcessingPayment.value = true;
    final activeWallets = effectiveWalletKinds;
    final isWallet = selectedPaymentMethod.value == 'Wallet' &&
        combinedWalletBalance > 0 &&
        walletDeductionAmount > 0 &&
        activeWallets.isNotEmpty;
    final apiPayment = isWallet ? 'wallet' : 'cod';
    final idempotencyKey = generateUuidV4();

    final payload = <String, dynamic>{
      'addressId': selectedAddressId,
      'paymentMethod': apiPayment,
      if (appliedPromoCode.value.isNotEmpty)
        'couponCode': appliedPromoCode.value,
      if (isWallet) ...{
        'walletKinds': activeWallets,
        'remainderMethod': 'cod',
        if (walletPin != null && walletPin.isNotEmpty)
          'walletPin': walletPin,
      },
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

        final successData = <String, dynamic>{
          'paymentId': isWallet ? 'WALLET_DEBIT' : 'COD_PENDING',
          'paymentMethod': paymentLabel,
          'customOrderId': orderId,
          'batchNumber': batchNumber,
          'paymentStatus': paymentStatus,
        };

        if (!deferNavigation) {
          _processSuccessfulOrder(
            paymentId: successData['paymentId'] as String,
            paymentMethod: successData['paymentMethod'] as String,
            customOrderId: successData['customOrderId'] as String?,
            batchNumber: successData['batchNumber'] as String?,
            paymentStatus: successData['paymentStatus'] as String?,
          );
        }

        return {
          'success': true,
          'data': successData,
          'pinResult': const WalletPinActionResult.success(),
        };
      } else {
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

        // 1. PIN-related errors (WALLET_PIN_*)
        if (errorCode.startsWith('WALLET_PIN_')) {
          return {
            'success': false,
            'pinResult': WalletPinActionResult.failure(
              errorCode: errorCode,
              errorMessage: errorMsg,
            ),
          };
        }

        // 2. Cart empty (already processed)
        if (errorCode == 'CART_EMPTY') {
          Get.snackbar(
            'Order Status',
            'Your order has already been processed. Viewing your orders...',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFD97706),
            colorText: AppColor.white,
            duration: const Duration(seconds: 3),
          );
          if (!isDirectBuy.value && Get.isRegistered<BagController>()) {
            Get.find<BagController>().clearLocalCart();
          }
          Get.offNamed(Routes.MY_ORDERS);
          return {
            'success': false,
            'pinResult': WalletPinActionResult.failure(
              errorCode: errorCode,
              errorMessage: errorMsg,
            ),
          };
        }

        // 3. Address issue (ADDRESS_NOT_FOUND / INVALID_ADDRESS)
        if (errorCode == 'ADDRESS_NOT_FOUND' ||
            errorCode == 'INVALID_ADDRESS' ||
            errorCode == 'DELIVERY_ADDRESS_NOT_FOUND' ||
            errorMsg.toLowerCase().contains('address not found') ||
            errorMsg.toLowerCase().contains('delivery address not found')) {
          if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
            Get.back();
          }
          selectedAddressIndex.value = -1;
          await fetchUserAddresses();
          Get.snackbar(
            'Address Required',
            'Delivery address not found. Please add a valid address to complete your order.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
          );
          if (Get.context != null) {
            openAddAddressModal(Get.context!);
          }
          return {
            'success': false,
            'pinResult': const WalletPinActionResult.failure(
              errorCode: 'ADDRESS_NOT_FOUND',
              errorMessage: 'Delivery address not found. Please add an address.',
            ),
          };
        }

        // 4. Other non-PIN errors handled on checkout view
        if (response.statusCode == 401 || errorCode == 'UNAUTHENTICATED') {
          Get.snackbar(
            'Login Required',
            'Please log in to your account to place an order',
            snackPosition: SnackPosition.TOP,
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
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFD97706),
            colorText: AppColor.white,
          );
        } else if (errorCode == 'CART_EMPTY') {
          Get.snackbar(
            'Cart is Empty',
            'Your shopping bag is empty. Please add items to order.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
          );
        } else if (errorCode == 'PRODUCT_NOT_AVAILABLE' ||
            errorMsg.toLowerCase().contains('not available')) {
          Get.snackbar(
            'Product Unavailable',
            'This product is not available right now.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
          );
          if (Get.isRegistered<BagController>()) {
            await Get.find<BagController>().fetchCart(showLoading: false, force: true);
          }
          return {
            'success': false,
            'pinResult': const WalletPinActionResult.failure(
              errorCode: 'PRODUCT_NOT_AVAILABLE',
              errorMessage: 'This product is not available right now.',
            ),
          };
        } else if (errorCode == 'MIN_PURCHASE_QTY' ||
            errorCode == 'MAX_PURCHASE_QTY') {
          Get.snackbar(
            'Quantity Limit',
            errorMsg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
          );
        } else if (errorCode == 'INVENTORY_FAILED' ||
            errorCode == 'VARIANT_NOT_AVAILABLE') {
          Get.snackbar(
            'Out of Stock',
            'Some items are currently unavailable. Please adjust quantity.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
          );
        } else if (errorCode == 'RATE_LIMITED') {
          Get.snackbar(
            'Please Wait',
            'Too many requests. Please try again in a moment.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFD97706),
            colorText: AppColor.white,
          );
        } else {
          Get.snackbar(
            'Order Placement Error',
            errorMsg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 4),
          );
        }

        return {
          'success': false,
          'pinResult': WalletPinActionResult.failure(
            errorCode: errorCode,
            errorMessage: errorMsg,
          ),
        };
      }
    } catch (e) {
      isProcessingPayment.value = false;
      Get.snackbar(
        'Connection Error',
        'Unable to reach server. Please check your internet connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return {
        'success': false,
        'pinResult': const WalletPinActionResult.failure(
          errorCode: 'NETWORK_ERROR',
          errorMessage: 'Unable to reach server. Please check your internet connection.',
        ),
      };
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
      Get.find<BagController>().clearLocalCart();
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
        'totalPoints': totalEarnPoints,
        'itemCount': items.length,
        'address': selectedAddr['address'] ?? '',
        'items': items,
      },
    );
  }
}