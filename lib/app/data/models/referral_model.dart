class ReferralInfoModel {
  final String code;
  final String link;
  final int referredCount;
  final int earningsMinor; // Order referral earnings
  final int registrationEarningsMinor; // Registration referral earnings
  final int ownRegistrationBonusMinor;
  final RegistrationBonusConfig registrationBonus;
  final int registrationMaxLevels;
  final List<ReferralLevelModel> levels;
  final String currency;
  final String currencySymbol;
  final String currencySymbolPlacement;

  ReferralInfoModel({
    required this.code,
    required this.link,
    required this.referredCount,
    required this.earningsMinor,
    required this.registrationEarningsMinor,
    required this.ownRegistrationBonusMinor,
    required this.registrationBonus,
    required this.registrationMaxLevels,
    required this.levels,
    required this.currency,
    required this.currencySymbol,
    required this.currencySymbolPlacement,
  });

  /// Order referral earnings in BDT (major unit)
  double get orderEarningsMajor => earningsMinor / 100.0;

  /// Registration referral earnings in BDT (major unit)
  double get registrationEarningsMajor => registrationEarningsMinor / 100.0;

  /// Total combined referral earnings in BDT (major unit)
  double get totalEarningsMajor =>
      (earningsMinor + registrationEarningsMinor) / 100.0;

  String get formattedTotalEarnings =>
      '$currencySymbol${totalEarningsMajor.toStringAsFixed(0)}';

  String get formattedRegistrationEarnings =>
      '$currencySymbol${registrationEarningsMajor.toStringAsFixed(0)}';

  String get formattedOrderEarnings =>
      '$currencySymbol${orderEarningsMajor.toStringAsFixed(0)}';

  /// Check if API returned user counts on levels
  bool get hasUserCounts => levels.any((l) => l.userCount != null);

  /// Total referred users count across all levels (or direct Level 1 count if userCount absent)
  int get totalUserCount {
    if (hasUserCounts) {
      return levels.fold<int>(0, (sum, l) => sum + (l.userCount ?? 0));
    }
    return referredCount;
  }

  factory ReferralInfoModel.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? '';
    final link = json['link']?.toString() ??
        json['shareUrl']?.toString() ??
        'https://alifworld.com.bd/register?ref=$code';

    // Parse levels
    List<ReferralLevelModel> parsedLevels = [];
    final rawLevels = json['levels'];
    if (rawLevels is List) {
      parsedLevels = rawLevels
          .whereType<Map<String, dynamic>>()
          .map((e) => ReferralLevelModel.fromJson(e))
          .toList();
    }
    if (parsedLevels.isEmpty) {
      parsedLevels = [
        ReferralLevelModel(level: 1, ratePct: 70),
        ReferralLevelModel(level: 2, ratePct: 30),
        ReferralLevelModel(level: 3, ratePct: 10),
      ];
    }

    final currencySym = json['currencySymbol']?.toString() ?? '৳';

    return ReferralInfoModel(
      code: code,
      link: link,
      referredCount: (json['referredCount'] as num?)?.toInt() ?? 0,
      earningsMinor: (json['earningsMinor'] as num?)?.toInt() ?? 0,
      registrationEarningsMinor:
          (json['registrationEarningsMinor'] as num?)?.toInt() ?? 0,
      ownRegistrationBonusMinor:
          (json['ownRegistrationBonusMinor'] as num?)?.toInt() ?? 0,
      registrationBonus: json['registrationBonus'] is Map<String, dynamic>
          ? RegistrationBonusConfig.fromJson(
              json['registrationBonus'] as Map<String, dynamic>,
              currencySym,
            )
          : RegistrationBonusConfig.fallback(currencySym),
      registrationMaxLevels:
          (json['registrationMaxLevels'] as num?)?.toInt() ?? 3,
      levels: parsedLevels,
      currency: json['currency']?.toString() ?? 'BDT',
      currencySymbol: currencySym,
      currencySymbolPlacement:
          json['currencySymbolPlacement']?.toString() ?? 'left',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'link': link,
        'referredCount': referredCount,
        'earningsMinor': earningsMinor,
        'registrationEarningsMinor': registrationEarningsMinor,
        'ownRegistrationBonusMinor': ownRegistrationBonusMinor,
        'registrationBonus': registrationBonus.toJson(),
        'registrationMaxLevels': registrationMaxLevels,
        'levels': levels.map((e) => e.toJson()).toList(),
        'currency': currency,
        'currencySymbol': currencySymbol,
        'currencySymbolPlacement': currencySymbolPlacement,
      };
}

