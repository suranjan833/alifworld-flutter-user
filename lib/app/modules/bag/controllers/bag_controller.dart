// ignore_for_file: library_prefixes

import 'dart:convert';
import 'package:dio/dio.dart' as DIO;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../data/widgets/no_internet_dialog.dart';
import '../../../routes/app_pages.dart';
import '../../product_details/models/product_details_model.dart';
import '../models/cart_model.dart';

class BagController extends GetxController with SkeletonLoadingMixin {
  final cartItems = <CartItemModel>[].obs;
  final isMutating = false.obs;
  final hasInternetError = false.obs;
  DateTime? _lastFetchTime;

  static const String _kGuestCartKey = 'GUEST_CART_ITEMS_V1';

  static BagController get to {
    if (!Get.isRegistered<BagController>()) {
      return Get.put<BagController>(BagController(), permanent: true);
    }
    return Get.find<BagController>();
  }

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);
  }

  @override
  void onInit() {
    super.onInit();
    if (!_hasAuth) {
      isLoading.value = false;
      _loadGuestCartFromStorage();
    } else {
      syncGuestCartToServer();
      isLoading.value = true;
      fetchCart(showLoading: true, force: true);
    }
  }

  void _loadGuestCartFromStorage() {
    try {
      final raw = getBox.read(_kGuestCartKey);
      if (raw is List && raw.isNotEmpty) {
        final items = raw
            .whereType<Map>()
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        cartItems.assignAll(items);
        cartItems.refresh();
        _healGuestCartPrices(items);
      }
    } catch (_) {}
  }

  void _healGuestCartPrices(List<CartItemModel> items) {
    final hasZeroPrice = items.any((it) => it.price <= 0);
    if (!hasZeroPrice) return;

    Future.microtask(() async {
      bool updated = false;
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        if (item.price <= 0) {
          try {
            final lookup = item.productId.isNotEmpty ? item.productId : (item.variantId ?? '');
            if (lookup.isEmpty) continue;
            final res = await dioGet('catalog/products/$lookup');
            if (res.statusCode == 200 && res.data != null) {
              dynamic pData = res.data;
              if (pData is Map && pData.containsKey('data')) pData = pData['data'];
              if (pData is Map && pData.containsKey('product')) pData = pData['product'];
              if (pData is Map) {
                num? minor;
                String? label;
                if (pData['variants'] is List) {
                  for (var v in pData['variants'] as List) {
                    if (v is Map &&
                        (item.variantId == null ||
                            item.variantId!.isEmpty ||
                            v['id']?.toString() == item.variantId)) {
                      minor = v['priceMinor'] ?? v['unitPriceMinor'];
                      label = v['label']?.toString();
                      break;
                    }
                  }
                }
                minor ??= pData['priceMinor'];
                if (minor != null && minor > 0) {
                  final newPrice = minor.toDouble() / 100.0;
                  cartItems[i] = item.copyWith(
                    price: newPrice,
                    unitPriceMinor: minor.toInt(),
                    variantLabel: label ?? item.variantLabel,
                  );
                  updated = true;
                }
              }
            }
          } catch (_) {}
        }
      }
      if (updated) {
        cartItems.refresh();
        _saveGuestCartToStorage();
        update();
      }
    });
  }

  void _saveGuestCartToStorage() {
    try {
      final list = cartItems.map((e) => e.toJson()).toList();
      getBox.write(_kGuestCartKey, list);
    } catch (_) {}
  }

  /// Automatically called after user logs in to transfer local guest cart to server
  Future<void> syncGuestCartToServer() async {
    if (!_hasAuth) return;
    try {
      final raw = getBox.read(_kGuestCartKey);
      if (raw is List && raw.isNotEmpty) {
        final guestList = raw
            .whereType<Map>()
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        for (final item in guestList) {
          final vId = item.variantId;
          if (vId != null && vId.isNotEmpty) {
            try {
              await dioPost(
                endUrl: 'cart',
                data: {
                  'variantId': vId,
                  'qty': item.quantity,
                },
                isJson: true,
              );
            } catch (_) {}
          }
        }
        getBox.remove(_kGuestCartKey);
      }
      await fetchCart(showLoading: false, force: true);
    } catch (_) {}
  }

  /// Safely extracts numeric item price from any data shape (string with currency, minor units, raw, variants)
  static double extractItemPrice(Map<String, dynamic> item, {String? resolvedVariantId}) {
    // 1. Raw double price
    if (item['rawPrice'] is num && (item['rawPrice'] as num) > 0) {
      return (item['rawPrice'] as num).toDouble();
    }
    // 2. Minor units (poisha)
    final minor = item['unitPriceMinor'] ?? item['priceMinor'];
    if (minor is num && minor > 0) {
      return minor.toDouble() / 100.0;
    }
    // 3. Direct price field (num or string with potential currency symbol)
    final rawPrice = item['price'];
    if (rawPrice is num && rawPrice > 0) {
      return rawPrice.toDouble();
    } else if (rawPrice != null) {
      final clean = rawPrice
          .toString()
          .replaceAll('৳', '')
          .replaceAll('₹', '')
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .trim();
      final parsed = double.tryParse(clean);
      if (parsed != null && parsed > 0) return parsed;
    }
    // 4. Nested variants list
    if (item['variants'] is List && (item['variants'] as List).isNotEmpty) {
      for (final v in item['variants'] as List) {
        if (v is Map) {
          final vMap = Map<String, dynamic>.from(v);
          final matches = resolvedVariantId == null ||
              resolvedVariantId.isEmpty ||
              vMap['id']?.toString() == resolvedVariantId;
          if (matches) {
            final vMinor = vMap['priceMinor'] ?? vMap['unitPriceMinor'];
            if (vMinor is num && vMinor > 0) {
              return vMinor.toDouble() / 100.0;
            }
            final vPrice = vMap['price'] ?? vMap['salePrice'] ?? vMap['rawPrice'];
            if (vPrice is num && vPrice > 0) {
              return vPrice.toDouble();
            } else if (vPrice != null) {
              final clean = vPrice
                  .toString()
                  .replaceAll('৳', '')
                  .replaceAll('₹', '')
                  .replaceAll('\$', '')
                  .replaceAll(',', '')
                  .trim();
              final parsed = double.tryParse(clean);
              if (parsed != null && parsed > 0) return parsed;
            }
          }
        }
      }
    }
    return 0.0;
  }

  /// Instant millisecond mutation of cart in memory
  CartItemModel addOptimisticItem(
    Map<String, dynamic> item, {
    int quantity = 1,
    String? resolvedVariantId,
  }) {
    final vId = resolvedVariantId ?? item['variantId']?.toString();
    final pId = item['productId']?.toString() ?? item['id']?.toString() ?? '';
    final double price = extractItemPrice(item, resolvedVariantId: vId);
    final int? unitPriceMinor = (price > 0)
        ? (price * 100).round()
        : (item['priceMinor'] as num?)?.toInt() ??
            (item['unitPriceMinor'] as num?)?.toInt();

    final existingIdx = cartItems.indexWhere((c) =>
        (vId != null && vId.isNotEmpty && c.variantId == vId) ||
        (c.productId == pId && (vId == null || vId.isEmpty)));

    if (existingIdx != -1) {
      final existing = cartItems[existingIdx];
      existing.quantity += quantity;
      if (existing.price <= 0 && price > 0) {
        cartItems[existingIdx] = existing.copyWith(
          price: price,
          unitPriceMinor: unitPriceMinor,
        );
      }
      cartItems.refresh();
      if (!_hasAuth) _saveGuestCartToStorage();
      return cartItems[existingIdx];
    } else {
      final newItem = CartItemModel(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
        productId: pId,
        variantId: vId,
        variantLabel: item['variantLabel']?.toString(),
        title: item['title']?.toString() ?? item['name']?.toString() ?? 'Product',
        brand: item['brand']?.toString() ?? 'Alif',
        price: price,
        quantity: quantity,
        image: item['image']?.toString() ?? '',
        unitPriceMinor: unitPriceMinor,
        minPurchaseQty: item['minPurchaseQty'] is num
            ? (item['minPurchaseQty'] as num).toInt()
            : null,
        maxPurchaseQty: item['maxPurchaseQty'] is num
            ? (item['maxPurchaseQty'] as num).toInt()
            : null,
      );
      cartItems.add(newItem);
      cartItems.refresh();
      if (!_hasAuth) _saveGuestCartToStorage();
      return newItem;
    }
  }

  /// Fire-and-forget background server sync without blocking UI
  void syncItemToServerBackground(String variantId, int quantity) {
    if (!_hasAuth) return;
    dioPost(
      endUrl: 'cart',
      data: {
        'variantId': variantId,
        'qty': quantity,
      },
      isJson: true,
    ).then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          _updateCartFromData(rawData['data']);
        }
      }
    }).catchError((_) {});
  }

  void _updateCartFromData(dynamic rawData) {
    if (rawData is Map) {
      final mapData = Map<String, dynamic>.from(rawData);
      final model = CartModel.fromJson(mapData);
      cartItems.assignAll(model.items);
      cartItems.refresh();
      update();
    }
  }

  /// 1. GET /cart - Fetch user's cart from API (no local storage)
  Future<void> fetchCart({bool showLoading = true, bool force = false}) async {
    if (!_hasAuth) {
      isLoading.value = false;
      _loadGuestCartFromStorage();
      hasInternetError.value = false;
      return;
    }

    if (!force && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!).inSeconds;
      if (elapsed < 3) return;
    }
    _lastFetchTime = DateTime.now();

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      isLoading.value = false;
      if (cartItems.isEmpty) {
        hasInternetError.value = true;
      } else {
        showNoInternetDialog(
          onRetry: () => fetchCart(showLoading: showLoading, force: true),
        );
      }
      return;
    }

    hasInternetError.value = false;

    if (showLoading && cartItems.isEmpty) {
      isLoading.value = true;
    }

    try {
      final response = await dioGet('cart').timeout(
        const Duration(seconds: 8),
        onTimeout: () => DIO.Response(
          requestOptions: DIO.RequestOptions(path: 'cart'),
          statusCode: 408,
          data: {'message': 'Request timed out'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        hasInternetError.value = false;
        dynamic rawData = response.data;
        if (rawData is String) {
          try {
            rawData = jsonDecode(rawData);
          } catch (_) {}
        }
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        List<CartItemModel> incomingItems = [];
        if (rawData is Map) {
          final cartModel =
              CartModel.fromJson(Map<String, dynamic>.from(rawData));
          incomingItems = cartModel.items;
        } else if (rawData is List) {
          for (var e in rawData) {
            if (e is Map) {
              incomingItems.add(
                CartItemModel.fromJson(Map<String, dynamic>.from(e)),
              );
            }
          }
        }

        cartItems.assignAll(incomingItems);
        cartItems.refresh();
        update();
      } else {
        cartItems.clear();
      }
    } catch (_) {
      final onlineCheck = await hasInternetConnection();
      if (!onlineCheck && cartItems.isEmpty) {
        hasInternetError.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh handler
  Future<void> refreshCart() async {
    await fetchCart(showLoading: false, force: true);
  }

  int get totalItemCount {
    int total = 0;
    for (var item in cartItems) {
      total += item.quantity;
    }
    return total;
  }

  double get subtotal {
    double total = 0;
    for (var item in cartItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get deliveryFee => subtotal > 499 || subtotal == 0 ? 0.0 : 49.0;
  double get tax => 0.0;
  double get totalDiscount {
    double total = 0;
    for (var item in cartItems) {
      total += item.lineDiscount;
    }
    return total;
  }
  double get totalAmount => subtotal + deliveryFee + tax;

  int get totalPoints {
    int total = 0;
    for (var item in cartItems) {
      total += item.calculatedLinePoints;
    }
    return total;
  }

  /// 2. PATCH /cart/items/{id} - Update exact quantity
  Future<void> updateQuantity(int index, int newQty) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final minQty = item.effectiveMinQty;
    final cap = item.effectiveCap;

    if (newQty < minQty) {
      // Stepping down from minimum or entering 0 removes the line
      await removeItem(index);
      return;
    }

    final clampedQty = newQty > cap ? cap : newQty;
    if (clampedQty == item.quantity) {
      cartItems.refresh();
      return;
    }

    final oldQty = item.quantity;
    item.quantity = clampedQty;
    cartItems.refresh();

    if (!_hasAuth) {
      _saveGuestCartToStorage();
      return;
    }

    if (_hasAuth) {
      try {
        final res = await dioPatch(
          endUrl: 'cart/items/${item.id}',
          data: {'qty': clampedQty},
          isJson: true,
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          dynamic rawData = res.data;
          if (rawData is Map && rawData.containsKey('data')) {
            _updateCartFromData(rawData['data']);
          }
        } else {
          String errMsg = 'Failed to update quantity';
          String errCode = '';
          if (res.data is Map) {
            final map = res.data as Map;
            if (map['error'] is Map) {
              errCode = map['error']['code']?.toString() ?? '';
              errMsg = map['error']['message']?.toString() ?? errMsg;
            } else if (map['message'] != null) {
              errMsg = map['message'].toString();
            }
          }

          if (errCode == 'PRODUCT_NOT_AVAILABLE' ||
              errMsg.toLowerCase().contains('not available')) {
            errMsg = 'This product is not available right now.';
            // Line disappeared server-side; refresh cart so it vanishes without re-adding or retrying
            await fetchCart(showLoading: false, force: true);
            cartItems.refresh();
          } else {
            // Revert on other failure
            item.quantity = oldQty;
            cartItems.refresh();
          }

          Get.snackbar(
            'Unable to Update',
            errMsg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (_) {
        item.quantity = oldQty;
        cartItems.refresh();
      }
    }
  }

  /// Increment quantity
  Future<void> incrementQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final cap = item.effectiveCap;

    if (item.quantity >= cap) {
      final msg = item.maxPurchaseQty != null && item.quantity >= item.maxPurchaseQty!
          ? 'Maximum purchase for this item is ${item.maxPurchaseQty}'
          : 'Only ${item.maxStock ?? cap} items available in stock';
      Get.snackbar(
        'Limit Reached',
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await updateQuantity(index, item.quantity + 1);
  }

  /// Decrement quantity
  Future<void> decrementQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final minQty = item.effectiveMinQty;

    if (item.quantity <= minQty) {
      // Stepping down from minimum removes the line
      await removeItem(index);
    } else {
      await updateQuantity(index, item.quantity - 1);
    }
  }

  /// 4. DELETE /cart/items/{id} - Remove single item
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final removed = cartItems.removeAt(index);
    cartItems.refresh();

    if (!_hasAuth) {
      _saveGuestCartToStorage();
    } else {
      try {
        final res = await dioDelete('cart/items/${removed.id}');
        if (res.statusCode == 200 && res.data != null) {
          dynamic rawData = res.data;
          if (rawData is Map && rawData.containsKey('data')) {
            _updateCartFromData(rawData['data']);
          }
        }
      } catch (_) {}
    }

    Get.snackbar(
      'Item Removed',
      '${removed.title} removed from bag',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.textPrimary,
      colorText: AppColor.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// 5. POST /cart - Add item to bag directly on server
  Future<bool> addItemToBag(Map<String, dynamic> item, {int quantity = 1}) async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      showNoInternetDialog(
        onRetry: () => addItemToBag(item, quantity: quantity),
      );
      return false;
    }

    int qtyToAdd = quantity > 0 ? quantity : 1;
    final rawMin = item['minPurchaseQty'];
    final minQty = rawMin is num
        ? rawMin.toInt()
        : (int.tryParse(rawMin?.toString() ?? '') ?? 1);
    if (minQty > 1 && qtyToAdd < minQty) {
      qtyToAdd = minQty;
    }
    final prodId = item['productId']?.toString() ??
        item['id']?.toString() ??
        '';

    String? variantId = item['variantId']?.toString();

    // 1. Try finding from variants list in item
    if (variantId == null || variantId.isEmpty || variantId == prodId) {
      if (item['variants'] is List && (item['variants'] as List).isNotEmpty) {
        final fv = (item['variants'] as List).first;
        if (fv is Map && fv['id'] != null) {
          variantId = fv['id'].toString();
        } else if (fv is ProductVariantModel) {
          variantId = fv.id;
        }
      }
    }

    // 2. If still missing and slug is present, fetch variants from catalog
    final slug = item['slug']?.toString();
    if ((variantId == null || variantId.isEmpty || variantId == prodId) &&
        slug != null &&
        slug.isNotEmpty) {
      try {
        final prodRes = await dioGet('catalog/products/$slug');
        if (prodRes.statusCode == 200 && prodRes.data != null) {
          dynamic raw = prodRes.data;
          if (raw is Map && raw.containsKey('data')) raw = raw['data'];
          if (raw is Map && raw.containsKey('product')) raw = raw['product'];
          if (raw is Map &&
              raw['variants'] is List &&
              (raw['variants'] as List).isNotEmpty) {
            final fv = (raw['variants'] as List).first;
            if (fv is Map && fv['id'] != null) {
              variantId = fv['id'].toString();
            }
          }
        }
      } catch (_) {}
    }

    if (variantId == null || variantId.isEmpty || variantId == prodId) {
      Get.snackbar(
        'Product Option',
        'Please select an available variant on product page',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return false;
    }

    final double checkPrice = extractItemPrice(item, resolvedVariantId: variantId);
    if (checkPrice <= 0) {
      final lookup = (slug != null && slug.isNotEmpty) ? slug : prodId;
      if (lookup.isNotEmpty) {
        try {
          final prodRes = await dioGet('catalog/products/$lookup');
          if (prodRes.statusCode == 200 && prodRes.data != null) {
            dynamic raw = prodRes.data;
            if (raw is Map && raw.containsKey('data')) raw = raw['data'];
            if (raw is Map && raw.containsKey('product')) raw = raw['product'];
            if (raw is Map) {
              if (raw['variants'] is List) {
                for (var v in raw['variants'] as List) {
                  if (v is Map &&
                      (variantId.isEmpty || v['id']?.toString() == variantId)) {
                    final vMin = v['priceMinor'] ?? v['unitPriceMinor'];
                    if (vMin is num && vMin > 0) {
                      item['priceMinor'] = vMin.toInt();
                      item['price'] = vMin / 100.0;
                    }
                    if (v['label'] != null) {
                      item['variantLabel'] = v['label'].toString();
                    }
                    break;
                  }
                }
              }
              if (item['price'] == null || item['price'] == 0 || item['price'] == 0.0) {
                final pMin = raw['priceMinor'];
                if (pMin is num && pMin > 0) {
                  item['priceMinor'] = pMin.toInt();
                  item['price'] = pMin / 100.0;
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    if (!_hasAuth) {
      addOptimisticItem(item, quantity: qtyToAdd, resolvedVariantId: variantId);
      _saveGuestCartToStorage();
      Get.snackbar(
        'Added to Bag',
        '${item['title'] ?? item['name'] ?? 'Item'} added to your bag',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF16A34A),
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
      return true;
    }

    isMutating.value = true;
    try {
      final response = await dioPost(
        endUrl: 'cart',
        data: {
          'variantId': variantId,
          'qty': qtyToAdd,
        },
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          _updateCartFromData(rawData['data']);
        }
        await fetchCart(showLoading: false, force: true);
        cartItems.refresh();
        update();
        Get.snackbar(
          'Added to Bag',
          '${item['title'] ?? item['name'] ?? 'Item'} added to your bag',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF16A34A),
          colorText: AppColor.white,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        String errMsg = 'Failed to add item to bag';
        String errCode = '';
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
          errMsg = 'This product is not available right now.';
        }
        Get.snackbar(
          'Unable to Add',
          errMsg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
        return false;
      }
    } catch (_) {
      final isOnline = await hasInternetConnection();
      if (!isOnline) {
        showNoInternetDialog(
          onRetry: () => addItemToBag(item, quantity: quantity),
        );
      } else {
        Get.snackbar(
          'Error',
          'Network error while adding to bag',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
      }
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  /// Clears cart items locally after order placement without calling DELETE /cart API
  void clearLocalCart() {
    cartItems.clear();
    cartItems.refresh();
    update();
  }

  /// 6. DELETE /cart - Clear whole cart directly on server
  Future<void> clearCart() async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      showNoInternetDialog(
        onRetry: () => clearCart(),
      );
      return;
    }

    cartItems.clear();
    cartItems.refresh();
    update();

    if (!_hasAuth) {
      getBox.remove(_kGuestCartKey);
      Get.snackbar(
        'Bag Cleared',
        'All items removed from your shopping bag',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.textPrimary,
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (_hasAuth) {
      try {
        final res = await dioDelete('cart');
        if (res.statusCode == 200 || res.statusCode == 204) {
          Get.snackbar(
            'Bag Cleared',
            'All items removed from your shopping bag',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.textPrimary,
            colorText: AppColor.white,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> proceedToCheckout() async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      showNoInternetDialog(
        onRetry: () => proceedToCheckout(),
      );
      return;
    }

    if (!_hasAuth) {
      Get.snackbar(
        'Login Required',
        'Please login to proceed with checkout',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.primary,
        colorText: AppColor.white,
      );
      Get.toNamed(Routes.LOGIN);
      return;
    }

    if (cartItems.isEmpty) {
      Get.snackbar(
        'Empty Bag',
        'Please add items to your bag before checking out',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColor.error,
        colorText: AppColor.white,
      );
      return;
    }

    if (!validateStockBeforeCheckout()) {
      return;
    }

    final itemsPayload = cartItems.map((e) => e.toJson()).toList();
    Get.toNamed(
      Routes.CHECKOUT,
      arguments: {
        'items': itemsPayload,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': tax,
        'totalAmount': totalAmount,
        'totalPoints': totalPoints,
        'isDirectBuy': false,
      },
    );
  }

  /// Checks whether a product or specific variant is present in cart
  bool hasItem(String productId, [String? variantId]) {
    return cartItems.any((item) {
      if (item.productId != productId && item.id != productId) return false;
      if (variantId != null && variantId.isNotEmpty) {
        return item.variantId == variantId;
      }
      return true;
    });
  }

  /// Returns current quantity of a specific product or variant in cart
  int getItemQuantity(String productId, [String? variantId]) {
    for (var item in cartItems) {
      if (item.productId == productId || item.id == productId) {
        if (variantId == null ||
            variantId.isEmpty ||
            item.variantId == variantId) {
          return item.quantity;
        }
      }
    }
    return 0;
  }

  /// Validates stock levels for all items in bag before proceeding to checkout
  bool validateStockBeforeCheckout() {
    for (var item in cartItems) {
      if (item.maxStock != null && item.quantity > item.maxStock!) {
        Get.snackbar(
          'Insufficient Stock',
          '${item.title} only has ${item.maxStock} items available',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    }
    return true;
  }
}
