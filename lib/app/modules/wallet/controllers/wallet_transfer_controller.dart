import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/redeem_model.dart';
import '../../../data/models/wallet_transfer_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import 'wallet_controller.dart';

class WalletTransferController extends GetxController {
  static WalletTransferController get to => Get.find<WalletTransferController>();

  final phoneController = TextEditingController();
  final amountController = TextEditingController();

  final isLookingUp = false.obs;
  final isTransferring = false.obs;

  final lookupResult = Rxn<WalletTransferLookupModel>();
  final transferResult = Rxn<WalletTransferResultModel>();

  final lookupError = RxnString();
  final amountError = RxnString();
  final transferError = RxnString();

  WalletController get _walletController => Get.find<WalletController>();

  double get senderMainBalance => _walletController.mainBalance.value;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(() {
      if (lookupError.value != null) {
        lookupError.value = null;
      }
    });
    amountController.addListener(() {
      if (amountError.value != null) {
        amountError.value = null;
      }
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    amountController.dispose();
    super.onClose();
  }

  void resetForm() {
    phoneController.clear();
    amountController.clear();
    lookupResult.value = null;
    transferResult.value = null;
    lookupError.value = null;
    amountError.value = null;
    transferError.value = null;
    isLookingUp.value = false;
    isTransferring.value = false;
  }

  void changeRecipient() {
    lookupResult.value = null;
    lookupError.value = null;
    amountError.value = null;
    transferError.value = null;
  }

  /// 1. Lookup recipient: GET /api/v1/wallet-transfers/lookup?phone=
  Future<void> lookupRecipient() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      lookupError.value = 'Please enter a recipient phone number';
      return;
    }

    isLookingUp.value = true;
    lookupError.value = null;
    lookupResult.value = null;

    try {
      final response = await dioGet('wallet-transfers/lookup?phone=$phone');
      final statusCode = response.statusCode ?? 500;
      final raw = response.data is Map ? response.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode == 200 && data is Map<String, dynamic>) {
        lookupResult.value = WalletTransferLookupModel.fromJson(data);
        lookupError.value = null;
      } else {
        final code = error?['code']?.toString() ?? '';
        final msg = error?['message']?.toString() ?? 'Failed to find account';

        if (code == 'RECIPIENT_NOT_FOUND' || statusCode == 404) {
          lookupError.value = 'No account for this phone number';
        } else if (code == 'SELF_TRANSFER') {
          lookupError.value = "You can't transfer money to yourself";
        } else {
          lookupError.value = msg;
        }
      }
    } catch (e) {
      lookupError.value = 'Connection error. Please try again.';
    } finally {
      isLookingUp.value = false;
    }
  }

  void setQuickAmount(double amount) {
    if (amount > senderMainBalance) {
      amountController.text = senderMainBalance.toStringAsFixed(2);
    } else {
      amountController.text = amount.toStringAsFixed(0);
    }
    validateAmount();
  }

  bool validateAmount() {
    final text = amountController.text.trim();
    if (text.isEmpty) {
      amountError.value = 'Please enter transfer amount';
      return false;
    }
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      amountError.value = 'Enter a valid positive amount';
      return false;
    }
    if (val > senderMainBalance) {
      amountError.value = 'Insufficient Main wallet balance';
      return false;
    }
    amountError.value = null;
    return true;
  }

  /// 2. Prompt PIN & POST /api/v1/wallet-transfers
  Future<void> initiateTransfer(BuildContext context) async {
    if (lookupResult.value == null) {
      lookupError.value = 'Please find and select a recipient first';
      return;
    }
    if (!validateAmount()) return;

    transferError.value = null;

    await WalletPinDialog.promptPin(
      context,
      title: 'Authorize Transfer',
      subtitle:
          'Transfer ৳${amountController.text.trim()} to ${lookupResult.value!.name}',
      onConfirm: (pin) => _executeTransfer(pin),
    );
  }

  Future<WalletPinActionResult> _executeTransfer(String pin) async {
    isTransferring.value = true;
    final phone = phoneController.text.trim();
    final amountVal = double.tryParse(amountController.text.trim()) ?? 0.0;
    final amountMinor = (amountVal * 100).round();
    final idempotencyKey = generateUuidV4();

    final payload = <String, dynamic>{
      'recipientPhone': phone,
      'amountMinor': amountMinor,
      'walletPin': pin,
    };

    try {
      final response = await dioPost(
        endUrl: 'wallet-transfers',
        data: payload,
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      final statusCode = response.statusCode ?? 500;
      final raw = response.data is Map ? response.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if ((statusCode == 200 || statusCode == 201) &&
          data is Map<String, dynamic>) {
        final result = WalletTransferResultModel.fromJson(data);
        transferResult.value = result;

        // Refresh sender's wallet balances and transaction history
        _walletController.refreshAll();

        return const WalletPinActionResult.success();
      } else {
        final code = error?['code']?.toString() ?? '';
        final msg = error?['message']?.toString() ?? 'Transfer failed';

        // Keep PIN sheet open on WALLET_PIN_* errors
        if (code.startsWith('WALLET_PIN_')) {
          return WalletPinActionResult.failure(
            errorCode: code,
            errorMessage: msg,
          );
        }

        transferError.value = msg;
        return WalletPinActionResult.failure(
          errorCode: code,
          errorMessage: msg,
        );
      }
    } catch (e) {
      transferError.value = 'An unexpected error occurred: $e';
      return WalletPinActionResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Network error. Please try again.',
      );
    } finally {
      isTransferring.value = false;
    }
  }
}
