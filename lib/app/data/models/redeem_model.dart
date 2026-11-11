import 'dart:math';

String generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));

  // Set version to 4 (0100)
  values[6] = (values[6] & 0x0f) | 0x40;
  // Set variant to RFC 4122 (10xx)
  values[8] = (values[8] & 0x3f) | 0x80;

  final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

class RedeemShareModel {
  final String key;
  final String walletKind;
  final int amountMinor;

  RedeemShareModel({
    required this.key,
    required this.walletKind,
    required this.amountMinor,
  });

  double get amount => amountMinor / 100.0;

  String get displayName {
    switch (key) {
      case 'main':
        return 'Main Wallet';
      case 'shopping':
        return 'Shopping Wallet';
      case 'good_luck':
        return 'Good-Luck Bonus';
      case 'charity':
        return 'Charity Contribution';
      case 'service_charge':
        return 'Platform Service Charge';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory RedeemShareModel.fromJson(Map<String, dynamic> json) {
    return RedeemShareModel(
      key: json['key']?.toString() ?? '',
      walletKind: json['walletKind']?.toString() ?? '',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
    );
  }
}

class RedeemPreviewResponseModel {
  final String walletKind;
  final int amountMinor;
  final List<RedeemShareModel> shares;

  RedeemPreviewResponseModel({
    required this.walletKind,
    required this.amountMinor,
    required this.shares,
  });

  double get amount => amountMinor / 100.0;

  List<RedeemShareModel> get receiveShares {
    return shares
        .where((s) => s.key != 'service_charge' && s.amountMinor > 0)
        .toList();
  }

  List<RedeemShareModel> get deductedShares {
    return shares
        .where((s) => s.key == 'service_charge' && s.amountMinor > 0)
        .toList();
  }

  factory RedeemPreviewResponseModel.fromJson(Map<String, dynamic> json) {
    final sList = (json['shares'] as List<dynamic>?)
            ?.map((e) =>
                RedeemShareModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return RedeemPreviewResponseModel(
      walletKind: json['walletKind']?.toString() ?? '',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      shares: sList,
    );
  }
}
