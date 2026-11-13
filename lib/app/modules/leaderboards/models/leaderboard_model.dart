import '../../../data/models/rewards_info_model.dart';

class LeaderboardEntryModel {
  final int rank;
  final String name;
  final int points;
  final String? avatarUrl;
  final String? maskedPhone;

  LeaderboardEntryModel({
    required this.rank,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.maskedPhone,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl']?.toString(),
      maskedPhone: json['maskedPhone']?.toString(),
    );
  }
}

class LeaderboardPoolBandModel {
  final String key;
  final int from;
  final int to;
  final num pct;
  final int poolMinor;
  final int memberCount;

  LeaderboardPoolBandModel({
    required this.key,
    required this.from,
    required this.to,
    required this.pct,
    required this.poolMinor,
    required this.memberCount,
  });

  double get poolAmount => poolMinor / 100.0;

  factory LeaderboardPoolBandModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardPoolBandModel(
      key: json['key']?.toString() ?? '',
      from: (json['from'] as num?)?.toInt() ?? 0,
      to: (json['to'] as num?)?.toInt() ?? 0,
      pct: json['pct'] as num? ?? 0,
      poolMinor: (json['poolMinor'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardPoolModel {
  final int poolMinor;
  final List<LeaderboardPoolBandModel> bands;

  LeaderboardPoolModel({
    required this.poolMinor,
    required this.bands,
  });

  double get poolAmount => poolMinor / 100.0;

  factory LeaderboardPoolModel.fromJson(Map<String, dynamic> json) {
    final bList = (json['bands'] as List<dynamic>?)
            ?.map((e) => LeaderboardPoolBandModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return LeaderboardPoolModel(
      poolMinor: (json['poolMinor'] as num?)?.toInt() ?? 0,
      bands: bList,
    );
  }
}

class LeaderboardResponseModel {
  final String kind;
  final String period;
  final List<LeaderboardEntryModel> entries;
  final List<StarBandModel> bands;
  final LeaderboardPoolModel? pool;

  LeaderboardResponseModel({
    required this.kind,
    required this.period,
    required this.entries,
    required this.bands,
    this.pool,
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final entriesList = (json['entries'] as List<dynamic>?)
            ?.map((e) =>
                LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final bandsList = (json['bands'] as List<dynamic>?)
            ?.map((e) =>
                StarBandModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    LeaderboardPoolModel? poolModel;
    if (json['pool'] is Map<String, dynamic>) {
      poolModel = LeaderboardPoolModel.fromJson(
          Map<String, dynamic>.from(json['pool']));
    }

    return LeaderboardResponseModel(
      kind: json['kind']?.toString() ?? 'customer',
      period: json['period']?.toString() ?? 'daily',
      entries: entriesList,
      bands: bandsList,
      pool: poolModel,
    );
  }
}

class MyProgressClubModel {
  final String? currentTier;
  final num? currentTierPct;
  final String? nextTier;
  final num? nextTierPct;
  final int points;
  final int pointsToNext;
  final num progressPct;

  MyProgressClubModel({
    this.currentTier,
    this.currentTierPct,
    this.nextTier,
    this.nextTierPct,
    required this.points,
    required this.pointsToNext,
    required this.progressPct,
  });

  factory MyProgressClubModel.fromJson(Map<String, dynamic> json) {
    return MyProgressClubModel(
      currentTier: json['currentTier']?.toString(),
      currentTierPct: json['currentTierPct'] as num?,
      nextTier: json['nextTier']?.toString(),
      nextTierPct: json['nextTierPct'] as num?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      pointsToNext: (json['pointsToNext'] as num?)?.toInt() ?? 0,
      progressPct: json['progressPct'] as num? ?? 0,
    );
  }
}

class MyProgressStarModel {
  final int? rank;
  final int? totalRanked;
  final String? bandKey;
  final String? nextBandKey;
  final StarBandModel? band;
  final StarBandModel? nextBand;
  final int ranksToNext;

  MyProgressStarModel({
    this.rank,
    this.totalRanked,
    this.bandKey,
    this.nextBandKey,
    this.band,
    this.nextBand,
    this.ranksToNext = 0,
  });

  String get displayBand {
    if (band != null) return band!.displayName;
    if (bandKey != null && bandKey!.isNotEmpty) {
      switch (bandKey!.toLowerCase()) {
        case 'mega':
          return 'Mega Star';
        case 'super':
          return 'Super Star';
        case 'star':
          return 'Star';
        default:
          return bandKey!;
      }
    }
    return '';
  }

  String get displayNextBand {
    if (nextBand != null) return nextBand!.displayName;
    if (nextBandKey != null && nextBandKey!.isNotEmpty) {
      switch (nextBandKey!.toLowerCase()) {
        case 'mega':
          return 'Mega Star';
        case 'super':
          return 'Super Star';
        case 'star':
          return 'Star';
        default:
          return nextBandKey!;
      }
    }
    return '';
  }

  factory MyProgressStarModel.fromJson(Map<String, dynamic> json) {
    String? bKey;
    StarBandModel? bModel;
    if (json['band'] is Map) {
      bModel = StarBandModel.fromJson(Map<String, dynamic>.from(json['band'] as Map));
      bKey = bModel.key;
    } else if (json['band'] != null) {
      bKey = json['band'].toString();
    }

    String? nbKey;
    StarBandModel? nbModel;
    if (json['nextBand'] is Map) {
      nbModel = StarBandModel.fromJson(Map<String, dynamic>.from(json['nextBand'] as Map));
      nbKey = nbModel.key;
    } else if (json['nextBand'] != null) {
      nbKey = json['nextBand'].toString();
    }

    return MyProgressStarModel(
      rank: (json['rank'] as num?)?.toInt(),
      totalRanked: (json['totalRanked'] as num?)?.toInt(),
      bandKey: bKey,
      nextBandKey: nbKey,
      band: bModel,
      nextBand: nbModel,
      ranksToNext: (json['ranksToNext'] as num?)?.toInt() ?? 0,
    );
  }
}

class MyProgressPeriodModel {
  final String period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int points;
  final MyProgressClubModel? club;
  final MyProgressStarModel? star;

  MyProgressPeriodModel({
    required this.period,
    this.periodStart,
    this.periodEnd,
    required this.points,
    this.club,
    this.star,
  });

  factory MyProgressPeriodModel.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;
    if (json['periodStart'] != null) {
      try {
        start = DateTime.parse(json['periodStart'].toString());
      } catch (_) {}
    }
    if (json['periodEnd'] != null) {
      try {
        end = DateTime.parse(json['periodEnd'].toString());
      } catch (_) {}
    }

    return MyProgressPeriodModel(
      period: json['period']?.toString() ?? '',
      periodStart: start,
      periodEnd: end,
      points: (json['points'] as num?)?.toInt() ?? 0,
      club: json['club'] is Map<String, dynamic>
          ? MyProgressClubModel.fromJson(Map<String, dynamic>.from(json['club']))
          : null,
      star: json['star'] is Map<String, dynamic>
          ? MyProgressStarModel.fromJson(Map<String, dynamic>.from(json['star']))
          : null,
    );
  }
}

class MyProgressResponseModel {
  final String kind;
  final int pendingPoints;
  final List<MyProgressPeriodModel> periods;

  MyProgressResponseModel({
    required this.kind,
    required this.pendingPoints,
    required this.periods,
  });

  MyProgressPeriodModel? getPeriod(String period) {
    try {
      return periods.firstWhere((p) => p.period.toLowerCase() == period.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  factory MyProgressResponseModel.fromJson(Map<String, dynamic> json) {
    final pList = (json['periods'] as List<dynamic>?)
            ?.map((e) =>
                MyProgressPeriodModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return MyProgressResponseModel(
      kind: json['kind']?.toString() ?? 'customer',
      pendingPoints: (json['pendingPoints'] as num?)?.toInt() ?? 0,
      periods: pList,
    );
  }
}
