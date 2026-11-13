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
    switch (key.toLowerCase()) {
      case 'mega':
      case 'mega_star':
        return 'Mega Star';
      case 'super':
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

  factory ClubTierModel.fromDynamic(dynamic val, {num defaultPct = 0}) {
    if (val is num) {
      return ClubTierModel(threshold: val.toInt(), pct: defaultPct);
    }
    if (val is Map) {
      final map = Map<String, dynamic>.from(val);
      return ClubTierModel(
        threshold: (map['threshold'] as num?)?.toInt() ?? 0,
        pct: map['pct'] as num? ?? defaultPct,
      );
    }
    return ClubTierModel(threshold: 0, pct: defaultPct);
  }

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
      bronze: json['bronze'] != null
          ? ClubTierModel.fromDynamic(json['bronze'], defaultPct: 1)
          : null,
      silver: json['silver'] != null
          ? ClubTierModel.fromDynamic(json['silver'], defaultPct: 2)
          : null,
      gold: json['gold'] != null
          ? ClubTierModel.fromDynamic(json['gold'], defaultPct: 3)
          : null,
    );
  }
}

class GeoPctModel {
  final num division;
  final num district;
  final num upazila;
  final num union;
  final num area;

  GeoPctModel({
    this.division = 1,
    this.district = 2,
    this.upazila = 3,
    this.union = 0,
    this.area = 0,
  });

  factory GeoPctModel.fromJson(Map<String, dynamic> json) {
    return GeoPctModel(
      division: json['division'] as num? ?? 1,
      district: json['district'] as num? ?? 2,
      upazila: json['upazila'] as num? ?? 3,
      union: json['union'] as num? ?? 0,
      area: json['area'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'division': division,
    'district': district,
    'upazila': upazila,
    'union': union,
    'area': area,
  };
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
  final GeoPctModel geoPct;
  final CustomerSplitModel customerSplit;
  final List<StarBandModel> customerStarBands;
  final Map<String, ClubPeriodTiersModel> customerClub;

  RewardsInfoModel({
    this.pointValueMinor = 100,
    this.cashbackPct = 10,
    this.referralPct = const [3, 2, 1],
    this.registrationBonusMinor = 100000,
    this.registrationReferralPct = const [70, 30, 10],
    GeoPctModel? geoPct,
    CustomerSplitModel? customerSplit,
    this.customerStarBands = const [],
    this.customerClub = const {},
  })  : geoPct = geoPct ?? GeoPctModel(),
        customerSplit = customerSplit ?? CustomerSplitModel();

  double pointsToMoney(int points) => (points * pointValueMinor) / 100.0;

  String formatPointsMoney(int points) {
    final val = pointsToMoney(points);
    return '৳${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}';
  }

  factory RewardsInfoModel.fromJson(Map<String, dynamic> json) {
    final bandsList = (json['customerStarBands'] as List<dynamic>?)
            ?.map((e) => StarBandModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final clubMap = <String, ClubPeriodTiersModel>{};
    if (json['customerClub'] is Map<String, dynamic>) {
      (json['customerClub'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map) {
          clubMap[k] = ClubPeriodTiersModel.fromJson(Map<String, dynamic>.from(v));
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

    final parsedGeo = json['geoPct'] is Map<String, dynamic>
        ? GeoPctModel.fromJson(Map<String, dynamic>.from(json['geoPct']))
        : (json['geoPct'] is Map
            ? GeoPctModel.fromJson(Map<String, dynamic>.from(json['geoPct'] as Map))
            : GeoPctModel());

    return RewardsInfoModel(
      pointValueMinor: (json['pointValueMinor'] as num?)?.toInt() ?? 100,
      cashbackPct: json['cashbackPct'] as num? ?? 10,
      referralPct: refPct,
      registrationBonusMinor:
          (json['registrationBonusMinor'] as num?)?.toInt() ?? 100000,
      registrationReferralPct: regRefPct,
      geoPct: parsedGeo,
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
