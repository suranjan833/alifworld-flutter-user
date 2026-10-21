import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/wallet_model.dart';
import '../../../routes/app_pages.dart';

class MyTransactionsController extends GetxController {
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  final transactions = <WalletTransactionModel>[].obs;
  final nextCursor = RxnString();
  final selectedWalletKind = ''.obs;
  final currencySymbol = '৳'.obs;

  final filterOptions = const [
    {'label': 'All', 'kind': ''},
    {'label': 'Main Wallet', 'kind': 'customer_main'},
    {'label': 'Shopping', 'kind': 'customer_shopping'},
    {'label': 'Advance Shopping', 'kind': 'customer_advanced_shopping'},
    {'label': 'Cashback', 'kind': 'customer_cashback'},
    {'label': 'Referral', 'kind': 'customer_referral'},
    {'label': 'Club Bonus', 'kind': 'customer_club_bonus'},
    {'label': 'Star Bonus', 'kind': 'customer_star_bonus'},
    {'label': 'Advance Return', 'kind': 'customer_advanced_return'},
    {'label': 'Good Luck', 'kind': 'customer_good_luck'},
    {'label': 'Charity', 'kind': 'customer_charity'},
  ];

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
    fetchTransactions(refresh: true);
  }

  /// GET /api/v1/wallets/transactions?limit=20&walletKind=...
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
      isLoading.value = true;
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
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  void selectFilter(String kind) {
    if (selectedWalletKind.value == kind) return;
    selectedWalletKind.value = kind;
    fetchTransactions(refresh: true);
  }

  void navigateToLogin() {
    Get.toNamed(Routes.LOGIN);
  }
}
