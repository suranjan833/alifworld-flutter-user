class CartItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String title;
  final String brand;
  final double price;
  int quantity;
  final String image;
  final int? maxStock;

  CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.title,
    this.brand = 'Alif',
    required this.price,
    this.quantity = 1,
    this.image = '',
    this.maxStock,
  });

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

    String extractedId = json['id']?.toString() ??
        json['_id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    String extractedProductId = json['productId']?.toString() ??
        productObj?['id']?.toString() ??
        productObj?['_id']?.toString() ??
        extractedId;

    String? extractedVariantId = json['variantId']?.toString() ??
        variantObj?['id']?.toString();

    String extractedTitle = json['title']?.toString() ??
        json['name']?.toString() ??
        productObj?['title']?.toString() ??
        productObj?['name']?.toString() ??
        'Product';

    String extractedBrand = json['brand']?.toString() ??
        (productObj?['brand'] is Map
            ? (productObj!['brand'] as Map)['name']?.toString()
            : null) ??
        productObj?['brand']?.toString() ??
        productObj?['brandName']?.toString() ??
        'Alif';

    double extractedPrice = 0.0;
    final rawPriceMinor = json['unitPriceMinor'] ??
        json['priceMinor'] ??
        json['lineTotalMinor'] ??
        variantObj?['priceMinor'] ??
        productObj?['priceMinor'];
    if (rawPriceMinor is num) {
      extractedPrice = rawPriceMinor / 100.0;
    } else {
      final rawPrice = json['price'] ??
          variantObj?['price'] ??
          productObj?['price'];
      if (rawPrice is num) {
        extractedPrice = rawPrice.toDouble();
      } else if (rawPrice != null) {
        final clean = rawPrice
            .toString()
            .replaceAll('৳', '')
            .replaceAll('₹', '')
            .replaceAll('\$', '')
            .replaceAll(',', '')
            .trim();
        extractedPrice = double.tryParse(clean) ?? 0.0;
      }
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
        if (f is Map && f['fileUrl'] != null) {
          extractedImage = f['fileUrl'].toString();
        } else {
          extractedImage = f.toString();
        }
      }
    }

    if (extractedImage.isEmpty && productObj?['images'] is List) {
      final images = productObj!['images'] as List;
      if (images.isNotEmpty && images.first != null) {
        final firstImg = images.first;
        if (firstImg is Map && firstImg['fileUrl'] != null) {
          extractedImage = firstImg['fileUrl'].toString();
        } else {
          extractedImage = firstImg.toString();
        }
      }
    }

    if (extractedImage.isNotEmpty && !extractedImage.startsWith('http')) {
      extractedImage = 'https://alifworld.vercel.app$extractedImage';
    }

    return CartItemModel(
      id: extractedId,
      productId: extractedProductId,
      variantId: extractedVariantId,
      title: extractedTitle,
      brand: extractedBrand,
      price: extractedPrice,
      quantity: extractedQty,
      image: extractedImage,
      maxStock: json['maxStock'] is int ? json['maxStock'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'title': title,
      'brand': brand,
      'price': price,
      'quantity': quantity,
      'image': image,
      if (maxStock != null) 'maxStock': maxStock,
    };
  }
}

class CartModel {
  final String? id;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalAmount;

  CartModel({
    this.id,
    this.items = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.totalAmount = 0.0,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> parsedItems = [];
    final rawItems = json['items'] ?? json['cartItems'] ?? json['lines'];
    if (rawItems is List) {
      for (var e in rawItems) {
        if (e is Map) {
          try {
            parsedItems.add(
              CartItemModel.fromJson(Map<String, dynamic>.from(e)),
            );
          } catch (_) {}
        }
      }
    }
    if (parsedItems.isEmpty && json['groups'] is List) {
      for (var g in json['groups']) {
        if (g is Map && g['items'] is List) {
          for (var e in g['items']) {
            if (e is Map) {
              try {
                parsedItems.add(
                  CartItemModel.fromJson(Map<String, dynamic>.from(e)),
                );
              } catch (_) {}
            }
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
    if (json['deliveryFee'] is num) {
      calcDelivery = (json['deliveryFee'] as num).toDouble();
    } else if (json['shipping'] is num) {
      calcDelivery = (json['shipping'] as num).toDouble();
    } else {
      calcDelivery = calcSubtotal > 499 || calcSubtotal == 0 ? 0.0 : 49.0;
    }

    double calcDiscount = 0.0;
    if (json['discount'] is num) {
      calcDiscount = (json['discount'] as num).toDouble();
    }

    double calcTax = 0.0;
    if (json['tax'] is num) {
      calcTax = (json['tax'] as num).toDouble();
    } else {
      calcTax = calcSubtotal * 0.05;
    }

    double calcTotal = 0.0;
    if (json['total'] is num) {
      calcTotal = (json['total'] as num).toDouble();
    } else if (json['totalAmount'] is num) {
      calcTotal = (json['totalAmount'] as num).toDouble();
    } else {
      calcTotal = calcSubtotal + calcDelivery + calcTax - calcDiscount;
    }

    return CartModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      items: parsedItems,
      subtotal: calcSubtotal,
      deliveryFee: calcDelivery,
      discount: calcDiscount,
      tax: calcTax,
      totalAmount: calcTotal > 0 ? calcTotal : 0.0,
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
    };
  }
}
