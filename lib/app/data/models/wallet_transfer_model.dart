class WalletTransferLookupModel {
  final String name;
  final String? maskedPhone;
  final String side; // "customer" | "seller"
  final String toKind; // "customer_main" | "seller_main"
  final int toBalanceMinor;

  WalletTransferLookupModel({
    required this.name,
    this.maskedPhone,
    required this.side,
    required this.toKind,
    this.toBalanceMinor = 0,
  });

  double get toBalance => toBalanceMinor / 100.0;
  bool get isSeller => side.toLowerCase() == 'seller';
  bool get isCustomer => !isSeller;

  String get sideBadgeLabel => isSeller ? 'Seller' : 'Customer';

  factory WalletTransferLookupModel.fromJson(Map<String, dynamic> json) {
    return WalletTransferLookupModel(
      name: json['name']?.toString() ?? '',
      maskedPhone: json['maskedPhone']?.toString(),
      side: json['side']?.toString() ?? 'customer',
      toKind: json['toKind']?.toString() ?? 'customer_main',
      toBalanceMinor: (json['toBalanceMinor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'maskedPhone': maskedPhone,
        'side': side,
        'toKind': toKind,
        'toBalanceMinor': toBalanceMinor,
      };
}

class WalletTransferResultModel {
  final String id;
  final String fromKind;
  final String toKind;
  final int amountMinor;
  final int toBalanceMinor;
  final int fromBalanceMinor;
  final DateTime? createdAt;
  final WalletTransferLookupModel? recipient;

  WalletTransferResultModel({
    required this.id,
    required this.fromKind,
    required this.toKind,
    required this.amountMinor,
    required this.toBalanceMinor,
    required this.fromBalanceMinor,
    this.createdAt,
    this.recipient,
  });

  double get amount => amountMinor / 100.0;
  double get toBalance => toBalanceMinor / 100.0;
  double get fromBalance => fromBalanceMinor / 100.0;

  factory WalletTransferResultModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    WalletTransferLookupModel? recipientModel;
    if (json['recipient'] is Map<String, dynamic>) {
      recipientModel = WalletTransferLookupModel.fromJson(
        Map<String, dynamic>.from(json['recipient']),
      );
    }

    return WalletTransferResultModel(
      id: json['id']?.toString() ?? '',
      fromKind: json['fromKind']?.toString() ?? 'customer_main',
      toKind: json['toKind']?.toString() ?? 'customer_main',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      toBalanceMinor: (json['toBalanceMinor'] as num?)?.toInt() ?? 0,
      fromBalanceMinor: (json['fromBalanceMinor'] as num?)?.toInt() ?? 0,
      createdAt: created,
      recipient: recipientModel,
    );
  }
}
