class LotteryItemModel {
  final String id;
  final String title;
  final String? description;
  final int ticketPriceMinor;
  final int poolAmountMinor;
  final int winnerCount;
  final int minParticipants;
  final DateTime? startAt;
  final DateTime? resultAt;
  final String? prizeWalletKind;
  final String? prizeTitle;
  final String? prizeImageUrl;
  final String? prizeDescription;
  final String status; // 'active', 'drawn', etc.
  final String audience; // 'customer' or 'seller'
  final DateTime? drawnAt;
  final int ticketCount;
  final int winnersDeclared;
  final List<LotteryWinnerModel> winners;

  LotteryItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.ticketPriceMinor,
    required this.poolAmountMinor,
    required this.winnerCount,
    this.minParticipants = 0,
    this.startAt,
    this.resultAt,
    this.prizeWalletKind,
    this.prizeTitle,
    this.prizeImageUrl,
    this.prizeDescription,
    required this.status,
    this.audience = 'customer',
    this.drawnAt,
    this.ticketCount = 0,
    this.winnersDeclared = 0,
    this.winners = const [],
  });

  bool get isCustomer => audience.toLowerCase() == 'customer';
  bool get isSeller => audience.toLowerCase() == 'seller';

  double get ticketPrice => ticketPriceMinor / 100.0;
  double get poolAmount => poolAmountMinor / 100.0;

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
      poolAmountMinor: (json['poolAmountMinor'] as num?)?.toInt() ?? 0,
      winnerCount: (json['winnerCount'] as num?)?.toInt() ?? 1,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? 0,
      startAt: parseDate(json['startAt']),
      resultAt: parseDate(json['resultAt']),
      prizeWalletKind: json['prizeWalletKind']?.toString(),
      prizeTitle: json['prizeTitle']?.toString(),
      prizeImageUrl: json['prizeImageUrl']?.toString(),
      prizeDescription: json['prizeDescription']?.toString(),
      status: json['status']?.toString() ?? 'active',
      audience: json['audience']?.toString() ?? 'customer',
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

  LotteryTicketModel({
    required this.ticketNumber,
    this.purchasedAt,
    this.isWinner = false,
    this.winPosition,
    this.winPrizeMinor,
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
  final DateTime? settledAt;
  final WinnerUserModel? winner;

  LotteryWinnerModel({
    required this.position,
    required this.ticketNumber,
    required this.prizeMinor,
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
  final int poolAmountMinor;
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
    required this.poolAmountMinor,
    required this.winnerCount,
    this.prizeTitle,
    this.prizeImageUrl,
    this.prizeDescription,
    required this.winners,
  });

  double get poolAmount => poolAmountMinor / 100.0;

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
      poolAmountMinor: (json['poolAmountMinor'] as num?)?.toInt() ?? 0,
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
  final LotteryItemModel? lottery;

  MyLotteryTicketItemModel({
    required this.id,
    required this.ticketNumber,
    this.purchasedAt,
    this.isWinner = false,
    this.winPosition,
    this.winPrizeMinor,
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
