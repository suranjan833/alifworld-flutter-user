import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/address_model.dart';
import '../../../data/widgets/address_form_modal.dart';
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

  Future<void> deleteAddress(String addressId) async {
    try {
      final res = await dioDelete('addresses/$addressId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        addresses.removeWhere((addr) => addr['id'] == addressId);
        if (selectedAddressIndex.value >= addresses.length) {
          selectedAddressIndex.value = addresses.isNotEmpty ? 0 : 0;
        }
        await fetchUserAddresses();
        fetchQuote();
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
      'returnUrl': resolveImageUrl('/checkout/success'),
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