import 'manual_payment_model.dart';
import 'wallet_model.dart';

class TransactionManualBlockModel {
  final String kind; // 'deposit' | 'withdrawal'
  final String status; // 'pending' | 'approved' | 'paid' | 'rejected'
  final int amountMinor;
  final int feeMinor;
  final int netMinor;
  final String? reference;
  final String? proofUrl;
  final List<WithdrawalAccountDetailModel> details;
  final String? rejectReason;
  final String? paidMessage;
  final DateTime? reviewedAt;

  TransactionManualBlockModel({
    required this.kind,
    required this.status,
    required this.amountMinor,
    required this.feeMinor,
    required this.netMinor,
    this.reference,
    this.proofUrl,
    this.details = const [],
    this.rejectReason,
    this.paidMessage,
    this.reviewedAt,
  });

  bool get isDeposit => kind.toLowerCase() == 'deposit';
  bool get isWithdrawal => kind.toLowerCase() == 'withdrawal';

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isRejected => status.toLowerCase() == 'rejected';

  double get amount => amountMinor / 100.0;
  double get fee => feeMinor / 100.0;
  double get net => netMinor / 100.0;

  String get maskedCardSummary {
    if (details.isEmpty) return '';
    String bankName = '';
    String acctNo = '';
    for (var d in details) {
      final l = d.label.toLowerCase();
      if (l.contains('bank') ||
          l.contains('method') ||
          l.contains('provider') ||
          l.contains('name')) {
        if (bankName.isEmpty) bankName = d.value;
      }
      if (l.contains('number') ||
          l.contains('account') ||
          l.contains('no') ||
          l.contains('acct') ||
          l.contains('wallet')) {
        acctNo = d.value;
      }
    }
    if (bankName.isEmpty && details.isNotEmpty) {
      bankName = details.first.value;
    }
    if (acctNo.isNotEmpty) {
      final clean = acctNo.trim();
      final last4 =
          clean.length > 4 ? clean.substring(clean.length - 4) : clean;
      return bankName.isNotEmpty ? '$bankName · ••••$last4' : '••••$last4';
    }
    return bankName;
  }

  factory TransactionManualBlockModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedReviewed;
    final rStr =
        json['reviewedAt']?.toString() ?? json['reviewed_at']?.toString();
    if (rStr != null && rStr.isNotEmpty) {
      try {
        parsedReviewed = DateTime.parse(rStr);
      } catch (_) {}
    }

