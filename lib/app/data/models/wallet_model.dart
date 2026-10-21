import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class WalletItemModel {
  final String kind;
  final int balanceMinor;

  WalletItemModel({
    required this.kind,
    required this.balanceMinor,
  });

  double get balance => balanceMinor / 100.0;

  String formattedBalance({String symbol = '৳'}) {
    return '$symbol ${balance.toStringAsFixed(2)}';
  }

  String get title {
    switch (kind) {
      case 'customer_main':
        return 'Main Wallet';
      case 'customer_shopping':
        return 'Shopping Wallet';
      case 'customer_advanced_shopping':
        return 'Advance Shopping';
      case 'customer_cashback':
        return 'Cashback Balance';
      case 'customer_referral':
        return 'Referral Rewards';
      case 'customer_club_bonus':
        return 'Club Bonus';
      case 'customer_star_bonus':
        return 'Star Bonus';
      case 'customer_advanced_return':
        return 'Advance Return';
      case 'customer_good_luck':
        return 'Good Luck Bonus';
      case 'customer_charity':
        return 'Charity Wallet';
      default:
        return kind
            .replaceAll('customer_', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
    }
  }

  String get shortTitle {
    switch (kind) {
      case 'customer_main':
        return 'Main';
      case 'customer_shopping':
        return 'Shopping';
      case 'customer_advanced_shopping':
        return 'Advance';
      case 'customer_cashback':
        return 'Cashback';
      case 'customer_referral':
        return 'Referral';
      case 'customer_club_bonus':
        return 'Club';
      case 'customer_star_bonus':
        return 'Star';
      case 'customer_advanced_return':
        return 'Return';
      case 'customer_good_luck':
        return 'Good Luck';
      case 'customer_charity':
        return 'Charity';
      default:
        return kind.replaceAll('customer_', '');
    }
  }

  String get description {
    switch (kind) {
      case 'customer_main':
        return 'Primary balance for instant purchases and top-ups';
      case 'customer_shopping':
        return 'Dedicated funds for everyday shopping discounts';
      case 'customer_advanced_shopping':
        return 'Funds deposited for advance shopping benefits';
      case 'customer_cashback':
        return 'Accumulated cashback rewards earned from orders';
      case 'customer_referral':
        return 'Bonuses accrued from inviting friends to Alifworld';
      case 'customer_club_bonus':
        return 'Exclusive perks for loyal club members';
      case 'customer_star_bonus':
        return 'Special milestone star achievements';
      case 'customer_advanced_return':
        return 'Returns and refunds for advance purchases';
      case 'customer_good_luck':
        return 'Campaign prizes and promotional luck bonuses';
      case 'customer_charity':
        return 'Allocated contributions for community charity';
      default:
        return 'Wallet balance';
    }
  }

  IconData get icon {
    switch (kind) {
      case 'customer_main':
        return Iconsax.wallet_2;
      case 'customer_shopping':
        return Iconsax.shopping_bag;
      case 'customer_advanced_shopping':
        return Iconsax.trend_up;
      case 'customer_cashback':
        return Iconsax.money_recive;
      case 'customer_referral':
        return Iconsax.profile_2user;
      case 'customer_club_bonus':
        return Iconsax.crown;
      case 'customer_star_bonus':
        return Iconsax.star;
      case 'customer_advanced_return':
        return Iconsax.repeat;
      case 'customer_good_luck':
        return Iconsax.gift;
      case 'customer_charity':
        return Iconsax.heart;
      default:
        return Iconsax.wallet_3;
    }
  }

  List<Color> get gradientColors {
    switch (kind) {
      case 'customer_main':
        return const [Color(0xFF0F172A), Color(0xFF1E293B)];
      case 'customer_shopping':
        return const [Color(0xFF0284C7), Color(0xFF0369A1)];
      case 'customer_advanced_shopping':
        return const [Color(0xFF059669), Color(0xFF047857)];
      case 'customer_cashback':
        return const [Color(0xFFD97706), Color(0xFFB45309)];
      case 'customer_referral':
        return const [Color(0xFF7C3AED), Color(0xFF6D28D9)];
      case 'customer_club_bonus':
        return const [Color(0xFFE11D48), Color(0xFFBE123C)];
      case 'customer_star_bonus':
        return const [Color(0xFFCA8A04), Color(0xFFA16207)];
      case 'customer_advanced_return':
        return const [Color(0xFF475569), Color(0xFF334155)];
      case 'customer_good_luck':
        return const [Color(0xFFDB2777), Color(0xFFBE185D)];
      case 'customer_charity':
        return const [Color(0xFF0D9488), Color(0xFF0F766E)];
      default:
        return const [Color(0xFF1E293B), Color(0xFF334155)];
    }
  }

  factory WalletItemModel.fromJson(Map<String, dynamic> json) {
    return WalletItemModel(
      kind: json['kind']?.toString() ?? 'customer_main',
      balanceMinor: (json['balanceMinor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'balanceMinor': balanceMinor,
    };
  }
}

class WalletResponseModel {
  final List<WalletItemModel> items;
  final String currency;
  final String currencySymbol;
  final String currencySymbolPlacement;

  WalletResponseModel({
    required this.items,
    this.currency = 'BDT',
    this.currencySymbol = '৳',
    this.currencySymbolPlacement = 'left',
  });

  WalletItemModel? get mainWallet {
    try {
      return items.firstWhere((w) => w.kind == 'customer_main');
    } catch (_) {
      return items.isNotEmpty ? items.first : null;
    }
  }

  double get mainBalance => mainWallet?.balance ?? 0.0;

  int get totalBalanceMinor {
    return items.fold<int>(0, (sum, item) => sum + item.balanceMinor);
  }

  double get totalBalance => totalBalanceMinor / 100.0;

  String formatAmount(double amount) {
    if (currencySymbolPlacement == 'right') {
      return '${amount.toStringAsFixed(2)} $currencySymbol';
    }
    return '$currencySymbol ${amount.toStringAsFixed(2)}';
  }

  factory WalletResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => WalletItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WalletResponseModel(
      items: list,
      currency: json['currency']?.toString() ?? 'BDT',
      currencySymbol: json['currencySymbol']?.toString() ?? '৳',
      currencySymbolPlacement:
          json['currencySymbolPlacement']?.toString() ?? 'left',
    );
  }
}

class WalletTransactionModel {
  final String id;
  final String walletKind;
  final int amountMinor;
  final String? type;
  final int? balanceAfterMinor;
  final String reason;
  final String? referenceId;
  final String? status;
  final DateTime? createdAt;

  WalletTransactionModel({
    required this.id,
    required this.walletKind,
    required this.amountMinor,
    this.type,
    this.balanceAfterMinor,
    required this.reason,
    this.referenceId,
    this.status,
    this.createdAt,
  });

  bool get isCredit {
    if (type != null) {
      return type!.toLowerCase().contains('credit');
    }
    return amountMinor >= 0;
  }

  double get amount => (amountMinor.abs()) / 100.0;

  String formattedAmount({String symbol = '৳'}) {
    final sign = isCredit ? '+' : '-';
    return '$sign $symbol ${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (createdAt == null) return '';
    final dt = createdAt!;
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
    final monthName = months[dt.month - 1];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthName ${dt.year}, $hour:$minuteStr $ampm';
  }

  String get displayTitle {
    if (reason.isNotEmpty) return reason;
    if (referenceId != null && referenceId!.isNotEmpty) {
      return isCredit
          ? 'Credit: #$referenceId'
          : 'Payment: #$referenceId';
    }
    return isCredit ? 'Wallet Credit' : 'Wallet Debit';
  }

  String get walletTitle {
    return WalletItemModel(kind: walletKind, balanceMinor: 0).title;
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr = json['createdAt']?.toString() ??
        json['created_at']?.toString() ??
        json['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (_) {}
    }

    final amtMinor = (json['amountMinor'] as num?)?.toInt() ??
        (((json['amount'] as num?)?.toDouble() ?? 0.0) * 100).toInt();

    return WalletTransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      walletKind: json['walletKind']?.toString() ?? 'customer_main',
      amountMinor: amtMinor,
      type: json['type']?.toString(),
      balanceAfterMinor: (json['balanceAfterMinor'] as num?)?.toInt(),
      reason: json['reason']?.toString() ??
          json['title']?.toString() ??
          json['description']?.toString() ??
          '',
      referenceId: json['referenceId']?.toString() ??
          json['reference']?.toString() ??
          json['orderId']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      createdAt: parsedDate,
    );
  }
}

class WalletTransactionsResponseModel {
  final List<WalletTransactionModel> items;
  final String? nextCursor;
  final String currency;
  final String currencySymbol;
  final String currencySymbolPlacement;

  WalletTransactionsResponseModel({
    required this.items,
    this.nextCursor,
    this.currency = 'BDT',
    this.currencySymbol = '৳',
    this.currencySymbolPlacement = 'left',
  });

  factory WalletTransactionsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) =>
                WalletTransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WalletTransactionsResponseModel(
      items: list,
      nextCursor: json['nextCursor']?.toString(),
      currency: json['currency']?.toString() ?? 'BDT',
      currencySymbol: json['currencySymbol']?.toString() ?? '৳',
      currencySymbolPlacement:
          json['currencySymbolPlacement']?.toString() ?? 'left',
    );
  }
}

