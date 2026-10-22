class OrderItemModel {
  final String id;
  final String productId;
  final String name;
  final String variantName;
  final String image;
  final int quantity;
  final double price;
  final double lineTotal;

  OrderItemModel({
    required this.id,
    this.productId = '',
    required this.name,
    this.variantName = '',
    this.image = '',
    this.quantity = 1,
    this.price = 0.0,
    this.lineTotal = 0.0,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? prod =
        json['product'] is Map<String, dynamic> ? json['product'] : null;

    double parsedPrice = 0.0;
    if (json['unitPriceMinor'] is num) {
      parsedPrice = (json['unitPriceMinor'] as num) / 100.0;
    } else if (json['priceMinor'] is num) {
      parsedPrice = (json['priceMinor'] as num) / 100.0;
    } else if (json['lineTotalMinor'] is num &&
        (json['qty'] is num || json['quantity'] is num)) {
      final q = (json['qty'] ?? json['quantity']) as num;
      parsedPrice =
          (json['lineTotalMinor'] as num) / (q > 0 ? q * 100.0 : 100.0);
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    } else if (prod?['priceMinor'] is num) {
      parsedPrice = (prod!['priceMinor'] as num) / 100.0;
    }

    final q = json['qty'] is num
        ? (json['qty'] as num).toInt()
        : (json['quantity'] is num
            ? (json['quantity'] as num).toInt()
            : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1);

    double parsedLineTotal = 0.0;
    if (json['lineTotalMinor'] is num) {
      parsedLineTotal = (json['lineTotalMinor'] as num) / 100.0;
    } else {
      parsedLineTotal = parsedPrice * q;
    }

    String img = json['thumbnailUrl']?.toString() ??
        json['image']?.toString() ??
        json['thumbnail']?.toString() ??
        prod?['image']?.toString() ??
        '';

    if (img.isEmpty &&
        prod?['images'] is List &&
        (prod!['images'] as List).isNotEmpty) {
      img = prod['images'][0].toString();
    }

    final variant = json['variantName']?.toString() ?? '';
    final name = json['productName']?.toString() ??
        json['name']?.toString() ??
        json['title']?.toString() ??
        prod?['name']?.toString() ??
        'Product';

    return OrderItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      productId:
          json['productId']?.toString() ?? prod?['id']?.toString() ?? '',
      name: name,
      variantName: variant,
      image: img,
      quantity: q,
      price: parsedPrice,
      lineTotal: parsedLineTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'variantName': variantName,
      'image': image,
      'quantity': quantity,
      'price': price,
      'lineTotal': lineTotal,
    };
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String date;
  final String status;
  final String backendStatus;
  final double totalAmount;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double walletPaid;
  final double remainingPayable;
  final int itemCount;
  final List<OrderItemModel> items;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? address;
  final String? recipientName;
  final String? phone;
  final String? sellerName;
  final bool openBoxDelivery;
  final String? deliveryOtp;
  final List<Map<String, dynamic>> timeline;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.date,
    required this.status,
    this.backendStatus = 'pending',
    required this.totalAmount,
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    this.walletPaid = 0.0,
    this.remainingPayable = 0.0,
    this.itemCount = 1,
    this.items = const [],
    this.paymentMethod,
    this.paymentStatus,
    this.address,
    this.recipientName,
    this.phone,
    this.sellerName,
    this.openBoxDelivery = false,
    this.deliveryOtp,
    this.timeline = const [],
  });

  OrderModel copyWith({
    String? id,
    String? orderId,
    String? date,
    String? status,
    String? backendStatus,
    double? totalAmount,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? walletPaid,
    double? remainingPayable,
    int? itemCount,
    List<OrderItemModel>? items,
    String? paymentMethod,
    String? paymentStatus,
    String? address,
    String? recipientName,
    String? phone,
    String? sellerName,
    bool? openBoxDelivery,
    String? deliveryOtp,
    List<Map<String, dynamic>>? timeline,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      date: date ?? this.date,
      status: status ?? this.status,
      backendStatus: backendStatus ?? this.backendStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      walletPaid: walletPaid ?? this.walletPaid,
      remainingPayable: remainingPayable ?? this.remainingPayable,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      address: address ?? this.address,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      sellerName: sellerName ?? this.sellerName,
      openBoxDelivery: openBoxDelivery ?? this.openBoxDelivery,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      timeline: timeline ?? this.timeline,
    );
  }

  factory OrderModel.placeholder({String id = ''}) {
    return OrderModel(
      id: id,
      orderId: id.isNotEmpty
          ? (id.length > 8
              ? '#ALF-${id.substring(id.length - 6).toUpperCase()}'
              : '#ALF-$id')
          : '#ALF-PENDING',
      date: 'Recently',
      status: 'In Progress',
      backendStatus: 'pending',
      totalAmount: 0.0,
      subtotal: 0.0,
      shippingFee: 0.0,
      itemCount: 1,
      items: const [],
    );
  }

  String get formattedTotal => '৳${totalAmount.toStringAsFixed(2)}';
  String get formattedSubtotal =>
      '৳${(subtotal > 0 ? subtotal : totalAmount).toStringAsFixed(2)}';
  String get formattedShipping =>
      shippingFee == 0 ? 'FREE' : '৳${shippingFee.toStringAsFixed(2)}';

  String get formattedPaymentMethod {
    final method = (paymentMethod ?? 'Cash on Delivery').toLowerCase();
    if (method.contains('wallet')) {
      if (walletPaid > 0 && remainingPayable > 0) {
        return 'Alif Wallet + Cash on Delivery';
      }
      return 'Alif Wallet';
    }
    if (method.contains('cod') || method.contains('cash')) {
      return 'Cash on Delivery';
    }
    return paymentMethod ?? 'Cash on Delivery';
  }

  String get formattedPaymentStatus {
    final status = (paymentStatus ?? '').toLowerCase().trim();
    if (status.isEmpty) {
      if (walletPaid > 0 && remainingPayable > 0) return 'Partially Paid';
      return 'Pending';
    }
    switch (status) {
      case 'partially_paid':
        return 'Partially Paid';
      case 'paid':
        return 'Paid';
      case 'cod_pending':
        return 'COD Pending';
      case 'unpaid':
        return 'Unpaid';
      case 'failed':
        return 'Failed';
      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
    }
  }

  /// Active timeline stage index (0: Placed, 1: Shipped, 2: Nearest Zone, 3: Out for Delivery, 4: Delivered)
  int get trackingStage {
    final s = (backendStatus.isNotEmpty ? backendStatus : status).toLowerCase();
    if (s == 'delivered' || s == 'completed') return 4;
    if (s.contains('out for delivery') || s == 'out_for_delivery') return 3;
    if (s.contains('zone') || s.contains('hub') || s.contains('nearest')) return 2;
    if (s.contains('shipped') || s.contains('transit') || s.contains('dispatched')) {
      return 1;
    }
    if (s.contains('pending') || s.contains('placed') || s.contains('received')) {
      return 0;
    }
    return 0;
  }

  factory OrderModel.fromJson(Map<String, dynamic> rawInput) {
    var json = rawInput;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      json = json['data'] as Map<String, dynamic>;
    }
    if (json.containsKey('order') && json['order'] is Map<String, dynamic>) {
      json = json['order'] as Map<String, dynamic>;
    }

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
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'pending';
    String userStatus = 'In Progress';
    if (rawStatus.contains('deliver') || rawStatus == 'completed') {
      userStatus = 'Delivered';
    } else if (rawStatus.contains('cancel') || rawStatus == 'rejected') {
      userStatus = 'Cancelled';
    } else if (rawStatus.contains('progress') ||
        rawStatus.contains('process') ||
        rawStatus.contains('pending') ||
        rawStatus.contains('shipped') ||
        rawStatus.contains('placed')) {
      userStatus = 'In Progress';
    }

    // Money minor units
    double total = 0.0;
    if (json['totalMinor'] is num) {
      total = (json['totalMinor'] as num) / 100.0;
    } else if (json['batchTotalMinor'] is num) {
      total = (json['batchTotalMinor'] as num) / 100.0;
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

    double walletPaidAmount = 0.0;
    if (json['walletPaidMinor'] is num) {
      walletPaidAmount = (json['walletPaidMinor'] as num) / 100.0;
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

    if (total == 0.0 && calcSubtotal > 0) {
      total = calcSubtotal + calcShipping - calcDiscount;
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

    final sellerMap = json['seller'] is Map ? json['seller'] as Map : null;
    final sName = sellerMap?['shopName']?.toString();

    List<Map<String, dynamic>> parsedTimeline = [];
    if (json['timeline'] is List) {
      parsedTimeline = (json['timeline'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    final remaining = (total - walletPaidAmount) > 0 ? (total - walletPaidAmount) : 0.0;

    return OrderModel(
      id: rawId,
      orderId: code,
      date: formattedDate,
      status: userStatus,
      backendStatus: rawStatus,
      totalAmount: total,
      subtotal: calcSubtotal > 0 ? calcSubtotal : total,
      shippingFee: calcShipping,
      discount: calcDiscount,
      walletPaid: walletPaidAmount,
      remainingPayable: remaining,
      itemCount: count,
      items: parsedItems,
      paymentMethod: json['paymentMethod']?.toString() ??
          (json['batch'] is Map
              ? (json['batch'] as Map)['paymentMethod']?.toString()
              : null),
      paymentStatus: json['paymentStatus']?.toString() ??
          (json['batch'] is Map
              ? (json['batch'] as Map)['paymentStatus']?.toString()
              : null),
      address: formattedAddress ??
          json['address']?.toString() ??
          json['deliveryAddress']?.toString() ??
          addrObj?['addressLine']?.toString(),
      recipientName: addrObj?['fullName']?.toString() ??
          json['recipientName']?.toString() ??
          json['customerName']?.toString(),
      phone: addrObj?['phone']?.toString() ?? json['phone']?.toString(),
      sellerName: sName,
      openBoxDelivery: json['openBoxDelivery'] == true,
      deliveryOtp: json['deliveryOtp']?.toString(),
      timeline: parsedTimeline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'date': date,
      'status': status,
      'backendStatus': backendStatus,
      'total': formattedTotal,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'walletPaid': walletPaid,
      'remainingPayable': remainingPayable,
      'itemCount': itemCount,
      'items': items.map((e) => e.toJson()).toList(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (address != null) 'address': address,
      if (recipientName != null) 'recipientName': recipientName,
      if (phone != null) 'phone': phone,
      if (sellerName != null) 'sellerName': sellerName,
      'openBoxDelivery': openBoxDelivery,
      if (deliveryOtp != null) 'deliveryOtp': deliveryOtp,
      'timeline': timeline,
    };
  }
}
