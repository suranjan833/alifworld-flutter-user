/// Data models for the Shopping Bag and Cart module.
/// Represents cart line items, seller groupings, pricing breakdowns, and applied coupons.
class CartItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String? variantLabel;
  final String title;
  final String brand;
  final String? shopName;
  final String? sellerId;
  final double price;
  int quantity;
  final String image;
  final int? maxStock;
  final int? unitPriceMinor;
  final int? lineTotalMinor;

  CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    this.variantLabel,
    required this.title,
    this.brand = 'Alif',
    this.shopName,
    this.sellerId,
    required this.price,
    this.quantity = 1,
    this.image = '',
    this.maxStock,
    this.unitPriceMinor,
    this.lineTotalMinor,
  });

  /// Factory constructor to parse cart items from various API response shapes
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? productObj;
    Map<String, dynamic>? variantObj;

    if (json['variant'] is Map<String, dynamic>) {
      variantObj = json['variant'] as Map<String, dynamic>;
      if (variantObj['product'] is Map<String, dynamic>) {
        productObj = variantObj['product'] as Map<String, dynamic>;
      }
    }
    if (productObj == null && json['product'] is Map<String, dynamic>) {
      productObj = json['product'] as Map<String, dynamic>;
    }

    final String extractedId = json['id']?.toString() ??
        json['_id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final String extractedProductId = json['productId']?.toString() ??
        productObj?['id']?.toString() ??
        productObj?['_id']?.toString() ??
        extractedId;

    final String? extractedVariantId = json['variantId']?.toString() ??
        variantObj?['id']?.toString();

    final String? extractedVariantLabel = json['variantLabel']?.toString() ??
        variantObj?['label']?.toString() ??
        variantObj?['name']?.toString() ??
        json['variantName']?.toString();

    final String extractedTitle = json['title']?.toString() ??
        json['productName']?.toString() ??
        json['name']?.toString() ??
        productObj?['name']?.toString() ??
        productObj?['title']?.toString() ??
        'Product';

    final String extractedBrand = json['brand']?.toString() ??
        (productObj?['brand'] is Map
            ? (productObj!['brand'] as Map)['name']?.toString()
            : null) ??
        productObj?['brand']?.toString() ??
        productObj?['brandName']?.toString() ??
        'Alif';

    final String? extractedShopName = json['shopName']?.toString() ??
        productObj?['shopName']?.toString() ??
        (json['seller'] is Map ? json['seller']['shopName']?.toString() : null);

    final String? extractedSellerId = json['sellerId']?.toString() ??
        productObj?['sellerId']?.toString() ??
        (json['seller'] is Map ? json['seller']['id']?.toString() : null);

    // Calculate price from minor units (poisha) or standard currency
    double extractedPrice = 0.0;
    int? extractedUnitPriceMinor;
    int? extractedLineTotalMinor;

    final rawPriceMinor = json['unitPriceMinor'] ??
        json['priceMinor'] ??
        variantObj?['priceMinor'] ??
        productObj?['priceMinor'];

    if (rawPriceMinor is num) {
      extractedUnitPriceMinor = rawPriceMinor.toInt();
      extractedPrice = extractedUnitPriceMinor / 100.0;
    } else {
      final rawPrice = json['price'] ??
          variantObj?['price'] ??
          productObj?['price'];
      if (rawPrice is num) {
        extractedPrice = rawPrice.toDouble();
        extractedUnitPriceMinor = (extractedPrice * 100).round();
      } else if (rawPrice != null) {
        final clean = rawPrice
            .toString()
            .replaceAll('৳', '')
            .replaceAll('₹', '')
            .replaceAll('\$', '')
            .replaceAll(',', '')
            .trim();
        extractedPrice = double.tryParse(clean) ?? 0.0;
        extractedUnitPriceMinor = (extractedPrice * 100).round();
      }
    }

    final rawLineTotalMinor = json['lineTotalMinor'];
    if (rawLineTotalMinor is num) {
      extractedLineTotalMinor = rawLineTotalMinor.toInt();
    }

    int extractedQty = 1;
    final rawQty = json['qty'] ?? json['quantity'];
    if (rawQty is num) {
      extractedQty = rawQty.toInt();
    } else if (rawQty != null) {
      extractedQty = int.tryParse(rawQty.toString()) ?? 1;
    }

    String extractedImage = json['image']?.toString() ??
        json['imageUrl']?.toString() ??
        variantObj?['imageUrl']?.toString() ??
        productObj?['imageUrl']?.toString() ??
        json['thumbnail']?.toString() ??
        productObj?['image']?.toString() ??
        productObj?['thumbnail']?.toString() ??
        '';

    if (extractedImage.isEmpty && variantObj?['images'] is List) {
      final vImgs = variantObj!['images'] as List;
      if (vImgs.isNotEmpty && vImgs.first != null) {
        final f = vImgs.first;
        extractedImage = f is Map && f['fileUrl'] != null
            ? f['fileUrl'].toString()
            : f.toString();
      }
    }

    if (extractedImage.isEmpty && productObj?['images'] is List) {
      final images = productObj!['images'] as List;
      if (images.isNotEmpty && images.first != null) {
        final firstImg = images.first;
        extractedImage = firstImg is Map && firstImg['fileUrl'] != null
            ? firstImg['fileUrl'].toString()
            : firstImg.toString();
      }
    }

    if (extractedImage.isNotEmpty && !extractedImage.startsWith('http')) {
      extractedImage = 'https://alifworld.vercel.app$extractedImage';
    }

    int? extractedStock;
    final rawStock = json['stockQty'] ??
        json['maxStock'] ??
        variantObj?['stockQty'] ??
        productObj?['stockQty'];
    if (rawStock is num) {
      extractedStock = rawStock.toInt();
    }

    return CartItemModel(
      id: extractedId,
      productId: extractedProductId,
      variantId: extractedVariantId,
      variantLabel: extractedVariantLabel,
      title: extractedTitle,
      brand: extractedBrand,
      shopName: extractedShopName,
      sellerId: extractedSellerId,
      price: extractedPrice,
      quantity: extractedQty,
      image: extractedImage,
      maxStock: extractedStock,
      unitPriceMinor: extractedUnitPriceMinor,
      lineTotalMinor: extractedLineTotalMinor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      if (variantId != null) 'variantId': variantId,
      if (variantLabel != null) 'variantLabel': variantLabel,
      'title': title,
      'brand': brand,
      if (shopName != null) 'shopName': shopName,
      if (sellerId != null) 'sellerId': sellerId,
      'price': price,
      'quantity': quantity,
      'image': image,
      if (maxStock != null) 'maxStock': maxStock,
      if (unitPriceMinor != null) 'unitPriceMinor': unitPriceMinor,
      if (lineTotalMinor != null) 'lineTotalMinor': lineTotalMinor,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? variantId,
    String? variantLabel,
    String? title,
    String? brand,
    String? shopName,
    String? sellerId,
    double? price,
    int? quantity,
    String? image,
    int? maxStock,
    int? unitPriceMinor,
    int? lineTotalMinor,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      variantLabel: variantLabel ?? this.variantLabel,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      shopName: shopName ?? this.shopName,
      sellerId: sellerId ?? this.sellerId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      maxStock: maxStock ?? this.maxStock,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      lineTotalMinor: lineTotalMinor ?? this.lineTotalMinor,
    );
  }

  double get lineTotal => price * quantity;
  bool get inStock => maxStock == null || maxStock! > 0;
  String get formattedPrice => '৳${price.toStringAsFixed(2)}';
  String get formattedLineTotal => '৳${lineTotal.toStringAsFixed(2)}';
}

