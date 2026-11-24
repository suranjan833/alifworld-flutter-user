import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

export 'wallet_transaction_model.dart';

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
        return const [Color(0xFF4F46E5), Color(0xFF3730A3)];
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
        return const [Color(0xFF0284C7), Color(0xFF075985)];
      case 'customer_good_luck':
        return const [Color(0xFFDB2777), Color(0xFFBE185D)];
      case 'customer_charity':
        return const [Color(0xFF0D9488), Color(0xFF0F766E)];
      default:
        return const [Color(0xFF4F46E5), Color(0xFF3730A3)];
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

class WalletCapsModel {
  final int customerMain;
  final int customerShopping;

  WalletCapsModel({
    this.customerMain = 100,
    this.customerShopping = 62,
  });

  factory WalletCapsModel.fromJson(Map<String, dynamic> json) {
    return WalletCapsModel(
      customerMain: (json['customer_main'] as num?)?.toInt() ?? 100,
      customerShopping: (json['customer_shopping'] as num?)?.toInt() ?? 62,
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_main': customerMain,
        'customer_shopping': customerShopping,
      };
}

class WalletResponseModel {
  final List<WalletItemModel> items;
  final String currency;
  final String currencySymbol;
  final String currencySymbolPlacement;
  final int walletMaxPercent;
  final WalletCapsModel walletCaps;

  WalletResponseModel({
    required this.items,
    this.walletMaxPercent = 100,
    WalletCapsModel? walletCaps,
    this.currency = 'BDT',
    this.currencySymbol = '৳',
    this.currencySymbolPlacement = 'left',
  }) : walletCaps = walletCaps ?? WalletCapsModel();

  WalletItemModel? get mainWallet {
    try {
      return items.firstWhere((w) => w.kind == 'customer_main');
    } catch (_) {
      return items.isNotEmpty ? items.first : null;
    }
  }

  double get mainBalance => mainWallet?.balance ?? 0.0;

  int get totalBalanceMinor {
    // Total balance = every wallet except Charity (Charity is view-only and excluded)
    return items
        .where((item) => item.kind != 'customer_charity')
        .fold<int>(0, (sum, item) => sum + item.balanceMinor);
  }

  double get totalBalance => totalBalanceMinor / 100.0;

  WalletItemModel? get charityWallet {
    try {
      return items.firstWhere((w) => w.kind == 'customer_charity');
    } catch (_) {
      return null;
    }
  }

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

    final caps = json['walletCaps'] is Map<String, dynamic>
        ? WalletCapsModel.fromJson(
            Map<String, dynamic>.from(json['walletCaps']))
        : (json['walletCaps'] is Map
            ? WalletCapsModel.fromJson(
                Map<String, dynamic>.from(json['walletCaps'] as Map))
            : WalletCapsModel());

    final maxPct = (json['walletMaxPercent'] as num?)?.toInt() ??
        ((caps.customerMain + caps.customerShopping).clamp(0, 100));

    return WalletResponseModel(
      items: list,
      walletMaxPercent: maxPct,
      walletCaps: caps,
      currency: json['currency']?.toString() ?? 'BDT',
      currencySymbol: json['currencySymbol']?.toString() ?? '৳',
      currencySymbolPlacement:
          json['currencySymbolPlacement']?.toString() ?? 'left',
    );
  }
}


