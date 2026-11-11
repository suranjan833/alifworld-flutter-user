class StarBandModel {
  final String key;
  final int from;
  final int to;
  final num pct;

  StarBandModel({
    required this.key,
    required this.from,
    required this.to,
    required this.pct,
  });

  String get displayName {
    switch (key) {
      case 'mega_star':
        return 'Mega Star';
      case 'super_star':
        return 'Super Star';
      case 'star':
        return 'Star';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  factory StarBandModel.fromJson(Map<String, dynamic> json) {
    return StarBandModel(
      key: json['key']?.toString() ?? '',
      from: (json['from'] as num?)?.toInt() ?? 0,
      to: (json['to'] as num?)?.toInt() ?? 0,
      pct: json['pct'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'from': from,
      'to': to,
      'pct': pct,
    };
  }
}

class ClubTierModel {
  final int threshold;
  final num pct;

  ClubTierModel({
    required this.threshold,
    required this.pct,
  });

  factory ClubTierModel.fromJson(Map<String, dynamic> json) {
    return ClubTierModel(
      threshold: (json['threshold'] as num?)?.toInt() ?? 0,
      pct: json['pct'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'threshold': threshold,
    'pct': pct,
  };
}

class ClubPeriodTiersModel {
  final ClubTierModel? bronze;
  final ClubTierModel? silver;
  final ClubTierModel? gold;

  ClubPeriodTiersModel({this.bronze, this.silver, this.gold});

  factory ClubPeriodTiersModel.fromJson(Map<String, dynamic> json) {
    return ClubPeriodTiersModel(
      bronze: json['bronze'] is Map<String, dynamic>
          ? ClubTierModel.fromJson(Map<String, dynamic>.from(json['bronze']))
          : null,
      silver: json['silver'] is Map<String, dynamic>
          ? ClubTierModel.fromJson(Map<String, dynamic>.from(json['silver']))
          : null,
      gold: json['gold'] is Map<String, dynamic>
          ? ClubTierModel.fromJson(Map<String, dynamic>.from(json['gold']))
          : null,
    );
  }
}

class CustomerSplitModel {
  final num main;
  final num shopping;
  final num goodLuck;
  final num charity;
  final num serviceCharge;

  CustomerSplitModel({
    this.main = 50,
    this.shopping = 20,
    this.goodLuck = 15,
    this.charity = 5,
    this.serviceCharge = 10,
  });

  factory CustomerSplitModel.fromJson(Map<String, dynamic> json) {
    return CustomerSplitModel(
      main: json['main'] as num? ?? 50,
      shopping: json['shopping'] as num? ?? 20,
      goodLuck: (json['good_luck'] ?? json['goodLuck']) as num? ?? 15,
      charity: json['charity'] as num? ?? 5,
      serviceCharge: (json['service_charge'] ?? json['serviceCharge']) as num? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
    'main': main,
    'shopping': shopping,
    'good_luck': goodLuck,
    'charity': charity,
    'service_charge': serviceCharge,
  };
}

class RewardsInfoModel {
  final int pointValueMinor;
  final num cashbackPct;
  final List<num> referralPct;
  final int registrationBonusMinor;
  final List<num> registrationReferralPct;
  final CustomerSplitModel customerSplit;
  final List<StarBandModel> customerStarBands;
  final Map<String, ClubPeriodTiersModel> customerClub;

  RewardsInfoModel({
    this.pointValueMinor = 100,
    this.cashbackPct = 10,
    this.referralPct = const [3, 2, 1],
    this.registrationBonusMinor = 100000,
    this.registrationReferralPct = const [70, 30, 10],
    CustomerSplitModel? customerSplit,
    this.customerStarBands = const [],
    this.customerClub = const {},
  }) : customerSplit = customerSplit ?? CustomerSplitModel();

  factory RewardsInfoModel.fromJson(Map<String, dynamic> json) {
    final bandsList = (json['customerStarBands'] as List<dynamic>?)
            ?.map((e) => StarBandModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final clubMap = <String, ClubPeriodTiersModel>{};
    if (json['customerClub'] is Map<String, dynamic>) {
      (json['customerClub'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          clubMap[k] = ClubPeriodTiersModel.fromJson(v);
        }
      });
    }

    final refPct = (json['referralPct'] as List<dynamic>?)
            ?.map((e) => e as num)
            .toList() ??
        const [3, 2, 1];

    final regRefPct = (json['registrationReferralPct'] as List<dynamic>?)
            ?.map((e) => e as num)
            .toList() ??
        const [70, 30, 10];

    return RewardsInfoModel(
      pointValueMinor: (json['pointValueMinor'] as num?)?.toInt() ?? 100,
      cashbackPct: json['cashbackPct'] as num? ?? 10,
      referralPct: refPct,
      registrationBonusMinor:
          (json['registrationBonusMinor'] as num?)?.toInt() ?? 100000,
      registrationReferralPct: regRefPct,
      customerSplit: json['customerSplit'] is Map<String, dynamic>
          ? CustomerSplitModel.fromJson(
              Map<String, dynamic>.from(json['customerSplit']),
            )
          : CustomerSplitModel(),
      customerStarBands: bandsList,
      customerClub: clubMap,
    );
  }
}
