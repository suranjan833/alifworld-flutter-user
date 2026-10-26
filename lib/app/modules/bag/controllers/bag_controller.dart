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

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);
  }

  @override
  void onInit() {
    super.onInit();
    // Wipe any previously saved local cart data completely
    try {
      getBox.remove('LOCAL_CART_ITEMS_V1');
      getBox.remove('LOCAL_CART_ITEMS');
    } catch (_) {}

    if (!_hasAuth) {
      isLoading.value = false;
      cartItems.clear();
    } else {
      isLoading.value = true;
      fetchCart(showLoading: true, force: true);
    }
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
      cartItems.clear();
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
  double get totalAmount => subtotal + deliveryFee + tax;

  /// 2. PATCH /cart/items/{id} - Increment quantity
  Future<void> incrementQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];

    // Check stock limit if known
    if (item.maxStock != null && item.quantity >= item.maxStock!) {
      Get.snackbar(
        'Stock Limit Reached',
        'Only ${item.maxStock} items available in stock',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: AppColor.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final oldQty = item.quantity;
    final newQty = oldQty + 1;
    item.quantity = newQty;
    cartItems.refresh();

    if (_hasAuth) {
      try {
        final res = await dioPatch(
          endUrl: 'cart/items/${item.id}',
          data: {'qty': newQty},
          isJson: true,
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          dynamic rawData = res.data;
          if (rawData is Map && rawData.containsKey('data')) {
            _updateCartFromData(rawData['data']);
          }
        } else {
          // Revert on failure
          item.quantity = oldQty;
          cartItems.refresh();

          String errMsg = 'Failed to update quantity';
          if (res.data is Map) {
            final map = res.data as Map;
            if (map['error'] is Map && map['error']['message'] != null) {
              errMsg = map['error']['message'].toString();
            } else if (map['message'] != null) {
              errMsg = map['message'].toString();
            }
          }
          Get.snackbar(
            'Unable to Update',
            errMsg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColor.error,
            colorText: AppColor.white,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (_) {
        item.quantity = oldQty;
        cartItems.refresh();
      }
    }
  }

  /// 3. PATCH /cart/items/{id} - Decrement quantity
  Future<void> decrementQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final currentQty = item.quantity;

    if (currentQty > 1) {
      final oldQty = currentQty;
      final newQty = currentQty - 1;
      item.quantity = newQty;
      cartItems.refresh();

      if (_hasAuth) {
        try {
          final res = await dioPatch(
            endUrl: 'cart/items/${item.id}',
            data: {'qty': newQty},
            isJson: true,
          );

          if (res.statusCode == 200 || res.statusCode == 201) {
            dynamic rawData = res.data;
            if (rawData is Map && rawData.containsKey('data')) {
              _updateCartFromData(rawData['data']);
            }
          } else {
            item.quantity = oldQty;
            cartItems.refresh();
          }
        } catch (_) {
          item.quantity = oldQty;
          cartItems.refresh();
        }
      }
    } else {
      removeItem(index);
    }
  }

  /// 4. DELETE /cart/items/{id} - Remove single item
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final removed = cartItems.removeAt(index);

    if (_hasAuth) {
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
  Future<void> addItemToBag(Map<String, dynamic> item, {int quantity = 1}) async {
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      showNoInternetDialog(
        onRetry: () => addItemToBag(item, quantity: quantity),
      );
      return;
    }

    if (!_hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final qtyToAdd = quantity > 0 ? quantity : 1;
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
      return;
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
      } else {
        String errMsg = 'Failed to add item to bag';
        if (response.data is Map) {
          final map = response.data as Map;
          if (map['error'] is Map && map['error']['message'] != null) {
            errMsg = map['error']['message'].toString();
          } else if (map['message'] != null) {
            errMsg = map['message'].toString();
          }
        }
        Get.snackbar(
          'Unable to Add',
          errMsg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColor.error,
          colorText: AppColor.white,
        );
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
    } finally {
      isMutating.value = false;
    }
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
