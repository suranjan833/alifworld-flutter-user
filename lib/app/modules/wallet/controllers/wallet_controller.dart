import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/wallet_model.dart';
import '../../../routes/app_pages.dart';

class WalletController extends GetxController {
  final isLoading = false.obs;
  final isTransactionsLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSubmittingAction = false.obs;
  final isSingleWalletLoading = false.obs;
  final activeSingleWallet = Rxn<WalletItemModel>();
  final activeSingleTransactions = <WalletTransactionModel>[].obs;

  final wallets = <WalletItemModel>[].obs;
  final currencySymbol = '৳'.obs;
  final currency = 'BDT'.obs;
  final mainBalance = 0.0.obs;
  final totalBalance = 0.0.obs;

  // Selected wallet filter for transactions (empty = All)
  final selectedWalletKind = ''.obs;

  final transactions = <WalletTransactionModel>[].obs;
  final nextCursor = RxnString();

  bool get hasAuth {
    final token = getBox.read(USER_TOKEN);
    final sessionCookie = getBox.read('SESSION_COOKIE');
    final isLoggedIn = getBox.read(IS_USER_LOGGED_IN);
    return (token != null && token.toString().trim().isNotEmpty) ||
        (sessionCookie != null && sessionCookie.toString().trim().isNotEmpty) ||
        (isLoggedIn == true || isLoggedIn == 'true');
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchWallets(),
        fetchTransactions(refresh: true),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  /// 1. GET /api/v1/wallets - Fetch all customer wallets & balances
  Future<void> fetchWallets() async {
    if (!hasAuth) {
      _loadFallbackWallets();
      return;
    }

    try {
      final response = await dioGet('wallets');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        if (rawData is Map<String, dynamic>) {
          final resModel = WalletResponseModel.fromJson(rawData);
          wallets.assignAll(resModel.items);
          currencySymbol.value = resModel.currencySymbol;
          currency.value = resModel.currency;
          mainBalance.value = resModel.mainBalance;
          totalBalance.value = resModel.totalBalance;
        }
      } else {
        _loadFallbackWallets();
      }
    } catch (e) {
      debugPrint('Error fetching wallets: $e');
      _loadFallbackWallets();
    }
  }

