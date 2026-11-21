// ignore_for_file: library_prefixes

import 'package:dio/dio.dart' as DIO;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/manual_payment_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import 'wallet_controller.dart';

class ManualPaymentController extends GetxController {
  // §2 Config
  final config = Rxn<ManualPaymentConfigModel>();
  final isLoadingConfig = false.obs;

  // §4 Service Points
  final servicePoints = <ServicePointModel>[].obs;
  final isLoadingServicePoints = false.obs;

  // §5 Saved Cards / Accounts
  final withdrawalAccounts = <WithdrawalAccountModel>[].obs;
  final isLoadingAccounts = false.obs;
  final selectedAccountId = RxnString();
  final isDeletingAccountId = RxnString();
  final pendingDeleteCardId = RxnString(); // For 2-tap confirm (§5.3)

  // §3 Deposit Form & Upload
  final isUploadingReceipt = false.obs;
  final localReceiptPath = RxnString();
  final uploadedReceiptUrl = RxnString();
  final uploadedReceiptName = RxnString();
  final isSubmittingDeposit = false.obs;

  // Deposit Sheet UI State & Controllers (AddMoneySheet)
  final depositTab = 0.obs; // 0: Bank Transfer, 1: Service Point, 2: History
  final enteredDepositAmount = 0.0.obs;
  final depositAmountCtrl = TextEditingController();
  final depositRefCtrl = TextEditingController();

  // §3.3 Deposits List
  final deposits = <ManualDepositModel>[].obs;
  final isLoadingDeposits = false.obs;
  final depositNextCursor = RxnString();

  // §6 Withdrawal Form & List
  final isSubmittingWithdrawal = false.obs;
  final withdrawals = <ManualWithdrawalModel>[].obs;
  final isLoadingWithdrawals = false.obs;
  final withdrawalNextCursor = RxnString();

  // Withdraw Sheet UI State & Controllers (WithdrawSheet)
  final withdrawTab = 0.obs; // 0: Withdraw, 1: History
  final isAddingNewCard = false.obs;
  final enteredWithdrawAmount = 0.0.obs;
  final withdrawAmountCtrl = TextEditingController();
  final cardLabelCtrl = TextEditingController();
  final dynamicFieldCtrls = <String, TextEditingController>{};

  final ImagePicker _picker = ImagePicker();

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
    localReceiptPath.value = null;
    uploadedReceiptUrl.value = null;
    uploadedReceiptName.value = null;
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

  /// §2 GET /manual-payments/config
  /// Never cached across sessions; reload whenever sheet opens.
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

  /// §4 GET /service-points
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
              .map((e) => ServicePointModel.fromJson(Map<String, dynamic>.from(e)))
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

