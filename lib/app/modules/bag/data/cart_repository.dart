import 'dart:developer' as developer;
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../models/cart_model.dart';

/// Data Repository for handling shopping cart network operations.
/// Interacts directly with the backend REST endpoints to fetch, add, update,
/// delete, and quote items without relying on local cache storage.
class CartRepository {
  static final CartRepository _instance = CartRepository._internal();
  factory CartRepository() => _instance;
  CartRepository._internal();

  /// 1. GET /cart - Fetch latest active cart from server
  Future<CartModel?> fetchRemoteCart() async {
    try {
      final response = await dioGet('cart');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          return CartModel.fromJson(rawData);
        }
      }
      return null;
    } catch (e, stack) {
      developer.log(
        'CartRepository.fetchRemoteCart failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// 2. POST /cart - Add item/variant to cart on server
  Future<bool> addItemToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      final payload = <String, dynamic>{
        'productId': productId,
        'qty': quantity,
        if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      };

      final response = await dioPost(
        endUrl: 'cart',
        data: payload,
        isJson: true,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      developer.log(
        'CartRepository.addItemToCart failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 3. PATCH /cart/items/:id - Update item quantity on server
  Future<bool> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    try {
      if (itemId.isEmpty || quantity < 1) return false;

      final response = await dioPatch(
        endUrl: 'cart/items/$itemId',
        data: {'qty': quantity},
        isJson: true,
      );

      return response.statusCode == 200;
    } catch (e, stack) {
      developer.log(
        'CartRepository.updateQuantity failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 4. DELETE /cart/items/:id - Remove item from server cart
  Future<bool> deleteItem(String itemId) async {
    try {
      if (itemId.isEmpty) return false;

      final response = await dioDelete('cart/items/$itemId');

      return response.statusCode == 200;
    } catch (e, stack) {
      developer.log(
        'CartRepository.deleteItem failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 5. DELETE /cart - Clear all items from server cart
  Future<bool> clearAllItems() async {
    try {
      final response = await dioDelete('cart');

      return response.statusCode == 200;
    } catch (e, stack) {
      developer.log(
        'CartRepository.clearAllItems failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 6. POST /checkout/quote - Fetch price quote and order lines calculation
  Future<Map<String, dynamic>?> fetchCheckoutQuotation({
    String? addressId,
    String paymentMethod = 'cod',
    String? couponCode,
  }) async {
    try {
      final payload = <String, dynamic>{
        'paymentMethod': paymentMethod,
        if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
      };

      final response = await dioPost(
        endUrl: 'checkout/quote',
        data: payload,
        isJson: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          return rawData;
        }
      }
      return null;
    } catch (e, stack) {
      developer.log(
        'CartRepository.fetchCheckoutQuotation failed: $e',
        name: 'CartRepository',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Validate current cart items against in-stock constraints
  bool validateStockAvailability(List<CartItemModel> items) {
    if (items.isEmpty) return false;
    for (final item in items) {
      if (item.maxStock != null && item.quantity > item.maxStock!) {
        return false;
      }
    }
    return true;
  }
}
