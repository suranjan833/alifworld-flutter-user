class LotteryGiftModel {
  final int rank;
  final String kind; // 'points' or 'custom'
  final int? pointsMinor;
  final String? walletKind;
  final String? title;
  final String? description;
  final String? imageUrl;

  LotteryGiftModel({
    required this.rank,
    required this.kind,
    this.pointsMinor,
    this.walletKind,
    this.title,
    this.description,
    this.imageUrl,
  });

  bool get isCustom => kind.toLowerCase() == 'custom';
  bool get isPoints => kind.toLowerCase() == 'points';
  double? get pointsAmount => pointsMinor != null ? pointsMinor! / 100.0 : null;

  String get displayWalletTitle {
    if (walletKind == null) return '';
    return walletKind!
        .replaceAll('customer_', '')
        .replaceAll('seller_', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  factory LotteryGiftModel.fromJson(Map<String, dynamic> json) {
    return LotteryGiftModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      kind: json['kind']?.toString() ?? 'points',
      pointsMinor: (json['pointsMinor'] as num?)?.toInt(),
      walletKind: json['walletKind']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'kind': kind,
        'pointsMinor': pointsMinor,
        'walletKind': walletKind,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
      };
}

class LotteryItemModel {
  final String id;
  final String title;
  final String? description;
  final int ticketPriceMinor;
  final int winnerCount;
  final int minParticipants;
  final DateTime? startAt;
  final DateTime? resultAt;
  final String? prizeTitle;
  final String? prizeImageUrl;
  final String? prizeDescription;
  final String status; // 'active', 'drawn', etc.
  final String audience; // 'customer' or 'seller'
  final List<LotteryGiftModel> gifts;
  final DateTime? drawnAt;
  final int ticketCount;
  final int winnersDeclared;
  final List<LotteryWinnerModel> winners;

  LotteryItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.ticketPriceMinor,
    required this.winnerCount,
    this.minParticipants = 0,
    this.startAt,
    this.resultAt,
    this.prizeTitle,
    this.prizeImageUrl,
    this.prizeDescription,
    required this.status,
    this.audience = 'customer',
    this.gifts = const [],
    this.drawnAt,
    this.ticketCount = 0,
    this.winnersDeclared = 0,
    this.winners = const [],
  });

  bool get isCustomer => audience.toLowerCase() == 'customer';
  bool get isSeller => audience.toLowerCase() == 'seller';

  double get ticketPrice => ticketPriceMinor / 100.0;

  LotteryGiftModel? get rank1Gift {
    if (gifts.isEmpty) return null;
    for (final g in gifts) {
      if (g.rank == 1) return g;
    }
    return gifts.first;
  }

  String get topPrizeTitle {
    final g = rank1Gift;
    if (g == null) return prizeTitle ?? 'Top Prize';
    if (g.isCustom) return g.title ?? prizeTitle ?? 'Top Prize';
    if (g.pointsAmount != null) return '৳${g.pointsAmount!.toStringAsFixed(2)} Points';
    return prizeTitle ?? 'Top Prize';
  }

  String get topPrizeSubtitle {
    final g = rank1Gift;
    if (g == null) return winnerCountText;
    if (g.isCustom) {
      return 'Top Prize (Rank 1) • $winnerCountText';
    }
    final wallet = g.displayWalletTitle;
    return wallet.isNotEmpty
        ? 'Rank 1 ($wallet) • $winnerCountText'
        : 'Top Prize (Rank 1) • $winnerCountText';
  }

  String get winnerCountText =>
      winnerCount == 1 ? '1 winner' : '$winnerCount winners';

  String get statusLine {
    if (status.toLowerCase() == 'drawn') {
      return drawnAt != null
          ? 'Drawn ${_formatDate(drawnAt!)}'
          : 'Drawn';
    }
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) {
      return 'Sales start ${_formatDate(startAt!)}';
    }
    if (status.toLowerCase() == 'ended' || (resultAt != null && !now.isBefore(resultAt!))) {
      return 'Ended';
    }
    if (resultAt != null) {
      return 'Result ${_formatDate(resultAt!)}';
    }
    return status.toUpperCase();
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  factory LotteryItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return LotteryItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      ticketPriceMinor: (json['ticketPriceMinor'] as num?)?.toInt() ?? 0,
      winnerCount: (json['winnerCount'] as num?)?.toInt() ?? 1,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? 0,
      startAt: parseDate(json['startAt']),
      resultAt: parseDate(json['resultAt']),
      prizeTitle: json['prizeTitle']?.toString(),
      prizeImageUrl: json['prizeImageUrl']?.toString(),
      prizeDescription: json['prizeDescription']?.toString(),
      status: json['status']?.toString() ?? 'active',
      audience: json['audience']?.toString() ?? 'customer',
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((e) =>
                  LotteryGiftModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      drawnAt: parseDate(json['drawnAt']),
      ticketCount: (json['ticketCount'] as num?)?.toInt() ?? 0,
      winnersDeclared: (json['winnersDeclared'] as num?)?.toInt() ?? 0,
      winners: (json['winners'] as List<dynamic>?)
              ?.map((e) =>
                  LotteryWinnerModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

class WinnerUserModel {
  final String name;
  final String? maskedPhone;
  final String? avatarUrl;

  WinnerUserModel({
    required this.name,
    this.maskedPhone,
    this.avatarUrl,
  });

  factory WinnerUserModel.fromJson(Map<String, dynamic> json) {
    return WinnerUserModel(
      name: json['name']?.toString() ?? '',
      maskedPhone: json['maskedPhone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'maskedPhone': maskedPhone,
        'avatarUrl': avatarUrl,
      };
}

class LotteryTicketModel {
  final String ticketNumber;
  final DateTime? purchasedAt;
  final bool isWinner;
  final int? winPosition;
  final int? winPrizeMinor;
  final LotteryGiftModel? winGift;

  LotteryTicketModel({
    required this.ticketNumber,
    this.purchasedAt,
    this.isWinner = false,
    this.winPosition,
    this.winPrizeMinor,
    this.winGift,
  });

  double? get winPrize =>
      winPrizeMinor != null ? winPrizeMinor! / 100.0 : null;

  factory LotteryTicketModel.fromJson(Map<String, dynamic> json) {
    DateTime? pAt;
    if (json['purchasedAt'] != null) {
      try {
        pAt = DateTime.parse(json['purchasedAt'].toString());
      } catch (_) {}
    }
    return LotteryTicketModel(
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      purchasedAt: pAt,
      isWinner: json['isWinner'] == true,
      winPosition: (json['winPosition'] as num?)?.toInt(),
      winPrizeMinor: (json['winPrizeMinor'] as num?)?.toInt(),
      winGift: json['winGift'] is Map<String, dynamic>
          ? LotteryGiftModel.fromJson(
              Map<String, dynamic>.from(json['winGift']))
          : null,
    );
  }
}

class LotteryDetailResponseModel {
  final LotteryItemModel lottery;
  final int goodLuckBalanceMinor;
  final List<LotteryTicketModel>? myTickets;

  LotteryDetailResponseModel({
    required this.lottery,
    required this.goodLuckBalanceMinor,
    this.myTickets,
  });

  double get goodLuckBalance => goodLuckBalanceMinor / 100.0;

  factory LotteryDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final lot = json['lottery'] is Map<String, dynamic>
        ? LotteryItemModel.fromJson(Map<String, dynamic>.from(json['lottery']))
        : LotteryItemModel.fromJson(json);

    List<LotteryTicketModel>? tickets;
    if (json['myTickets'] is List) {
      tickets = (json['myTickets'] as List<dynamic>)
          .map((e) =>
              LotteryTicketModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return LotteryDetailResponseModel(
      lottery: lot,
      goodLuckBalanceMinor:
          (json['goodLuckBalanceMinor'] as num?)?.toInt() ?? 0,
      myTickets: tickets,
    );
  }
}

class LotteryWinnerModel {
  final int position;
  final String ticketNumber;
  final int prizeMinor;
  final LotteryGiftModel? gift;
  final DateTime? settledAt;
  final WinnerUserModel? winner;

  LotteryWinnerModel({
    required this.position,
    required this.ticketNumber,
    required this.prizeMinor,
    this.gift,
    this.settledAt,
    this.winner,
  });

  double get prize => prizeMinor / 100.0;

  factory LotteryWinnerModel.fromJson(Map<String, dynamic> json) {
    DateTime? sAt;
    if (json['settledAt'] != null) {
      try {
        sAt = DateTime.parse(json['settledAt'].toString());
      } catch (_) {}
    }
    return LotteryWinnerModel(
      position: (json['position'] as num?)?.toInt() ?? 1,
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      prizeMinor: (json['prizeMinor'] as num?)?.toInt() ?? 0,
      gift: json['gift'] is Map<String, dynamic>
          ? LotteryGiftModel.fromJson(Map<String, dynamic>.from(json['gift']))
          : null,
      settledAt: sAt,
      winner: json['winner'] is Map<String, dynamic>
          ? WinnerUserModel.fromJson(Map<String, dynamic>.from(json['winner']))
          : null,
    );
  }
}

class LotteryResultsResponseModel {
  final String lotteryId;
  final String title;
  final String status;
  final String audience;
  final DateTime? resultAt;
  final DateTime? drawnAt;
  final int winnerCount;
  final String? prizeTitle;
  final String? prizeImageUrl;
  final String? prizeDescription;
  final List<LotteryWinnerModel> winners;

  LotteryResultsResponseModel({
    required this.lotteryId,
    required this.title,
    required this.status,
    this.audience = 'customer',
    this.resultAt,
    this.drawnAt,
    required this.winnerCount,
    this.prizeTitle,
    this.prizeImageUrl,
    this.prizeDescription,
    required this.winners,
  });

  factory LotteryResultsResponseModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final wList = (json['winners'] as List<dynamic>?)
            ?.map((e) =>
                LotteryWinnerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return LotteryResultsResponseModel(
      lotteryId: json['lotteryId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'drawn',
      audience: json['audience']?.toString() ?? 'customer',
      resultAt: parseDate(json['resultAt']),
      drawnAt: parseDate(json['drawnAt']),
      winnerCount: (json['winnerCount'] as num?)?.toInt() ?? 1,
      prizeTitle: json['prizeTitle']?.toString(),
      prizeImageUrl: json['prizeImageUrl']?.toString(),
      prizeDescription: json['prizeDescription']?.toString(),
      winners: wList,
    );
  }
}

class MyLotteryTicketItemModel {
  final String id;
  final String ticketNumber;
  final DateTime? purchasedAt;
  final bool isWinner;
  final int? winPosition;
  final int? winPrizeMinor;
  final LotteryGiftModel? winGift;
  final LotteryItemModel? lottery;

  MyLotteryTicketItemModel({
    required this.id,
    required this.ticketNumber,
    this.purchasedAt,
    this.isWinner = false,
    this.winPosition,
    this.winPrizeMinor,
    this.winGift,
    this.lottery,
  });

  double? get winPrize =>
      winPrizeMinor != null ? winPrizeMinor! / 100.0 : null;

  factory MyLotteryTicketItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? pAt;
    if (json['purchasedAt'] != null) {
      try {
        pAt = DateTime.parse(json['purchasedAt'].toString());
      } catch (_) {}
    }

    LotteryItemModel? lot;
    if (json['lottery'] is Map<String, dynamic>) {
      lot = LotteryItemModel.fromJson(Map<String, dynamic>.from(json['lottery']));
    }

    return MyLotteryTicketItemModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      purchasedAt: pAt,
      isWinner: json['isWinner'] == true,
      winPosition: (json['winPosition'] as num?)?.toInt(),
      winPrizeMinor: (json['winPrizeMinor'] as num?)?.toInt(),
      winGift: json['winGift'] is Map<String, dynamic>
          ? LotteryGiftModel.fromJson(Map<String, dynamic>.from(json['winGift']))
          : null,
      lottery: lot,
    );
  }
}

class MyLotteryTicketsResponseModel {
  final List<MyLotteryTicketItemModel> items;
  final String? nextCursor;

  MyLotteryTicketsResponseModel({
    required this.items,
    this.nextCursor,
  });

  factory MyLotteryTicketsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => MyLotteryTicketItemModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return MyLotteryTicketsResponseModel(
      items: list,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
