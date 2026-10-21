// ignore_for_file: library_prefixes

import 'dart:convert';
import 'package:dio/dio.dart' as DIO;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';
import '../../../routes/app_pages.dart';
import '../../product_details/models/product_details_model.dart';
import '../models/cart_model.dart';

class BagController extends GetxController with SkeletonLoadingMixin {
  final cartItems = <CartItemModel>[].obs;
  static const String _localCartStorageKey = 'LOCAL_CART_ITEMS_V1';

  bool get _hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty);
  }

  @override
  void onInit() {
    super.onInit();
    _loadLocalCart();

    if (!_hasAuth) {
      isLoading.value = false;
    } else {
      if (cartItems.isEmpty) {
        isLoading.value = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCart(showLoading: cartItems.isEmpty);
    });
  }

  void _saveLocalCart() {
    try {
      final jsonList = cartItems.map((e) => e.toJson()).toList();
      getBox.write(_localCartStorageKey, jsonList);
    } catch (_) {}
  }

  void _loadLocalCart() {
    try {
      final saved = getBox.read(_localCartStorageKey);
      if (saved is List && saved.isNotEmpty) {
        final list = <CartItemModel>[];
        for (var e in saved) {
          if (e is Map) {
            list.add(CartItemModel.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        if (list.isNotEmpty) {
          cartItems.assignAll(list);
        }
      }
    } catch (_) {}
  }

  /// 1. GET /cart - Fetch user's cart from API
  Future<void> fetchCart({bool showLoading = true}) async {
    if (showLoading && cartItems.isEmpty) {
      isLoading.value = true;
    }

    if (!_hasAuth) {
      isLoading.value = false;
      return;
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

        // If server returns items, update cart and cache locally
        if (incomingItems.isNotEmpty) {
          cartItems.assignAll(incomingItems);
          _saveLocalCart();
        } else if (cartItems.isNotEmpty) {
          // Server cart is empty but local cart has items - attempt to sync local items to server
          bool syncedAny = false;
          for (var item in cartItems) {
            final vId = item.variantId;
            if (vId != null && vId.isNotEmpty && vId != item.productId) {
              try {
                final syncRes = await dioPost(
                  endUrl: 'cart',
                  data: {'variantId': vId, 'qty': item.quantity},
                  isJson: true,
                );
                if (syncRes.statusCode == 200 || syncRes.statusCode == 201) {
                  syncedAny = true;
                }
              } catch (_) {}
            }
          }
          if (syncedAny) {
            // Re-fetch after syncing
            final reRes = await dioGet('cart');
            if (reRes.statusCode == 200 && reRes.data != null) {
              dynamic reRaw = reRes.data;
              if (reRaw is Map && reRaw.containsKey('data')) {
                reRaw = reRaw['data'];
              }
              if (reRaw is Map) {
                final reModel =
                    CartModel.fromJson(Map<String, dynamic>.from(reRaw));
                if (reModel.items.isNotEmpty) {
                  cartItems.assignAll(reModel.items);
                  _saveLocalCart();
                }
              }
            }
          } else {
            // No valid items could be synced; reflect server empty state
            cartItems.clear();
            _saveLocalCart();
          }
        } else {
          cartItems.clear();
          _saveLocalCart();
        }
      }
    } catch (_) {
      // Keep existing local cart on failure so items do not disappear unexpectedly
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh handler
  Future<void> refreshCart() async {
    await fetchCart(showLoading: false);
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
  double get tax => subtotal * 0.05;
  double get totalAmount => subtotal + deliveryFee + tax;

  /// 2. PATCH /cart/items/{id} - Increment quantity
  Future<void> incrementQuantity(int index) async {
    final item = cartItems[index];
    final newQty = item.quantity + 1;
    item.quantity = newQty;
    cartItems.refresh();
    _saveLocalCart();

    if (_hasAuth) {
      try {
        await dioPatch(
          endUrl: 'cart/items/${item.id}',
          data: {'qty': newQty},
          isJson: true,
        );
      } catch (_) {}
    }
  }

  /// 3. PATCH /cart/items/{id} - Decrement quantity
  Future<void> decrementQuantity(int index) async {
    final item = cartItems[index];
    final currentQty = item.quantity;
    if (currentQty > 1) {
      final newQty = currentQty - 1;
      item.quantity = newQty;
      cartItems.refresh();
      _saveLocalCart();

      if (_hasAuth) {
        try {
          await dioPatch(
            endUrl: 'cart/items/${item.id}',
            data: {'qty': newQty},
            isJson: true,
          );
        } catch (_) {}
      }
    } else {
      removeItem(index);
    }
  }

  /// 4. DELETE /cart/items/{id} - Remove single item
  Future<void> removeItem(int index) async {
    final removed = cartItems.removeAt(index);
    _saveLocalCart();

    Get.snackbar(
      'Removed',
      '${removed.title} removed from bag',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.textPrimary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    if (_hasAuth) {
      try {
        await dioDelete('cart/items/${removed.id}');
      } catch (_) {}
    }
  }

  /// 5. POST /cart - Add item to bag
  Future<void> addItemToBag(Map<String, dynamic> item, {int quantity = 1}) async {
    final qtyToAdd = quantity > 0 ? quantity : 1;
    final prodId = item['productId']?.toString() ??
        item['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

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

    // If still missing, we use prodId as fallback for local item model
    final fallbackVariantId = (variantId != null && variantId.isNotEmpty)
        ? variantId
        : prodId;

    final existingIndex = cartItems.indexWhere(
      (element) =>
          (element.productId == prodId || element.id == prodId) &&
          (element.variantId == fallbackVariantId ||
              element.variantId == variantId),
    );

    if (existingIndex != -1) {
      final existingItem = cartItems[existingIndex];
      final newQty = existingItem.quantity + qtyToAdd;
      existingItem.quantity = newQty;
      cartItems.refresh();
      _saveLocalCart();

      if (_hasAuth) {
        try {
          await dioPatch(
            endUrl: 'cart/items/${existingItem.id}',
            data: {'qty': newQty},
            isJson: true,
          );
        } catch (_) {}
      }
    } else {
      double priceVal = 0.0;
      final rawPriceMinor = item['priceMinor'];
      if (rawPriceMinor is num) {
        priceVal = rawPriceMinor / 100.0;
      } else {
        final rawPrice = item['rawPrice'] ?? item['price'];
        if (rawPrice is num) {
          priceVal = rawPrice.toDouble();
        } else if (rawPrice is String) {
          priceVal =
              double.tryParse(
                rawPrice
                    .replaceAll('৳', '')
                    .replaceAll('₹', '')
                    .replaceAll('\$', '')
                    .replaceAll(',', '')
                    .trim(),
              ) ??
              0.0;
        }
      }

      final newItem = CartItemModel(
        id: prodId,
        productId: prodId,
        variantId: fallbackVariantId,
        brand: item['brand']?.toString() ??
            item['brandName']?.toString() ??
            'Alif',
        title:
            item['title']?.toString() ?? item['name']?.toString() ?? 'Product',
        price: priceVal,
        quantity: qtyToAdd,
        image: item['image']?.toString() ?? '',
      );

      cartItems.add(newItem);
      _saveLocalCart();

      // Only attempt server POST if authenticated and we have a valid variantId distinct from prodId
      if (_hasAuth && variantId != null && variantId != prodId) {
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
            await fetchCart(showLoading: false);
          }
        } catch (_) {}
      }
    }
  }

  /// 6. DELETE /cart - Clear whole cart
  Future<void> clearCart() async {
    cartItems.clear();
    _saveLocalCart();

    if (_hasAuth) {
      try {
        await dioDelete('cart');
      } catch (_) {}
    }
  }

  void proceedToCheckout() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Empty Bag',
        'Please add items to your bag before checking out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.error,
        colorText: Colors.white,
      );
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
}