    final rawDetails = json['details'] as List<dynamic>?;
    final parsedDetails = rawDetails
            ?.map((e) => WithdrawalAccountDetailModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return TransactionManualBlockModel(
      kind: json['kind']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      feeMinor: (json['feeMinor'] as num?)?.toInt() ?? 0,
      netMinor: (json['netMinor'] as num?)?.toInt() ?? 0,
      reference: json['reference']?.toString(),
      proofUrl: json['proofUrl']?.toString() ?? json['proof_url']?.toString(),
      details: parsedDetails,
      rejectReason: json['rejectReason']?.toString() ??
          json['reject_reason']?.toString(),
      paidMessage:
          json['paidMessage']?.toString() ?? json['paid_message']?.toString(),
      reviewedAt: parsedReviewed,
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
  final String? referenceType;
  final String? referenceId;
  final String? status;
  final DateTime? createdAt;
  final TransactionManualBlockModel? manual;

  WalletTransactionModel({
    required this.id,
    required this.walletKind,
    required this.amountMinor,
    this.type,
    this.balanceAfterMinor,
    required this.reason,
    this.referenceType,
    this.referenceId,
    this.status,
    this.createdAt,
    this.manual,
  });

  bool get isManual => manual != null;

  bool get isCredit {
    if (reason.toLowerCase() == 'manual_withdraw_refund') {
      return true;
    }
    if (type != null) {
      return type!.toLowerCase().contains('credit');
    }
    if (manual != null) {
      return manual!.isDeposit;
    }
    final r = reason.toLowerCase();
    if (r == 'wallet_transfer_out') return false;
    if (r == 'wallet_transfer_in') return true;
    return amountMinor >= 0;
  }

  double get amount => (amountMinor.abs()) / 100.0;

  String formattedAmount({String symbol = '৳'}) {
    final sign = isCredit ? '+' : '-';
    return '$sign $symbol ${amount.toStringAsFixed(2)}';
  }

  String get formattedBalanceAfter {
    if (balanceAfterMinor == null) return '—';
    final val = balanceAfterMinor! / 100.0;
    return '৳${val.toStringAsFixed(2)}';
  }

  String get displayTitle {
    if (reason.toLowerCase() == 'manual_withdraw_refund') {
      return 'Withdrawal Refund';
    }
    if (manual != null) {
      return manual!.isDeposit ? 'Alif Pay Deposit' : 'Withdrawal (Hold)';
    }
    switch (reason.toLowerCase()) {
      case 'manual_deposit':
        return 'Alif Pay Deposit';
      case 'manual_withdraw':
      case 'manual_withdrawal':
        return 'Withdrawal (Hold)';
      case 'manual_withdraw_refund':
        return 'Withdrawal Refund';
      case 'wallet_transfer_out':
        return 'Sent Money';
      case 'wallet_transfer_in':
        return 'Received Money';
      case 'order_cashback':
        return 'Order Cashback';
      case 'order_payment':
        return 'Order Checkout';
      case 'order_refund':
        return 'Order Refund';
      case 'redeem':
        return 'Bonus Redeem';
      case 'wallet_redeem':
        return 'Wallet Redeem';
      case 'lottery_ticket':
        return 'Lottery Ticket Purchase';
      case 'lottery_prize':
        return 'Lottery Prize Win';
      case 'referral_bonus':
        return 'Referral Bonus';
      case 'club_bonus':
        return 'Club Bonus';
      case 'star_bonus':
        return 'Star Bonus';
      case 'registration_bonus':
        return 'Welcome Bonus';
      case 'service_point_deposit':
        return 'Cash In (Service Point)';
      default:
        if (reason.isNotEmpty) {
          return reason
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ');
        }
        if (referenceId != null && referenceId!.isNotEmpty) {
          return isCredit
              ? 'Credit: #$referenceId'
              : 'Payment: #$referenceId';
        }
        return isCredit ? 'Wallet Credit' : 'Wallet Debit';
    }
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

    final manualJson = json['manual'] as Map<String, dynamic>?;
    final manualBlock = manualJson != null
        ? TransactionManualBlockModel.fromJson(manualJson)
        : null;

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
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString() ??
          json['reference']?.toString() ??
          json['orderId']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      createdAt: parsedDate,
      manual: manualBlock,
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

class WalletPendingOrderModel {
  final String orderId;
  final String orderNumber;
  final int points;
  final int estimatedCashbackMinor;
  final DateTime? returnWindowEndsAt;
  final DateTime? deliveredAt;

  WalletPendingOrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.points,
    required this.estimatedCashbackMinor,
    this.returnWindowEndsAt,
    this.deliveredAt,
  });

  double get estimatedCashback => estimatedCashbackMinor / 100.0;

  String get formattedPostsDate {
    if (returnWindowEndsAt == null) return 'Pending';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dt = returnWindowEndsAt!;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  factory WalletPendingOrderModel.fromJson(Map<String, dynamic> json) {
    DateTime? returnEnds;
    DateTime? delivered;
    if (json['returnWindowEndsAt'] != null) {
      try {
        returnEnds = DateTime.parse(json['returnWindowEndsAt'].toString());
      } catch (_) {}
    }
    if (json['deliveredAt'] != null) {
      try {
        delivered = DateTime.parse(json['deliveredAt'].toString());
      } catch (_) {}
    }
    return WalletPendingOrderModel(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      estimatedCashbackMinor:
          (json['estimatedCashbackMinor'] as num?)?.toInt() ?? 0,
      returnWindowEndsAt: returnEnds,
      deliveredAt: delivered,
    );
  }
}

class WalletPendingPointsResponseModel {
  final int totalPoints;
  final int estimatedCashbackMinor;
  final List<WalletPendingOrderModel> orders;

  WalletPendingPointsResponseModel({
    required this.totalPoints,
    required this.estimatedCashbackMinor,
    required this.orders,
  });

  double get estimatedCashback => estimatedCashbackMinor / 100.0;

  factory WalletPendingPointsResponseModel.fromJson(Map<String, dynamic> json) {
    final oList = (json['orders'] as List<dynamic>?)
            ?.map((e) =>
                WalletPendingOrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WalletPendingPointsResponseModel(
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      estimatedCashbackMinor:
          (json['estimatedCashbackMinor'] as num?)?.toInt() ?? 0,
      orders: oList,
    );
  }
}