/// Seller grouping representation for multi-vendor shopping carts
class CartSellerGroupModel {
  final String sellerId;
  final String shopName;
  final List<CartItemModel> items;
  final int itemCount;
  final int subtotalMinor;
  final double subtotal;

  CartSellerGroupModel({
    required this.sellerId,
    required this.shopName,
    this.items = const [],
    this.itemCount = 0,
    this.subtotalMinor = 0,
    this.subtotal = 0.0,
  });

  factory CartSellerGroupModel.fromJson(Map<String, dynamic> json) {
    final List<CartItemModel> groupItems = [];
    if (json['items'] is List) {
      for (var e in json['items']) {
        if (e is Map<String, dynamic>) {
          groupItems.add(CartItemModel.fromJson(e));
        }
      }
    }

    final int minor = json['subtotalMinor'] is num
        ? (json['subtotalMinor'] as num).toInt()
        : 0;
    final double sub = minor > 0
        ? minor / 100.0
        : (json['subtotal'] is num ? (json['subtotal'] as num).toDouble() : 0.0);

    return CartSellerGroupModel(
      sellerId: json['sellerId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? 'Store',
      items: groupItems,
      itemCount: json['itemCount'] is num
          ? (json['itemCount'] as num).toInt()
          : groupItems.length,
      subtotalMinor: minor,
      subtotal: sub,
    );
  }
}

/// Pricing breakdown details for shopping cart
class CartPriceBreakdownModel {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalPayable;
  final String currency;
  final String currencySymbol;