  /// 2. GET /api/v1/wallets/transactions?limit=20 - Fetch wallet transactions
  Future<void> fetchTransactions({
    bool refresh = true,
    String? walletKind,
  }) async {
    final activeKind = walletKind ?? selectedWalletKind.value;

    if (!hasAuth) {
      if (refresh) transactions.clear();
      return;
    }

    if (refresh) {
      isTransactionsLoading.value = true;
      nextCursor.value = null;
    } else {
      if (nextCursor.value == null || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      String query = 'limit=20';
      if (activeKind.isNotEmpty) {
        query += '&walletKind=$activeKind';
      }
      if (!refresh && nextCursor.value != null) {
        query += '&cursor=${nextCursor.value}';
      }

      final response = await dioGet('wallets/transactions?$query');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        if (rawData is Map<String, dynamic>) {
          final txRes = WalletTransactionsResponseModel.fromJson(rawData);
          if (refresh) {
            transactions.assignAll(txRes.items);
          } else {
            transactions.addAll(txRes.items);
          }
          nextCursor.value = txRes.nextCursor;
          if (txRes.currencySymbol.isNotEmpty) {
            currencySymbol.value = txRes.currencySymbol;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      if (refresh) {
        isTransactionsLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  void selectWalletFilter(String kind) {
    if (selectedWalletKind.value == kind) {
      selectedWalletKind.value = '';
    } else {
      selectedWalletKind.value = kind;
    }
    fetchTransactions(refresh: true);
  }

  /// 3. GET /api/v1/wallets/{kind} - Fetch single wallet details & its specific transactions
  Future<void> fetchSingleWallet(String kind) async {
    if (!hasAuth || kind.isEmpty) return;

    isSingleWalletLoading.value = true;
    try {
      final response = await dioGet('wallets/$kind?limit=20');
      if (response.statusCode == 200 && response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        if (rawData is Map<String, dynamic>) {
          if (rawData['wallet'] is Map<String, dynamic>) {
            activeSingleWallet.value = WalletItemModel.fromJson(
              Map<String, dynamic>.from(rawData['wallet']),
            );
          }

          if (rawData['transactions'] is Map<String, dynamic>) {
            final txObj = rawData['transactions'] as Map<String, dynamic>;
            final txList = (txObj['items'] as List<dynamic>?)
                    ?.map((e) => WalletTransactionModel.fromJson(Map<String, dynamic>.from(e)))
                    .toList() ??
                [];
            activeSingleTransactions.assignAll(txList);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching single wallet ($kind): $e');
    } finally {
      isSingleWalletLoading.value = false;
    }
  }

  /// POST /api/v1/advanced-shopping/deposit
  Future<bool> depositAdvanceShopping(double amount) async {
    if (amount <= 0) {
      showSnack('Invalid Amount', 'Please enter a valid deposit amount', bg: Colors.red);
      return false;
    }

    final amountMinor = (amount * 100).round();
    final idempotencyKey = 'DEP_${DateTime.now().millisecondsSinceEpoch}';

    isSubmittingAction.value = true;
    try {
      final res = await dioPost(
        endUrl: 'advanced-shopping/deposit',
        data: {'amountMinor': amountMinor},
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      isSubmittingAction.value = false;
      if (res.statusCode == 200 || res.statusCode == 201) {
        showSnack(
          'Deposit Successful',
          '${currencySymbol.value}${amount.toStringAsFixed(2)} added to Advance Shopping wallet',
          bg: Colors.green,
        );
        await refreshAll();
        return true;
      } else {
        String msg = 'Deposit failed. Please try again.';
        if (res.data is Map && res.data['message'] != null) {
          msg = res.data['message'].toString();
        } else if (res.data is Map && res.data['error'] is Map && res.data['error']['message'] != null) {
          msg = res.data['error']['message'].toString();
        }
        showSnack('Deposit Failed', msg, bg: Colors.red);
        return false;
      }
    } catch (e) {
      isSubmittingAction.value = false;
      showSnack('Deposit Error', 'Something went wrong. Please try again.', bg: Colors.red);
      return false;
    }
  }

  /// POST /api/v1/advanced-shopping/withdraw
  Future<bool> withdrawAdvanceShopping(double amount) async {
    if (amount <= 0) {
      showSnack('Invalid Amount', 'Please enter a valid withdrawal amount', bg: Colors.red);
      return false;
    }

    final advWallet = wallets.firstWhereOrNull((w) => w.kind == 'customer_advanced_shopping');
    if (advWallet != null && amount > advWallet.balance) {
      showSnack(
        'Insufficient Balance',
        'Available Advance Shopping balance is ${currencySymbol.value}${advWallet.balance.toStringAsFixed(2)}',
        bg: Colors.red,
      );
      return false;
    }

    final amountMinor = (amount * 100).round();

    isSubmittingAction.value = true;
    try {
      final res = await dioPost(
        endUrl: 'advanced-shopping/withdraw',
        data: {'amountMinor': amountMinor},
        isJson: true,
      );

      isSubmittingAction.value = false;
      if (res.statusCode == 200 || res.statusCode == 201) {
        showSnack(
          'Withdrawal Successful',
          '${currencySymbol.value}${amount.toStringAsFixed(2)} withdrawn from Advance Shopping wallet',
          bg: Colors.green,
        );
        await refreshAll();
        return true;
      } else {
        String msg = 'Withdrawal failed. Please try again.';
        if (res.data is Map && res.data['message'] != null) {
          msg = res.data['message'].toString();
        } else if (res.data is Map && res.data['error'] is Map && res.data['error']['message'] != null) {
          msg = res.data['error']['message'].toString();
        }
        showSnack('Withdrawal Failed', msg, bg: Colors.red);
        return false;
      }
    } catch (e) {
      isSubmittingAction.value = false;
      showSnack('Withdrawal Error', 'Something went wrong. Please try again.', bg: Colors.red);
      return false;
    }
  }

  void _loadFallbackWallets() {
    wallets.assignAll([
      WalletItemModel(kind: 'customer_main', balanceMinor: 0),
      WalletItemModel(kind: 'customer_shopping', balanceMinor: 0),
      WalletItemModel(kind: 'customer_advanced_shopping', balanceMinor: 0),
      WalletItemModel(kind: 'customer_cashback', balanceMinor: 0),
      WalletItemModel(kind: 'customer_referral', balanceMinor: 0),
      WalletItemModel(kind: 'customer_club_bonus', balanceMinor: 0),
      WalletItemModel(kind: 'customer_star_bonus', balanceMinor: 0),
      WalletItemModel(kind: 'customer_advanced_return', balanceMinor: 0),
      WalletItemModel(kind: 'customer_good_luck', balanceMinor: 0),
      WalletItemModel(kind: 'customer_charity', balanceMinor: 0),
    ]);
    mainBalance.value = 0.0;
    totalBalance.value = 0.0;
  }

  void navigateToLogin() {
    Get.toNamed(Routes.LOGIN);
  }
}