class RegistrationBonusConfig {
  final int amountMinor;
  final String walletKind;
  final String currencySymbol;

  RegistrationBonusConfig({
    required this.amountMinor,
    required this.walletKind,
    this.currencySymbol = '৳',
  });

  double get amountMajor => amountMinor / 100.0;
  String get formattedAmount =>
      '$currencySymbol${amountMajor.toStringAsFixed(0)}';

  factory RegistrationBonusConfig.fromJson(
    Map<String, dynamic> json, [
    String currencySymbol = '৳',
  ]) {
    return RegistrationBonusConfig(
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 100000,
      walletKind: json['walletKind']?.toString() ?? 'customer_main',
      currencySymbol: currencySymbol,
    );
  }

  factory RegistrationBonusConfig.fallback([String currencySymbol = '৳']) {
    return RegistrationBonusConfig(
      amountMinor: 100000,
      walletKind: 'customer_main',
      currencySymbol: currencySymbol,
    );
  }

  Map<String, dynamic> toJson() => {
        'amountMinor': amountMinor,
        'walletKind': walletKind,
      };
}

class ReferralLevelModel {
  final int level;
  final num ratePct;
  final String walletKind;
  final int earningsMinor;
  final int? userCount;

  ReferralLevelModel({
    required this.level,
    required this.ratePct,
    this.walletKind = 'customer_referral',
    this.earningsMinor = 0,
    this.userCount,
  });

  double get earningsMajor => earningsMinor / 100.0;

  factory ReferralLevelModel.fromJson(Map<String, dynamic> json) {
    return ReferralLevelModel(
      level: (json['level'] as num?)?.toInt() ?? 1,
      ratePct: (json['ratePct'] as num?) ?? (json['percent'] as num?) ?? 0,
      walletKind: json['walletKind']?.toString() ?? 'customer_referral',
      earningsMinor: (json['earningsMinor'] as num?)?.toInt() ?? 0,
      userCount: (json['userCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'ratePct': ratePct,
        'walletKind': walletKind,
        'earningsMinor': earningsMinor,
        if (userCount != null) 'userCount': userCount,
      };
}

class ReferralHistoryItem {
  final String id;
  final String name;
  final DateTime? joinedAt;
  final int level;

  ReferralHistoryItem({
    required this.id,
    required this.name,
    this.joinedAt,
    this.level = 1,
  });

  String get formattedJoinedDate {
    if (joinedAt == null) return '';
    final local = joinedAt!.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    return '$day $month $year';
  }

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    final rawDate = json['joinedAt'] ?? json['createdAt'];
    if (rawDate != null) {
      date = DateTime.tryParse(rawDate.toString());
    }

    String parsedName = 'Friend';
    if (json['name'] != null && json['name'].toString().trim().isNotEmpty) {
      parsedName = json['name'].toString().trim();
    } else if (json['referredUser'] is Map &&
        json['referredUser']['name'] != null) {
      parsedName = json['referredUser']['name'].toString().trim();
    }

    return ReferralHistoryItem(
      id: json['id']?.toString() ?? '',
      name: parsedName,
      joinedAt: date,
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'joinedAt': joinedAt?.toIso8601String(),
        'level': level,
      };
}

class ReferralHistoryResponse {
  final List<ReferralHistoryItem> items;
  final String? nextCursor;

  ReferralHistoryResponse({
    required this.items,
    this.nextCursor,
  });

  factory ReferralHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<ReferralHistoryItem> list = [];
    final rawItems = json['items'];
    if (rawItems is List) {
      list = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => ReferralHistoryItem.fromJson(e))
          .toList();
    }
    return ReferralHistoryResponse(
      items: list,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
