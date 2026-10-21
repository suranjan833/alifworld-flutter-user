class CheckoutQuoteModel {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalAmount;
  final String? couponCode;
  final bool isValid;

  CheckoutQuoteModel({
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.totalAmount = 0.0,
    this.couponCode,
    this.isValid = true,
  });

  factory CheckoutQuoteModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) return double.tryParse(val.toString()) ?? 0.0;
      return 0.0;
    }

    // Money in minor units in backend (divide by 100 if minor unit)
    double sTotal = 0.0;
    if (json['subtotalMinor'] is num) {
      sTotal = (json['subtotalMinor'] as num) / 100.0;
    } else {
      sTotal = parseAmount(json['subtotal']);
    }

    double dFee = 0.0;
    if (json['deliveryFeeMinor'] is num) {
      dFee = (json['deliveryFeeMinor'] as num) / 100.0;
    } else if (json['shippingMinor'] is num) {
      dFee = (json['shippingMinor'] as num) / 100.0;
    } else {
      dFee = parseAmount(json['deliveryFee'] ?? json['shipping']);
    }

    double disc = 0.0;
    if (json['discountMinor'] is num) {
      disc = (json['discountMinor'] as num) / 100.0;
    } else {
      disc = parseAmount(json['discount']);
    }

    double tTax = 0.0;
    if (json['taxMinor'] is num) {
      tTax = (json['taxMinor'] as num) / 100.0;
    } else {
      tTax = parseAmount(json['tax']);
    }

    double tot = 0.0;
    if (json['totalMinor'] is num) {
      tot = (json['totalMinor'] as num) / 100.0;
    } else if (json['totalAmountMinor'] is num) {
      tot = (json['totalAmountMinor'] as num) / 100.0;
    } else {
      tot = parseAmount(json['total'] ?? json['totalAmount']);
    }

    if (tot == 0.0 && sTotal > 0.0) {
      tot = sTotal + dFee + tTax - disc;
    }

    return CheckoutQuoteModel(
      subtotal: sTotal,
      deliveryFee: dFee,
      discount: disc,
      tax: tTax,
      totalAmount: tot > 0 ? tot : 0.0,
      couponCode: json['couponCode']?.toString(),
      isValid: json['isValid'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'couponCode': couponCode,
      'isValid': isValid,
    };
  }
}
