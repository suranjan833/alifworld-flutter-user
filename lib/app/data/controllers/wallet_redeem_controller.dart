import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../models/redeem_model.dart';
import '../models/wallet_model.dart';
import '../widgets/wallet_pin_dialog.dart';

class WalletRedeemController extends GetxController {
  static const Set<String> redeemableKinds = {
    'customer_cashback',
    'customer_referral',
    'customer_club_bonus',
    'customer_star_bonus',
    'customer_advanced_return',
  };

  final validWallets = <WalletItemModel>[].obs;
  final selectedKind = 'customer_cashback'.obs;
  final amountController = TextEditingController();

  final isPreviewLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final preview = Rxn<RedeemPreviewResponseModel>();
  VoidCallback? onRedeemSuccess;

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(() {
      if (preview.value != null) {
        preview.value = null;
        errorMessage.value = null;
      }
    });
  }

  void initSheet({
    required List<WalletItemModel> wallets,
    String? initialWalletKind,
    required VoidCallback onRedeemSuccess,
  }) {
    this.onRedeemSuccess = onRedeemSuccess;
    amountController.clear();
    errorMessage.value = null;
    preview.value = null;
    isPreviewLoading.value = false;
    isSubmitting.value = false;

    final filtered = wallets.where((w) => redeemableKinds.contains(w.kind)).toList();
    validWallets.assignAll(filtered);

    if (filtered.isEmpty) {
      selectedKind.value = 'customer_cashback';
    } else if (initialWalletKind != null && redeemableKinds.contains(initialWalletKind)) {
      selectedKind.value = initialWalletKind;
    } else {
      selectedKind.value = filtered.first.kind;
    }
  }

  WalletItemModel? get currentWallet {
    try {
      return validWallets.firstWhere((w) => w.kind == selectedKind.value);
    } catch (_) {
      return null;
    }
  }

  void selectWallet(String kind) {
    if (selectedKind.value != kind) {
      selectedKind.value = kind;
      amountController.clear();
      preview.value = null;
      errorMessage.value = null;
    }
  }

  void fillMaxAmount() {
    final bal = currentWallet?.balance ?? 0.0;
    if (bal <= 0) return;
    amountController.text = bal.toStringAsFixed(2);
    fetchPreview();
  }

  Future<void> fetchPreview() async {
    final text = amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      errorMessage.value = 'Please enter a valid amount in ৳';
      return;
    }

    final amountMinor = (amount * 100).round();
    final currentBalMinor = currentWallet?.balanceMinor ?? 0;

    if (amountMinor > currentBalMinor) {
      errorMessage.value = 'Amount exceeds available balance';
      return;
    }

    isPreviewLoading.value = true;
    errorMessage.value = null;

    try {
      final res = await dioPost(
        endUrl: 'wallets/redeem/preview',
        data: {
          'walletKind': selectedKind.value,
          'amountMinor': amountMinor,
        },
        isJson: true,
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode == 200 && data is Map<String, dynamic>) {
        preview.value = RedeemPreviewResponseModel.fromJson(data);
        errorMessage.value = null;
      } else {
        preview.value = null;
        errorMessage.value = error?['message'] ?? raw['message'] ?? 'Unable to preview redeem';
      }
    } catch (e) {
      errorMessage.value = 'Network error during preview: $e';
    } finally {
      isPreviewLoading.value = false;
    }
  }

  Future<void> executeRedeem(BuildContext context) async {
    if (preview.value == null) {
      await fetchPreview();
      if (preview.value == null || !context.mounted) return;
    }

    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Confirm Redeem PIN',
      subtitle: 'Enter your 4-digit wallet PIN to complete redemption',
    );

    if (pin == null || pin.isEmpty) return;

    final idempotencyKey = generateUuidV4();
    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final res = await dioPost(
        endUrl: 'wallets/redeem',
        data: {
          'walletKind': preview.value!.walletKind,
          'amountMinor': preview.value!.amountMinor,
          'idempotencyKey': idempotencyKey,
          'walletPin': pin,
        },
        isJson: true,
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode >= 200 && statusCode < 300) {
        showSnack(
          'Redeem Successful',
          '৳${preview.value!.amount.toStringAsFixed(2)} redeemed successfully!',
          bg: AppColor.green,
        );
        onRedeemSuccess?.call();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final code = error?['code']?.toString() ?? '';
        final msg = error?['message']?.toString() ?? raw['message']?.toString() ?? 'Redemption failed';
        if (code == 'WALLET_PIN_INVALID') {
          showSnack('Invalid PIN', msg, bg: AppColor.red);
        } else if (code == 'WALLET_PIN_LOCKED') {
          showSnack('PIN Locked', msg, bg: AppColor.red);
        } else {
          errorMessage.value = msg;
        }
      }
    } catch (e) {
      errorMessage.value = 'Error executing redeem: $e';
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
