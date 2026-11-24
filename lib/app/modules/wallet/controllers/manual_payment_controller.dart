// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/manual_payment_model.dart';
import '../../../data/models/redeem_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import 'manual_payment_cards_mixin.dart';
import 'wallet_controller.dart';

class ManualPaymentController extends GetxController
    with ManualPaymentCardsMixin {
  // Config
  final config = Rxn<ManualPaymentConfigModel>();
  final isLoadingConfig = false.obs;

  // Service Points
  final servicePoints = <ServicePointModel>[].obs;
  final isLoadingServicePoints = false.obs;

  // Deposit Form State & Submissions
  final isSubmittingDeposit = false.obs;
  final depositTab = 0.obs;
  final enteredDepositAmount = 0.0.obs;
  final depositAmountCtrl = TextEditingController();
  final depositRefCtrl = TextEditingController();

  // Deposits List
  final deposits = <ManualDepositModel>[].obs;
  final isLoadingDeposits = false.obs;
  final depositNextCursor = RxnString();

  // Withdrawal Form State & Submissions
  final isSubmittingWithdrawal = false.obs;
  final withdrawals = <ManualWithdrawalModel>[].obs;
  final isLoadingWithdrawals = false.obs;
  final withdrawalNextCursor = RxnString();

  // Withdraw Sheet UI State
  final withdrawTab = 0.obs;
  final isAddingNewCard = false.obs;
  final enteredWithdrawAmount = 0.0.obs;
  final withdrawAmountCtrl = TextEditingController();
  final cardLabelCtrl = TextEditingController();
  final dynamicFieldCtrls = <String, TextEditingController>{};

  TextEditingController getWithdrawFieldCtrl(String id) {
    if (!dynamicFieldCtrls.containsKey(id)) {
      dynamicFieldCtrls[id] = TextEditingController();
    }
    return dynamicFieldCtrls[id]!;
  }

  void openDepositSheet() {
    depositTab.value = 0;
    depositAmountCtrl.clear();
    depositRefCtrl.clear();
    enteredDepositAmount.value = 0.0;
    clearUploadedReceipt();
    fetchConfig();
    fetchServicePoints();
    fetchDeposits(refresh: true);
  }

  void openWithdrawSheet() {
    withdrawTab.value = 0;
    withdrawAmountCtrl.clear();
    cardLabelCtrl.clear();
    for (var c in dynamicFieldCtrls.values) {
      c.clear();
    }
    enteredWithdrawAmount.value = 0.0;
    isAddingNewCard.value = false;
    pendingDeleteCardId.value = null;
    fetchConfig();
    fetchWithdrawalAccounts();
    fetchWithdrawals(refresh: true);
  }

  @override
  void onInit() {
    super.onInit();
    fetchConfig();

    depositAmountCtrl.addListener(() {
      final val = double.tryParse(depositAmountCtrl.text.trim()) ?? 0.0;
      if (val != enteredDepositAmount.value) {
        enteredDepositAmount.value = val;
      }
    });

    withdrawAmountCtrl.addListener(() {
      final val = double.tryParse(withdrawAmountCtrl.text.trim()) ?? 0.0;
      if (val != enteredWithdrawAmount.value) {
        enteredWithdrawAmount.value = val;
      }
    });
  }

  @override
  void onClose() {
    depositAmountCtrl.dispose();
    depositRefCtrl.dispose();
    withdrawAmountCtrl.dispose();
    cardLabelCtrl.dispose();
    for (var c in dynamicFieldCtrls.values) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> fetchConfig() async {
    isLoadingConfig.value = true;
    try {
      final response = await dioGet('manual-payments/config');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          config.value = ManualPaymentConfigModel.fromJson(rawData);
        }
      }
    } catch (e) {
      debugPrint('Error fetching manual payments config: $e');
    } finally {
      isLoadingConfig.value = false;
    }
  }

  Future<void> fetchServicePoints() async {
    isLoadingServicePoints.value = true;
    try {
      final response = await dioGet('service-points');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData['items'] is List) {
          final list = (rawData['items'] as List)
              .map((e) =>
                  ServicePointModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          servicePoints.assignAll(list);
        }
      }
    } catch (e) {
      debugPrint('Error fetching service points: $e');
    } finally {
      isLoadingServicePoints.value = false;
    }
  }

  Future<bool> createDeposit({
    required double amount,
    required String reference,
  }) async {
    if (isSubmittingDeposit.value) return false;

    final amountMinor = (amount * 100).round();
    if (amountMinor <= 0) {
      showSnack('Invalid Amount', 'Please enter a valid deposit amount');
      return false;
    }

    final trimmedRef = reference.trim();
    if (trimmedRef.isEmpty) {
      showSnack('Reference Required', 'Please enter bank transaction reference');
      return false;
    }

    if (uploadedReceiptUrl.value == null ||
        uploadedReceiptUrl.value!.trim().isEmpty) {
      showSnack('Receipt Required', 'Please upload deposit receipt/proof');
      return false;
    }

    isSubmittingDeposit.value = true;
    try {
      final payload = <String, dynamic>{
        'amountMinor': amountMinor,
        'reference': trimmedRef,
        'proofUrl': uploadedReceiptUrl.value!.trim(),
      };

      final response = await dioPost(
        endUrl: 'manual-payments/deposits',
        data: payload,
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnack('Deposit Submitted', 'Waiting for verification by admin');
        clearUploadedReceipt();
        await fetchDeposits(refresh: true);
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().refreshAll();
        }
        return true;
      } else {
        final err = _extractErrorMessage(response.data);
        showSnack('Deposit Failed', err ?? 'Failed to submit deposit');
        return false;
      }
    } catch (e) {
      showSnack('Error', 'Failed to submit deposit: $e');
      return false;
    } finally {
      isSubmittingDeposit.value = false;
    }
  }

  Future<void> fetchDeposits({bool refresh = true}) async {
    if (refresh) {
      isLoadingDeposits.value = true;
      depositNextCursor.value = null;
    } else {
      if (depositNextCursor.value == null || isLoadingDeposits.value) return;
    }

    try {
      String query = 'limit=20';
      if (!refresh && depositNextCursor.value != null) {
        query += '&cursor=${depositNextCursor.value}';
      }

      final response = await dioGet('manual-payments/deposits?$query');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map) {
          final items = (rawData['items'] as List<dynamic>?)
                  ?.map((e) =>
                      ManualDepositModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          if (refresh) {
            deposits.assignAll(items);
          } else {
            deposits.addAll(items);
          }
          depositNextCursor.value = rawData['nextCursor']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetching deposits: $e');
    } finally {
      isLoadingDeposits.value = false;
    }
  }

  /// POST /manual-payments/withdrawals with Idempotency-Key
  Future<WalletPinActionResult> executeWithdrawal({
    required double amount,
    required String walletPin,
    String? accountId,
    Map<String, dynamic>? fallbackDetails,
  }) async {
    if (isSubmittingWithdrawal.value) {
      return const WalletPinActionResult.failure(
        errorCode: 'ALREADY_PROCESSING',
        errorMessage: 'Withdrawal is already in progress',
      );
    }

    final amountMinor = (amount * 100).round();
    final targetAccountId = accountId ?? selectedAccountId.value;

    final payload = <String, dynamic>{
      'amountMinor': amountMinor,
      if (targetAccountId != null && targetAccountId.isNotEmpty)
        'accountId': targetAccountId
      else if (fallbackDetails != null && fallbackDetails.isNotEmpty)
        'details': fallbackDetails,
      'walletPin': walletPin,
    };

    isSubmittingWithdrawal.value = true;
    try {
      final idempotencyKey = generateUuidV4();
      final response = await dioPost(
        endUrl: 'manual-payments/withdrawals',
        data: payload,
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnack(
          'Withdrawal Requested',
          'Request submitted and pending admin approval',
        );
        if (Get.isRegistered<WalletController>()) {
          await Get.find<WalletController>().fetchWallets();
          Get.find<WalletController>().fetchTransactions(refresh: true);
        }
        await fetchWithdrawals(refresh: true);
        return const WalletPinActionResult.success();
      } else {
        var errCode = _extractErrorCode(response.data) ?? 'WITHDRAWAL_FAILED';
        var errMsg =
            _extractErrorMessage(response.data) ?? 'Failed to submit withdrawal';

        if (response.statusCode == 409 || errCode == 'INSUFFICIENT_BALANCE') {
          errCode = 'INSUFFICIENT_BALANCE';
          errMsg = errMsg.isNotEmpty && errMsg != 'Failed to submit withdrawal'
              ? errMsg
              : 'Insufficient balance in Main wallet for this withdrawal.';
          if (Get.isRegistered<WalletController>()) {
            Get.find<WalletController>().fetchWallets();
          }
        }

        return WalletPinActionResult.failure(
          errorCode: errCode,
          errorMessage: errMsg,
        );
      }
    } catch (e) {
      return WalletPinActionResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Network error: $e',
      );
    } finally {
      isSubmittingWithdrawal.value = false;
    }
  }

  Future<void> fetchWithdrawals({bool refresh = true}) async {
    if (refresh) {
      isLoadingWithdrawals.value = true;
      withdrawalNextCursor.value = null;
    } else {
      if (withdrawalNextCursor.value == null || isLoadingWithdrawals.value) return;
    }

    try {
      String query = 'limit=20';
      if (!refresh && withdrawalNextCursor.value != null) {
        query += '&cursor=${withdrawalNextCursor.value}';
      }

      final response = await dioGet('manual-payments/withdrawals?$query');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map) {
          final items = (rawData['items'] as List<dynamic>?)
                  ?.map((e) => ManualWithdrawalModel.fromJson(
                      Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          if (refresh) {
            withdrawals.assignAll(items);
          } else {
            withdrawals.addAll(items);
          }
          withdrawalNextCursor.value = rawData['nextCursor']?.toString();

          if (refresh && items.any((w) => w.isRejected)) {
            if (Get.isRegistered<WalletController>()) {
              Get.find<WalletController>().fetchWallets();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching withdrawals: $e');
    } finally {
      isLoadingWithdrawals.value = false;
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data['error'] is Map && data['error']['message'] != null) {
        return data['error']['message'].toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return null;
  }

  String? _extractErrorCode(dynamic data) {
    if (data is Map && data['error'] is Map && data['error']['code'] != null) {
      return data['error']['code'].toString();
    }
    return null;
  }
}
