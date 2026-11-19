class ManualPaymentFeeModel {
  final int flatMinor;
  final num pct;

  ManualPaymentFeeModel({
    this.flatMinor = 0,
    this.pct = 0,
  });

  factory ManualPaymentFeeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ManualPaymentFeeModel();
    return ManualPaymentFeeModel(
      flatMinor: (json['flatMinor'] as num?)?.toInt() ?? 0,
      pct: (json['pct'] as num?) ?? 0,
    );
  }

  /// Fee calculation (§7):
  /// feeMinor = min(amountMinor, flatMinor + round(amountMinor * pct / 100))
  int calculateFeeMinor(int amountMinor) {
    if (amountMinor <= 0) return 0;
    final pctFee = ((amountMinor * pct) / 100.0).round();
    final computed = flatMinor + pctFee;
    return computed > amountMinor ? amountMinor : computed;
  }
}

class ManualBankDetailModel {
  final String label;
  final String value;

  ManualBankDetailModel({
    required this.label,
    required this.value,
  });

  factory ManualBankDetailModel.fromJson(Map<String, dynamic> json) {
    return ManualBankDetailModel(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class ManualWithdrawalFieldModel {
  final String id;
  final String label;
  final String fieldType; // "text" | "numeric"
  final bool required;
  final String? helpHint;

  ManualWithdrawalFieldModel({
    required this.id,
    required this.label,
    required this.fieldType,
    required this.required,
    this.helpHint,
  });

  factory ManualWithdrawalFieldModel.fromJson(Map<String, dynamic> json) {
    return ManualWithdrawalFieldModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fieldType: json['fieldType']?.toString() ?? 'text',
      required: json['required'] == true,
      helpHint: json['helpHint']?.toString(),
    );
  }
}

class ManualPaymentConfigModel {
  final String name;
  final String tagline;
  final bool enabled;
  final bool bankTransferAvailable;
  final List<ManualBankDetailModel> bankDetails;
  final List<ManualWithdrawalFieldModel> withdrawalFields;
  final ManualPaymentFeeModel depositFee;
  final ManualPaymentFeeModel withdrawFee;

  ManualPaymentConfigModel({
    this.name = 'Alif Pay',
    this.tagline = 'Add money to your Main wallet by bank transfer or at a Service Point.',
    this.enabled = true,
    this.bankTransferAvailable = false,
    this.bankDetails = const [],
    this.withdrawalFields = const [],
    ManualPaymentFeeModel? depositFee,
    ManualPaymentFeeModel? withdrawFee,
  })  : depositFee = depositFee ?? ManualPaymentFeeModel(),
        withdrawFee = withdrawFee ?? ManualPaymentFeeModel();

  factory ManualPaymentConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ManualPaymentConfigModel();
    return ManualPaymentConfigModel(
      name: json['name']?.toString() ?? 'Alif Pay',
      tagline: json['tagline']?.toString() ?? '',
      enabled: json['enabled'] == true,
      bankTransferAvailable: json['bankTransferAvailable'] == true,
      bankDetails: (json['bankDetails'] as List<dynamic>?)
              ?.map((e) => ManualBankDetailModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      withdrawalFields: (json['withdrawalFields'] as List<dynamic>?)
              ?.map((e) =>
                  ManualWithdrawalFieldModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      depositFee: ManualPaymentFeeModel.fromJson(json['depositFee']),
      withdrawFee: ManualPaymentFeeModel.fromJson(json['withdrawFee']),
    );
  }
}

class ServicePointModel {
  final String id;
  final String name;
  final String division;
  final String district;
  final String upazila;
  final String union;
  final String address;
  final int score;
  final bool suggested;

  ServicePointModel({
    required this.id,
    required this.name,
    this.division = '',
    this.district = '',
    this.upazila = '',
    this.union = '',
    this.address = '',
    this.score = 0,
    this.suggested = false,
  });

  factory ServicePointModel.fromJson(Map<String, dynamic> json) {
    return ServicePointModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      division: json['division']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      upazila: json['upazila']?.toString() ?? '',
      union: json['union']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      suggested: json['suggested'] == true,
    );
  }

  String get fullLocationText {
    final parts = [address, union, upazila, district, division]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class WithdrawalAccountDetailModel {
  final String fieldId;
  final String label;
  final String value;

  WithdrawalAccountDetailModel({
    required this.fieldId,
    required this.label,
    required this.value,
  });

  factory WithdrawalAccountDetailModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalAccountDetailModel(
      fieldId: json['fieldId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class WithdrawalAccountModel {
  final String id;
  final String targetKind;
  final String label;
  final List<WithdrawalAccountDetailModel> details;
  final String createdAt;

  WithdrawalAccountModel({
    required this.id,
    required this.targetKind,
    required this.label,
    required this.details,
    required this.createdAt,
  });

  factory WithdrawalAccountModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalAccountModel(
      id: json['id']?.toString() ?? '',
      targetKind: json['targetKind']?.toString() ?? 'customer_main',
      label: json['label']?.toString() ?? '',
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => WithdrawalAccountDetailModel.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  /// Display rule (§5.1):
  /// card label as title and bank name · ••••last4 underneath.
  /// Never show full account number in list row.
  String get maskedSubtitle {
    String bankName = '';
    String accNumber = '';

    for (var d in details) {
      final fId = d.fieldId.toLowerCase();
      final l = d.label.toLowerCase();
      if (bankName.isEmpty && (fId.contains('bank') || l.contains('bank'))) {
        bankName = d.value.trim();
      } else if (accNumber.isEmpty &&
          (fId.contains('account-number') ||
              fId.contains('number') ||
              l.contains('account number') ||
              RegExp(r'^\d+$').hasMatch(d.value.trim()))) {
        accNumber = d.value.trim();
      }
    }

    if (bankName.isEmpty && details.isNotEmpty) {
      bankName = details.first.value.trim();
    }
    if (accNumber.isEmpty && details.length > 1) {
      accNumber = details[1].value.trim();
    }

    String masked = '';
    if (accNumber.isNotEmpty) {
      if (accNumber.length <= 4) {
        masked = '••••$accNumber';
      } else {
        masked = '••••${accNumber.substring(accNumber.length - 4)}';
      }
    }

    if (bankName.isNotEmpty && masked.isNotEmpty) {
      return '$bankName · $masked';
    } else if (masked.isNotEmpty) {
      return masked;
    } else if (bankName.isNotEmpty) {
      return bankName;
    }
    return label;
  }
}

class ManualDepositModel {
  final String id;
  final String targetKind;
  final int amountMinor;
  final int feeMinor;
  final int netMinor;
  final String reference;
  final String proofUrl;
  final String status; // "pending" | "approved" | "rejected"
  final String? rejectReason;
  final String? reviewedAt;
  final String createdAt;

  ManualDepositModel({
    required this.id,
    required this.targetKind,
    required this.amountMinor,
    required this.feeMinor,
    required this.netMinor,
    required this.reference,
    required this.proofUrl,
    required this.status,
    this.rejectReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ManualDepositModel.fromJson(Map<String, dynamic> json) {
    return ManualDepositModel(
      id: json['id']?.toString() ?? '',
      targetKind: json['targetKind']?.toString() ?? 'customer_main',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      feeMinor: (json['feeMinor'] as num?)?.toInt() ?? 0,
      netMinor: (json['netMinor'] as num?)?.toInt() ?? 0,
      reference: json['reference']?.toString() ?? '',
      proofUrl: json['proofUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      rejectReason: json['rejectReason']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  double get amount => amountMinor / 100.0;
  double get fee => feeMinor / 100.0;
  double get net => netMinor / 100.0;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}

class ManualWithdrawalModel {
  final String id;
  final String targetKind;
  final int amountMinor;
  final int feeMinor;
  final int netMinor;
  final List<WithdrawalAccountDetailModel> details;
  final String status; // "pending" | "approved" | "paid" | "rejected"
  final String? rejectReason;
  final String? paidMessage;
  final String? reviewedAt;
  final String createdAt;

  ManualWithdrawalModel({
    required this.id,
    required this.targetKind,
    required this.amountMinor,
    required this.feeMinor,
    required this.netMinor,
    required this.details,
    required this.status,
    this.rejectReason,
    this.paidMessage,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ManualWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return ManualWithdrawalModel(
      id: json['id']?.toString() ?? '',
      targetKind: json['targetKind']?.toString() ?? 'customer_main',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      feeMinor: (json['feeMinor'] as num?)?.toInt() ?? 0,
      netMinor: (json['netMinor'] as num?)?.toInt() ?? 0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => WithdrawalAccountDetailModel.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'pending',
      rejectReason: json['rejectReason']?.toString(),
      paidMessage: json['paidMessage']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  double get amount => amountMinor / 100.0;
  double get fee => feeMinor / 100.0;
  double get net => netMinor / 100.0;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isRejected => status.toLowerCase() == 'rejected';
}
