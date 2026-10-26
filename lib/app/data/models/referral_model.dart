class ReferralInfoModel {
  final String code;
  final String shareUrl;
  final String playStoreUrl;
  final RegistrationBonusConfig registrationBonus;
  final ReferralCounts counts;
  final ReferralEarnings earnings;

  ReferralInfoModel({
    required this.code,
    required this.shareUrl,
    required this.playStoreUrl,
    required this.registrationBonus,
    required this.counts,
    required this.earnings,
  });

  factory ReferralInfoModel.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? '';
    final shareUrl = json['shareUrl']?.toString() ??
        'https://alifworld.com.bd/register?ref=$code';
    final playStoreUrl = json['playStoreUrl']?.toString() ??
        'https://play.google.com/store/apps/details?id=com.dream.alifbd&referrer=ref%3D$code';

    return ReferralInfoModel(
      code: code,
      shareUrl: shareUrl,
      playStoreUrl: playStoreUrl,
      registrationBonus: json['registrationBonus'] is Map<String, dynamic>
          ? RegistrationBonusConfig.fromJson(
              json['registrationBonus'] as Map<String, dynamic>)
          : RegistrationBonusConfig.fallback(),
      counts: json['counts'] is Map<String, dynamic>
          ? ReferralCounts.fromJson(json['counts'] as Map<String, dynamic>)
          : ReferralCounts.empty(),
      earnings: json['earnings'] is Map<String, dynamic>
          ? ReferralEarnings.fromJson(json['earnings'] as Map<String, dynamic>)
          : ReferralEarnings.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'shareUrl': shareUrl,
        'playStoreUrl': playStoreUrl,
        'registrationBonus': registrationBonus.toJson(),
        'counts': counts.toJson(),
        'earnings': earnings.toJson(),
      };
}

class RegistrationBonusConfig {
  final int amountMinor;
  final String walletKind;
  final List<ReferralLevelModel> levels;

  RegistrationBonusConfig({
    required this.amountMinor,
    required this.walletKind,
    required this.levels,
  });

  double get amountMajor => amountMinor / 100.0;
  String get formattedAmount => '৳${amountMajor.toStringAsFixed(0)}';

  factory RegistrationBonusConfig.fromJson(Map<String, dynamic> json) {
    var rawLevels = json['levels'];
    List<ReferralLevelModel> parsedLevels = [];
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

    return RegistrationBonusConfig(
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 100000,
      walletKind: json['walletKind']?.toString() ?? 'customer_main',
      levels: parsedLevels,
    );
  }

  factory RegistrationBonusConfig.fallback() {
    return RegistrationBonusConfig(
      amountMinor: 100000,
      walletKind: 'customer_main',
      levels: [
        ReferralLevelModel(level: 1, ratePct: 70),
        ReferralLevelModel(level: 2, ratePct: 30),
        ReferralLevelModel(level: 3, ratePct: 10),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'amountMinor': amountMinor,
        'walletKind': walletKind,
        'levels': levels.map((e) => e.toJson()).toList(),
      };
}

class ReferralLevelModel {
  final int level;
  final num ratePct;

  ReferralLevelModel({
    required this.level,
    required this.ratePct,
  });

  factory ReferralLevelModel.fromJson(Map<String, dynamic> json) {
    return ReferralLevelModel(
      level: (json['level'] as num?)?.toInt() ?? 1,
      ratePct: (json['ratePct'] ?? json['percent'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'ratePct': ratePct,
      };
}

class ReferralCounts {
  final int total;
  final int level1;
  final int level2;
  final int level3;

  ReferralCounts({
    required this.total,
    required this.level1,
    required this.level2,
    required this.level3,
  });

  factory ReferralCounts.fromJson(Map<String, dynamic> json) {
    return ReferralCounts(
      total: (json['total'] as num?)?.toInt() ?? 0,
      level1: (json['level1'] as num?)?.toInt() ?? 0,
      level2: (json['level2'] as num?)?.toInt() ?? 0,
      level3: (json['level3'] as num?)?.toInt() ?? 0,
    );
  }

  factory ReferralCounts.empty() =>
      ReferralCounts(total: 0, level1: 0, level2: 0, level3: 0);

  Map<String, dynamic> toJson() => {
        'total': total,
        'level1': level1,
        'level2': level2,
        'level3': level3,
      };
}

class ReferralEarnings {
  final int totalMinor;
  final int registrationMinor;
  final int orderMinor;

  ReferralEarnings({
    required this.totalMinor,
    required this.registrationMinor,
    required this.orderMinor,
  });

  double get totalMajor => totalMinor / 100.0;
  double get registrationMajor => registrationMinor / 100.0;
  double get orderMajor => orderMinor / 100.0;

  String get formattedTotal => '৳${totalMajor.toStringAsFixed(0)}';
  String get formattedRegistration => '৳${registrationMajor.toStringAsFixed(0)}';
  String get formattedOrder => '৳${orderMajor.toStringAsFixed(0)}';

  factory ReferralEarnings.fromJson(Map<String, dynamic> json) {
    return ReferralEarnings(
      totalMinor: (json['totalMinor'] as num?)?.toInt() ?? 0,
      registrationMinor: (json['registrationMinor'] as num?)?.toInt() ?? 0,
      orderMinor: (json['orderMinor'] as num?)?.toInt() ?? 0,
    );
  }

  factory ReferralEarnings.empty() =>
      ReferralEarnings(totalMinor: 0, registrationMinor: 0, orderMinor: 0);

  Map<String, dynamic> toJson() => {
        'totalMinor': totalMinor,
        'registrationMinor': registrationMinor,
        'orderMinor': orderMinor,
      };
}

class ReferralHistoryItem {
  final String id;
  final String type; // 'registration' or 'order'
  final int level;
  final int amountMinor;
  final ReferredUserSummary? referredUser;
  final DateTime? createdAt;

  ReferralHistoryItem({
    required this.id,
    required this.type,
    required this.level,
    required this.amountMinor,
    this.referredUser,
    this.createdAt,
  });

  double get amountMajor => amountMinor / 100.0;
  String get formattedAmount => '৳${amountMajor.toStringAsFixed(0)}';
  bool get isRegistration => type.toLowerCase() == 'registration';

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return ReferralHistoryItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'registration',
      level: (json['level'] as num?)?.toInt() ?? 1,
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      referredUser: json['referredUser'] is Map<String, dynamic>
          ? ReferredUserSummary.fromJson(
              json['referredUser'] as Map<String, dynamic>)
          : null,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'level': level,
        'amountMinor': amountMinor,
        'referredUser': referredUser?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
      };
}

class ReferredUserSummary {
  final String name;
  final String? maskedPhone;

  ReferredUserSummary({
    required this.name,
    this.maskedPhone,
  });

  factory ReferredUserSummary.fromJson(Map<String, dynamic> json) {
    return ReferredUserSummary(
      name: json['name']?.toString() ?? 'Friend',
      maskedPhone: json['maskedPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'maskedPhone': maskedPhone,
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