  const CartPriceBreakdownModel({
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.totalPayable = 0.0,
    this.currency = 'BDT',
    this.currencySymbol = '৳',
  });

  String get formattedSubtotal => '$currencySymbol${subtotal.toStringAsFixed(2)}';
  String get formattedDelivery => deliveryFee == 0 ? 'FREE' : '$currencySymbol${deliveryFee.toStringAsFixed(2)}';
  String get formattedDiscount => '-$currencySymbol${discount.toStringAsFixed(2)}';
  String get formattedTotal => '$currencySymbol${totalPayable.toStringAsFixed(2)}';
}

/// Applied promotional coupon model
class CartCouponModel {
  final String code;
  final double discountAmount;
  final bool isFreeShipping;
  final String? description;

  const CartCouponModel({
    required this.code,
    this.discountAmount = 0.0,
    this.isFreeShipping = false,
    this.description,
  });
}

/// Overall Cart state container
class CartModel {
  final String? id;
  final List<CartItemModel> items;
  final List<CartSellerGroupModel> groups;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalAmount;
  final int totalPoints;
  final String currency;
  final String currencySymbol;

  CartModel({
    this.id,
    this.items = const [],
    this.groups = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.totalAmount = 0.0,
    this.totalPoints = 0,
    this.currency = 'BDT',
    this.currencySymbol = '৳',
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final List<CartItemModel> parsedItems = [];
    final rawItems = json['items'] ?? json['cartItems'] ?? json['lines'];

    if (rawItems is List) {
      for (var e in rawItems) {
        if (e is Map) {
          parsedItems.add(CartItemModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final List<CartSellerGroupModel> parsedGroups = [];
    if (json['groups'] is List) {
      for (var g in json['groups']) {
        if (g is Map) {
          final group = CartSellerGroupModel.fromJson(Map<String, dynamic>.from(g));
          parsedGroups.add(group);
          if (parsedItems.isEmpty && group.items.isNotEmpty) {
            parsedItems.addAll(group.items);
          }
        }
      }
    }

    double calcSubtotal = 0.0;
    final rawSubtotalMinor = json['subtotalMinor'];
    if (rawSubtotalMinor is num) {
      calcSubtotal = rawSubtotalMinor.toDouble() / 100.0;
    } else if (json['subtotal'] is num) {
      calcSubtotal = (json['subtotal'] as num).toDouble();
    } else {
      for (var item in parsedItems) {
        calcSubtotal += item.price * item.quantity;
      }
    }

    double calcDelivery = 0.0;
    if (json['shippingMinor'] is num) {
      calcDelivery = (json['shippingMinor'] as num).toDouble() / 100.0;
    } else if (json['deliveryFee'] is num) {
      calcDelivery = (json['deliveryFee'] as num).toDouble();
    } else if (json['shipping'] is num) {
      calcDelivery = (json['shipping'] as num).toDouble();
    } else {
      calcDelivery = calcSubtotal > 499 || calcSubtotal == 0 ? 0.0 : 49.0;
    }

    double calcDiscount = 0.0;
    if (json['discountMinor'] is num) {
      calcDiscount = (json['discountMinor'] as num).toDouble() / 100.0;
    } else if (json['discount'] is num) {
      calcDiscount = (json['discount'] as num).toDouble();
    }

    double calcTax = 0.0;
    if (json['taxMinor'] is num) {
      calcTax = (json['taxMinor'] as num).toDouble() / 100.0;
    } else if (json['tax'] is num) {
      calcTax = (json['tax'] as num).toDouble();
    } else {
      calcTax = calcSubtotal * 0.05;
    }

    double calcTotal = 0.0;
    if (json['totalMinor'] is num) {
      calcTotal = (json['totalMinor'] as num).toDouble() / 100.0;
    } else if (json['total'] is num) {
      calcTotal = (json['total'] as num).toDouble();
    } else if (json['totalAmount'] is num) {
      calcTotal = (json['totalAmount'] as num).toDouble();
    } else {
      calcTotal = calcSubtotal + calcDelivery + calcTax - calcDiscount;
    }

    return CartModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      items: parsedItems,
      groups: parsedGroups,
      subtotal: calcSubtotal,
      deliveryFee: calcDelivery,
      discount: calcDiscount,
      tax: calcTax,
      totalAmount: calcTotal > 0 ? calcTotal : 0.0,
      totalPoints: json['totalPoints'] is num ? (json['totalPoints'] as num).toInt() : 0,
      currency: json['currency']?.toString() ?? 'BDT',
      currencySymbol: json['currencySymbol']?.toString() ?? '৳',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'currency': currency,
      'currencySymbol': currencySymbol,
    };
  }

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}
