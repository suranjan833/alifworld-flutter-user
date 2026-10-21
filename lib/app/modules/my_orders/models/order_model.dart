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
    if (json['priceMinor'] is num) {
      parsedPrice = (json['priceMinor'] as num) / 100.0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    } else if (prod?['priceMinor'] is num) {
      parsedPrice = (prod!['priceMinor'] as num) / 100.0;
    }

    String img = json['image']?.toString() ??
        json['thumbnail']?.toString() ??
        prod?['image']?.toString() ??
        '';

    if (img.isEmpty && prod?['images'] is List && (prod!['images'] as List).isNotEmpty) {
      img = prod['images'][0].toString();
    }

    return OrderItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ??
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
  final int itemCount;
  final List<OrderItemModel> items;
  final String? paymentMethod;
  final String? address;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.itemCount = 1,
    this.items = const [],
    this.paymentMethod,
    this.address,
  });

  String get formattedTotal => '৳${totalAmount.toStringAsFixed(2)}';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final code = json['orderNumber']?.toString() ??
        json['orderCode']?.toString() ??
        (rawId.length > 8 ? '#ALF-${rawId.substring(rawId.length - 6).toUpperCase()}' : '#ALF-$rawId');

    // Parse created date
    String formattedDate = 'Recently';
    final rawDate = json['createdAt']?.toString() ?? json['date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        formattedDate = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
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

    return OrderModel(
      id: rawId,
      orderId: code,
      date: formattedDate,
      status: userStatus,
      totalAmount: total > 0 ? total : 999.0,
      itemCount: count,
      items: parsedItems,
      paymentMethod: json['paymentMethod']?.toString(),
      address: json['address']?.toString() ?? json['deliveryAddress']?.toString(),
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
      'itemCount': itemCount,
      'items': items.map((e) => e.toJson()).toList(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (address != null) 'address': address,
    };
  }
}
