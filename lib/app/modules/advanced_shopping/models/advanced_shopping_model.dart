class AdvancedShoppingPackageSummaryModel {
  final String id;
  final String title;
  final String? imageUrl;

  AdvancedShoppingPackageSummaryModel({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory AdvancedShoppingPackageSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdvancedShoppingPackageSummaryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
      };
}

class AdvancedShoppingPackageModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int priceMinor;
  final num annualRatePct;
  final String interestInterval; // 'daily', 'weekly', 'monthly', 'annually'
  final int holdDays;
  final int totalInterestMinor;
  final int projectedInterestMinor;
  final String releaseWalletKind; // e.g. 'customer_main'
  final String interestWalletKind; // e.g. 'customer_advanced_return'
  final int cancelFlatMinor;
  final num cancelPct;
  final int? maxPerUser;
  final int? maxTotal;
  final int totalPurchases;
  final bool isActive;
  final int sortOrder;
  final int myActiveCount;

  AdvancedShoppingPackageModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.priceMinor,
    required this.annualRatePct,
    this.interestInterval = 'daily',
    required this.holdDays,
    required this.totalInterestMinor,
    required this.projectedInterestMinor,
    this.releaseWalletKind = 'customer_main',
    this.interestWalletKind = 'customer_advanced_return',
    this.cancelFlatMinor = 0,
    this.cancelPct = 0,
    this.maxPerUser,
    this.maxTotal,
    this.totalPurchases = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.myActiveCount = 0,
  });

  double get price => priceMinor / 100.0;
  double get totalInterest => totalInterestMinor / 100.0;
  double get projectedInterest => projectedInterestMinor / 100.0;
  double get cancelFlat => cancelFlatMinor / 100.0;

  bool get isLimitReached => maxPerUser != null && myActiveCount >= maxPerUser!;
  bool get isSoldOut => maxTotal != null && totalPurchases >= maxTotal!;

  String get intervalTitle {
    switch (interestInterval.toLowerCase()) {
      case 'daily':
        return 'Daily Credit';
      case 'weekly':
        return 'Weekly Credit';
      case 'monthly':
        return 'Monthly Credit';
      case 'annually':
        return 'At Maturity';
      default:
        return '${interestInterval[0].toUpperCase()}${interestInterval.substring(1)} Credit';
    }
  }

  String get releaseWalletTitle => formatWalletKind(releaseWalletKind);
  String get interestWalletTitle => formatWalletKind(interestWalletKind);

  static String formatWalletKind(String kind) {
    switch (kind) {
      case 'customer_main':
        return 'Main Wallet';
      case 'customer_shopping':
        return 'Shopping Wallet';
      case 'customer_advanced_return':
        return 'Advance Return';
      case 'customer_cashback':
        return 'Cashback';
      case 'customer_referral':
        return 'Referral';
      case 'customer_good_luck':
        return 'Good Luck';
      default:
        return kind
            .replaceAll('customer_', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  factory AdvancedShoppingPackageModel.fromJson(Map<String, dynamic> json) {
    return AdvancedShoppingPackageModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      annualRatePct: (json['annualRatePct'] as num?) ?? 0,
      interestInterval: json['interestInterval']?.toString() ?? 'daily',
      holdDays: (json['holdDays'] as num?)?.toInt() ?? 0,
      totalInterestMinor: (json['totalInterestMinor'] as num?)?.toInt() ?? 0,
      projectedInterestMinor:
          (json['projectedInterestMinor'] as num?)?.toInt() ?? 0,
      releaseWalletKind:
          json['releaseWalletKind']?.toString() ?? 'customer_main',
      interestWalletKind:
          json['interestWalletKind']?.toString() ?? 'customer_advanced_return',
      cancelFlatMinor: (json['cancelFlatMinor'] as num?)?.toInt() ?? 0,
      cancelPct: (json['cancelPct'] as num?) ?? 0,
      maxPerUser: (json['maxPerUser'] as num?)?.toInt(),
      maxTotal: (json['maxTotal'] as num?)?.toInt(),
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == true || json['isActive'] == 1,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      myActiveCount: (json['myActiveCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdvancedShoppingCreditItemModel {
  final String id;
  final DateTime? dueAt;
  final int daysCovered;
  final int amountMinor;
  final String status; // 'pending', 'credited', 'cancelled'
  final DateTime? creditedAt;

  AdvancedShoppingCreditItemModel({
    required this.id,
    this.dueAt,
    this.daysCovered = 1,
    required this.amountMinor,
    this.status = 'pending',
    this.creditedAt,
  });

  double get amount => amountMinor / 100.0;
  bool get isCredited => status.toLowerCase() == 'credited';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory AdvancedShoppingCreditItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return AdvancedShoppingCreditItemModel(
      id: json['id']?.toString() ?? '',
      dueAt: parseDate(json['dueAt']),
      daysCovered: (json['daysCovered'] as num?)?.toInt() ?? 1,
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      creditedAt: parseDate(json['creditedAt']),
    );
  }
}

class AdvancedShoppingHoldingModel {
  final String id;
  final AdvancedShoppingPackageSummaryModel? package;
  final int priceMinor;
  final num annualRatePct;
  final String interestInterval;
  final int holdDays;
  final int totalInterestMinor;
  final int totalCreditedMinor;
  final int projectedProfitMinor;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysReceived;
  final int daysRemaining;
  final DateTime? nextCreditAt;
  final String releaseWalletKind;
  final String interestWalletKind;
  final int cancelFlatMinor;
  final num cancelPct;
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime? releasedAt;
  final DateTime? cancelledAt;
  final int? cancelChargeMinor;
  final int? cancelNetMinor;
  final DateTime? createdAt;
  final List<AdvancedShoppingCreditItemModel> credits;

  AdvancedShoppingHoldingModel({
    required this.id,
    this.package,
    required this.priceMinor,
    required this.annualRatePct,
    this.interestInterval = 'daily',
    required this.holdDays,
    required this.totalInterestMinor,
    required this.totalCreditedMinor,
    required this.projectedProfitMinor,
    this.startDate,
    this.endDate,
    this.daysReceived = 0,
    this.daysRemaining = 0,
    this.nextCreditAt,
    this.releaseWalletKind = 'customer_main',
    this.interestWalletKind = 'customer_advanced_return',
    this.cancelFlatMinor = 0,
    this.cancelPct = 0,
    this.status = 'active',
    this.releasedAt,
    this.cancelledAt,
    this.cancelChargeMinor,
    this.cancelNetMinor,
    this.createdAt,
    this.credits = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  double get price => priceMinor / 100.0;
  double get totalInterest => totalInterestMinor / 100.0;
  double get totalCredited => totalCreditedMinor / 100.0;
  double get projectedProfit => projectedProfitMinor / 100.0;

  double get progressRatio =>
      holdDays > 0 ? (daysReceived / holdDays).clamp(0.0, 1.0) : 0.0;

  String get releaseWalletTitle =>
      AdvancedShoppingPackageModel.formatWalletKind(releaseWalletKind);
  String get interestWalletTitle =>
      AdvancedShoppingPackageModel.formatWalletKind(interestWalletKind);

  /// Client-side charge calculation preview per §5:
  /// pctCharge = floor(priceMinor * cancelPct / 100)
  /// charge = min(priceMinor, cancelFlatMinor + pctCharge)
  /// net = priceMinor - charge
  int calculateCancelChargeMinor() {
    final pctCharge = (priceMinor * cancelPct / 100.0).floor();
    final charge = cancelFlatMinor + pctCharge;
    return charge > priceMinor ? priceMinor : charge;
  }

  int calculateCancelNetMinor() {
    return priceMinor - calculateCancelChargeMinor();
  }

  double get cancelChargePreview => calculateCancelChargeMinor() / 100.0;
  double get cancelNetPreview => calculateCancelNetMinor() / 100.0;

  factory AdvancedShoppingHoldingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    AdvancedShoppingPackageSummaryModel? pkg;
    if (json['package'] is Map<String, dynamic>) {
      pkg = AdvancedShoppingPackageSummaryModel.fromJson(
        Map<String, dynamic>.from(json['package']),
      );
    } else if (json['package'] is Map) {
      pkg = AdvancedShoppingPackageSummaryModel.fromJson(
        Map<String, dynamic>.from(json['package'] as Map),
      );
    }

    final creditList = (json['credits'] as List<dynamic>?)
            ?.map((e) => AdvancedShoppingCreditItemModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList() ??
        const [];

    return AdvancedShoppingHoldingModel(
      id: json['id']?.toString() ?? '',
      package: pkg,
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      annualRatePct: (json['annualRatePct'] as num?) ?? 0,
      interestInterval: json['interestInterval']?.toString() ?? 'daily',
      holdDays: (json['holdDays'] as num?)?.toInt() ?? 0,
      totalInterestMinor: (json['totalInterestMinor'] as num?)?.toInt() ?? 0,
      totalCreditedMinor: (json['totalCreditedMinor'] as num?)?.toInt() ?? 0,
      projectedProfitMinor:
          (json['projectedProfitMinor'] as num?)?.toInt() ?? 0,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      daysReceived: (json['daysReceived'] as num?)?.toInt() ?? 0,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      nextCreditAt: parseDate(json['nextCreditAt']),
      releaseWalletKind:
          json['releaseWalletKind']?.toString() ?? 'customer_main',
      interestWalletKind:
          json['interestWalletKind']?.toString() ?? 'customer_advanced_return',
      cancelFlatMinor: (json['cancelFlatMinor'] as num?)?.toInt() ?? 0,
      cancelPct: (json['cancelPct'] as num?) ?? 0,
      status: json['status']?.toString() ?? 'active',
      releasedAt: parseDate(json['releasedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      cancelChargeMinor: (json['cancelChargeMinor'] as num?)?.toInt(),
      cancelNetMinor: (json['cancelNetMinor'] as num?)?.toInt(),
      createdAt: parseDate(json['createdAt']),
      credits: creditList,
    );
  }
}

class AdvancedShoppingHoldingsResponseModel {
  final int balanceMinor;
  final List<AdvancedShoppingHoldingModel> items;

  AdvancedShoppingHoldingsResponseModel({
    required this.balanceMinor,
    required this.items,
  });

  double get balance => balanceMinor / 100.0;

  factory AdvancedShoppingHoldingsResponseModel.fromJson(
      Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => AdvancedShoppingHoldingModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return AdvancedShoppingHoldingsResponseModel(
      balanceMinor: (json['balanceMinor'] as num?)?.toInt() ?? 0,
      items: list,
    );
  }
}