  /// §5.1 GET /manual-payments/withdrawal-accounts
  Future<void> fetchWithdrawalAccounts() async {
    isLoadingAccounts.value = true;
    try {
      final response = await dioGet('manual-payments/withdrawal-accounts');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData['items'] is List) {
          final list = (rawData['items'] as List)
              .map((e) =>
                  WithdrawalAccountModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          withdrawalAccounts.assignAll(list);

          // §6.1 Auto-select the first card when list loads
          if (withdrawalAccounts.isNotEmpty) {
            if (selectedAccountId.value == null ||
                !withdrawalAccounts.any((a) => a.id == selectedAccountId.value)) {
              selectedAccountId.value = withdrawalAccounts.first.id;
            }
          } else {
            selectedAccountId.value = null;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching withdrawal accounts: $e');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  /// §5.2 POST /manual-payments/withdrawal-accounts
  Future<bool> createWithdrawalAccount({
    required String label,
    required Map<String, dynamic> details,
  }) async {
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      showSnack('Validation Error', 'Card label / nickname is required');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'label': trimmedLabel,
        'details': details,
      };

      final response = await dioPost(
        endUrl: 'manual-payments/withdrawal-accounts',
        data: payload,
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map<String, dynamic>) {
          final newCard = WithdrawalAccountModel.fromJson(rawData);
          withdrawalAccounts.insert(0, newCard);
          // Auto select immediately after saving (§5.2)
          selectedAccountId.value = newCard.id;
          showSnack('Success', 'Bank card added successfully');
          return true;
        }
        await fetchWithdrawalAccounts();
        return true;
      } else {
        final err = _extractErrorMessage(response.data);
        showSnack('Error', err ?? 'Failed to add card');
        return false;
      }
    } catch (e) {
      showSnack('Error', 'Failed to save card: $e');
      return false;
    }
  }

  /// §5.3 DELETE /manual-payments/withdrawal-accounts/[id]
  Future<bool> deleteWithdrawalAccount(String id) async {
    isDeletingAccountId.value = id;
    try {
      final response =
          await dioDelete('manual-payments/withdrawal-accounts/$id');
      if (response.statusCode == 200) {
        withdrawalAccounts.removeWhere((c) => c.id == id);
        if (selectedAccountId.value == id) {
          selectedAccountId.value =
              withdrawalAccounts.isNotEmpty ? withdrawalAccounts.first.id : null;
        }
        showSnack('Deleted', 'Card removed');
        return true;
      } else if (response.statusCode == 404) {
        // §8 NOT_FOUND -> Refresh card list
        await fetchWithdrawalAccounts();
        return false;
      } else {
        final err = _extractErrorMessage(response.data);
        showSnack('Error', err ?? 'Failed to delete card');
        return false;
      }
    } catch (e) {
      showSnack('Error', 'Failed to delete card: $e');
      return false;
    } finally {
      isDeletingAccountId.value = null;
      pendingDeleteCardId.value = null;
    }
  }

  /// §3.1 Upload receipt via image picker or camera
  Future<void> pickAndUploadReceipt(ImageSource source) async {
    debugPrint('[ManualPayment] pickAndUploadReceipt called: source=$source');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      debugPrint('[ManualPayment] pickedFile: $pickedFile');
      if (pickedFile == null) return;

      // Update state immediately so thumbnail preview renders INSTANTLY!
      localReceiptPath.value = pickedFile.path;
      uploadedReceiptName.value = pickedFile.name;
      uploadedReceiptUrl.value = null;
      isUploadingReceipt.value = true;

      final formDataMap = <String, dynamic>{
        'kind': 'document',
        'file': await DIO.MultipartFile.fromFile(
          pickedFile.path,
          filename: pickedFile.name,
        ),
      };

      final response = await dioPost(
        endUrl: 'account/uploads',
        data: formDataMap,
        isJson: false,
        isFile: true,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map && rawData['url'] != null) {
          uploadedReceiptUrl.value = rawData['url'].toString();
          showSnack('Receipt Uploaded', 'Receipt attached successfully');
        } else {
          showSnack('Upload Failed', 'No receipt URL returned');
        }
      } else {
        final err = _extractErrorMessage(response.data);
        showSnack('Upload Failed', err ?? 'Could not upload receipt image');
      }
    } catch (e) {
      showSnack('Upload Error', 'Failed to upload receipt: $e');
    } finally {
      isUploadingReceipt.value = false;
    }
  }

  void clearUploadedReceipt() {
    localReceiptPath.value = null;
    uploadedReceiptUrl.value = null;
    uploadedReceiptName.value = null;
  }

  /// §3.2 POST /manual-payments/deposits
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

  /// §3.3 GET /manual-payments/deposits (cursor-paged)
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

  /// §6.1 POST /manual-payments/withdrawals
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
      final response = await dioPost(
        endUrl: 'manual-payments/withdrawals',
        data: payload,
        isJson: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnack(
          'Withdrawal Requested',
          'Request submitted and pending admin approval',
        );
        // Refresh Main balance immediately after 201 submit: amount held immediately
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

        // 409 INSUFFICIENT_BALANCE error mapping
        if (response.statusCode == 409 || errCode == 'INSUFFICIENT_BALANCE') {
          errCode = 'INSUFFICIENT_BALANCE';
          errMsg = errMsg.isNotEmpty && errMsg != 'Failed to submit withdrawal'
              ? errMsg
              : 'Insufficient balance in Main wallet for this withdrawal.';
          if (Get.isRegistered<WalletController>()) {
            Get.find<WalletController>().fetchWallets();
          }
        }

        // Keep PIN sheet open on WALLET_PIN_* errors (§8)
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

  /// §6.2 GET /manual-payments/withdrawals (cursor-paged)
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

          // When a withdrawal's status becomes rejected, refresh Main balance too — refund has landed
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
