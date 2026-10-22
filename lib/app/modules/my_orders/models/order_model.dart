class OrderItemModel {
  final String id;
  final String name;
  final String image;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.id,
    required this.name,
    this.image = '',
    this.quantity = 1,
    this.price = 0.0,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? prod =
        json['product'] is Map<String, dynamic> ? json['product'] : null;

    double parsedPrice = 0.0;
    if (json['unitPriceMinor'] is num) {
      parsedPrice = (json['unitPriceMinor'] as num) / 100.0;
    } else if (json['lineTotalMinor'] is num && (json['qty'] is num || json['quantity'] is num)) {
      final q = (json['qty'] ?? json['quantity']) as num;
      parsedPrice = (json['lineTotalMinor'] as num) / (q > 0 ? q * 100.0 : 100.0);
    } else if (json['priceMinor'] is num) {
      parsedPrice = (json['priceMinor'] as num) / 100.0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    } else if (prod?['priceMinor'] is num) {
      parsedPrice = (prod!['priceMinor'] as num) / 100.0;
    }

    String img = json['thumbnailUrl']?.toString() ??
        json['image']?.toString() ??
        json['thumbnail']?.toString() ??
        prod?['image']?.toString() ??
        '';

    if (img.isEmpty && prod?['images'] is List && (prod!['images'] as List).isNotEmpty) {
      img = prod['images'][0].toString();
    }

    return OrderItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['productName']?.toString() ??
          json['name']?.toString() ??
          json['title']?.toString() ??
          prod?['name']?.toString() ??
          'Product',
      image: img,
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : (json['qty'] is num
              ? (json['qty'] as num).toInt()
              : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1),
      price: parsedPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String date;
  final String status;
  final double totalAmount;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final int itemCount;
  final List<OrderItemModel> items;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? address;
  final String? recipientName;
  final String? phone;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    this.itemCount = 1,
    this.items = const [],
    this.paymentMethod,
    this.paymentStatus,
    this.address,
    this.recipientName,
    this.phone,
  });

  String get formattedTotal => '৳${totalAmount.toStringAsFixed(2)}';
  String get formattedSubtotal =>
      '৳${(subtotal > 0 ? subtotal : totalAmount).toStringAsFixed(2)}';
  String get formattedShipping =>
      shippingFee == 0 ? 'FREE' : '৳${shippingFee.toStringAsFixed(2)}';

  /// Active timeline stage index (0: Placed, 1: Shipped, 2: Nearest Zone, 3: Out for Delivery, 4: Delivered)
  int get trackingStage {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return 4;
    if (s.contains('out for delivery')) return 3;
    if (s.contains('zone') || s.contains('hub') || s.contains('nearest')) return 2;
    if (s.contains('shipped') || s.contains('transit') || s.contains('dispatched')) {
      return 1;
    }
    // Default for active in progress orders:
    return 1;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final code = json['orderNumber']?.toString() ??
        json['orderCode']?.toString() ??
        (rawId.length > 8
            ? '#ALF-${rawId.substring(rawId.length - 6).toUpperCase()}'
            : '#ALF-$rawId');

    // Parse created date
    String formattedDate = 'Recently';
    final rawDate = json['placedAt']?.toString() ??
        json['createdAt']?.toString() ??
        json['date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        formattedDate = rawDate;
      }
    }

    // Map status enum to user-friendly status
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'in progress';
    String userStatus = 'In Progress';
    if (rawStatus.contains('deliver') || rawStatus == 'completed') {
      userStatus = 'Delivered';
    } else if (rawStatus.contains('cancel') || rawStatus == 'rejected') {
      userStatus = 'Cancelled';
    } else if (rawStatus.contains('progress') ||
        rawStatus.contains('process') ||
        rawStatus.contains('pending') ||
        rawStatus.contains('shipped')) {
      userStatus = 'In Progress';
    }

    // Money minor units
    double total = 0.0;
    if (json['totalMinor'] is num) {
      total = (json['totalMinor'] as num) / 100.0;
    } else if (json['totalAmount'] is num) {
      total = (json['totalAmount'] as num).toDouble();
    } else if (json['total'] is num) {
      total = (json['total'] as num).toDouble();
    }

    double calcSubtotal = 0.0;
    if (json['subtotalMinor'] is num) {
      calcSubtotal = (json['subtotalMinor'] as num) / 100.0;
    } else if (json['subtotal'] is num) {
      calcSubtotal = (json['subtotal'] as num).toDouble();
    }

    double calcShipping = 0.0;
    if (json['shippingMinor'] is num) {
      calcShipping = (json['shippingMinor'] as num) / 100.0;
    } else if (json['deliveryFee'] is num) {
      calcShipping = (json['deliveryFee'] as num).toDouble();
    }

    double calcDiscount = 0.0;
    if (json['discountMinor'] is num) {
      calcDiscount = (json['discountMinor'] as num) / 100.0;
    } else if (json['discount'] is num) {
      calcDiscount = (json['discount'] as num).toDouble();
    }

    // Items list
    List<OrderItemModel> parsedItems = [];
    final rawItems = json['items'] ?? json['orderItems'] ?? json['lines'];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderItemModel.fromJson(e))
          .toList();
    }

    final count = json['itemCount'] is num
        ? (json['itemCount'] as num).toInt()
        : (parsedItems.isNotEmpty ? parsedItems.length : 1);

    if (calcSubtotal == 0.0 && parsedItems.isNotEmpty) {
      calcSubtotal = parsedItems.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
    }

    final addrObj = json['addressSnapshot'] is Map
        ? json['addressSnapshot'] as Map
        : (json['address'] is Map ? json['address'] as Map : null);

    String? formattedAddress;
    if (addrObj != null) {
      final line = addrObj['addressLine']?.toString() ?? '';
      final upazila = addrObj['upazila']?.toString() ?? '';
      final district = addrObj['district']?.toString() ?? '';
      final division = addrObj['division']?.toString() ?? '';
      final postal = addrObj['postalCode']?.toString() ?? '';
      final parts = [line, upazila, district, division, postal]
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        formattedAddress = parts.join(', ');
      }
    }

    return OrderModel(
      id: rawId,
      orderId: code,
      date: formattedDate,
      status: userStatus,
      totalAmount: total > 0 ? total : (calcSubtotal > 0 ? calcSubtotal : 999.0),
      subtotal: calcSubtotal > 0 ? calcSubtotal : total,
      shippingFee: calcShipping,
      discount: calcDiscount,
      itemCount: count,
      items: parsedItems,
      paymentMethod: json['paymentMethod']?.toString() ??
          (json['batch'] is Map ? (json['batch'] as Map)['paymentMethod']?.toString() : null),
      paymentStatus: json['paymentStatus']?.toString() ??
          (json['batch'] is Map ? (json['batch'] as Map)['paymentStatus']?.toString() : null),
      address: formattedAddress ??
          json['address']?.toString() ??
          json['deliveryAddress']?.toString() ??
          addrObj?['addressLine']?.toString(),
      recipientName: addrObj?['fullName']?.toString() ??
          json['recipientName']?.toString() ??
          json['customerName']?.toString(),
      phone: addrObj?['phone']?.toString() ?? json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'date': date,
      'status': status,
      'total': formattedTotal,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'itemCount': itemCount,
      'items': items.map((e) => e.toJson()).toList(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (address != null) 'address': address,
      if (recipientName != null) 'recipientName': recipientName,
      if (phone != null) 'phone': phone,
    };
  }
}
