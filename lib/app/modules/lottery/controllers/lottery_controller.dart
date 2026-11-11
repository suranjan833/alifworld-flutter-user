import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/redeem_model.dart';
import '../../../data/widgets/wallet_pin_dialog.dart';
import '../../../routes/app_pages.dart';
import '../models/lottery_model.dart';

class LotteryController extends GetxController {
  final activeStatusFilter = 'all'.obs; // 'all', 'active', 'drawn'
  final isLoading = false.obs;
  final activeLotteries = <LotteryItemModel>[].obs;
  final pastLotteries = <LotteryItemModel>[].obs;
  final lotteries = <LotteryItemModel>[].obs;

  // Detail
  final isDetailLoading = false.obs;
  final activeLotteryDetail = Rxn<LotteryDetailResponseModel>();
  final buyQty = 1.obs;
  final isBuying = false.obs;

  // Results
  final isResultsLoading = false.obs;
  final lotteryResults = Rxn<LotteryResultsResponseModel>();

  // My Tickets
  final isMyTicketsLoading = false.obs;
  final isLoadingMoreTickets = false.obs;
  final myTickets = <MyLotteryTicketItemModel>[].obs;
  final myTicketsCursor = RxnString();

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
    fetchLotteries();
  }

  void setStatusFilter(String status) {
    if (activeStatusFilter.value == status) return;
    activeStatusFilter.value = status;
    if (status == 'active') {
      lotteries.assignAll(activeLotteries);
    } else if (status == 'drawn') {
      lotteries.assignAll(pastLotteries);
    } else {
      lotteries.assignAll([...activeLotteries, ...pastLotteries]);
    }
  }

  /// 1. GET /api/v1/lotteries?status=active|drawn&audience=customer
  Future<void> fetchLotteries() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        dioGet('lotteries?status=active&audience=customer'),
        dioGet('lotteries?status=drawn&audience=customer'),
      ]);

      // 1. Active draws
      final activeRes = results[0];
      if (activeRes.statusCode == 200 && activeRes.data != null) {
        dynamic raw = activeRes.data;
        if (raw is Map && raw.containsKey('data')) raw = raw['data'];
        if (raw is Map && raw.containsKey('items')) {
          final list = (raw['items'] as List<dynamic>?)
                  ?.map((e) => LotteryItemModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          activeLotteries.assignAll(list);
        }
      }

      // 2. Past draws (ordered newest draw first: drawnAt descending)
      final pastRes = results[1];
      if (pastRes.statusCode == 200 && pastRes.data != null) {
        dynamic raw = pastRes.data;
        if (raw is Map && raw.containsKey('data')) raw = raw['data'];
        if (raw is Map && raw.containsKey('items')) {
          final list = (raw['items'] as List<dynamic>?)
                  ?.map((e) => LotteryItemModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          list.sort((a, b) {
            final aDate = a.drawnAt ?? a.resultAt ?? DateTime(0);
            final bDate = b.drawnAt ?? b.resultAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          pastLotteries.assignAll(list);
        }
      }

      if (activeStatusFilter.value == 'active') {
        lotteries.assignAll(activeLotteries);
      } else if (activeStatusFilter.value == 'drawn') {
        lotteries.assignAll(pastLotteries);
      } else {
        lotteries.assignAll([...activeLotteries, ...pastLotteries]);
      }
    } catch (e) {
      debugPrint('Error fetching lotteries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. GET /api/v1/lotteries/[id]
  Future<void> fetchLotteryDetail(String id) async {
    if (id.isEmpty) return;
    isDetailLoading.value = true;
    buyQty.value = 1;
    try {
      final res = await dioGet('lotteries/$id');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          activeLotteryDetail.value = LotteryDetailResponseModel.fromJson(raw);
        }
      }
    } catch (e) {
      debugPrint('Error fetching lottery detail: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  int get buyTotalMinor {
    final price = activeLotteryDetail.value?.lottery.ticketPriceMinor ?? 0;
    return price * buyQty.value;
  }

  double get buyTotalAmount => buyTotalMinor / 100.0;

  bool get hasSufficientGoodLuck {
    final bal = activeLotteryDetail.value?.goodLuckBalanceMinor ?? 0;
    return bal >= buyTotalMinor;
  }

  void incrementQty() {
    if (buyQty.value < 100) {
      buyQty.value++;
    }
  }

  void decrementQty() {
    if (buyQty.value > 1) {
      buyQty.value--;
    }
  }

  /// 3. POST /api/v1/lotteries/[id]/tickets
  Future<bool> buyTickets({
    required BuildContext context,
    required String lotteryId,
  }) async {
    if (!hasAuth) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    final detail = activeLotteryDetail.value;
    if (detail != null && detail.lottery.isSeller) {
      showSnack(
        'Seller Lottery',
        'This lottery is for sellers. Customer accounts cannot purchase tickets for it.',
        bg: AppColor.red,
      );
      return false;
    }

    if (!hasSufficientGoodLuck) {
      showSnack(
        'Insufficient Good-Luck Balance',
        'Lottery tickets can only be purchased with Good-Luck wallet balance.',
        bg: AppColor.red,
      );
      return false;
    }

    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Confirm Ticket Purchase',
      subtitle: 'Enter your 6-digit wallet PIN to purchase ${buyQty.value} ticket(s)',
    );

    if (pin == null || pin.isEmpty) return false;

    isBuying.value = true;
    final idempotencyKey = generateUuidV4();

    try {
      final res = await dioPost(
        endUrl: 'lotteries/$lotteryId/tickets',
        data: {
          'qty': buyQty.value,
          'walletPin': pin,
        },
        isJson: true,
        customHeaders: {'Idempotency-Key': idempotencyKey},
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final error = raw['error'] is Map ? raw['error'] : null;

      isBuying.value = false;

      if (statusCode == 200 || statusCode == 201) {
        showSnack(
          'Tickets Purchased!',
          'Successfully bought ${buyQty.value} ticket(s)!',
          bg: AppColor.green,
        );
        await fetchLotteryDetail(lotteryId);
        return true;
      } else {
        final code = error?['code']?.toString() ?? '';
        String msg = error?['message']?.toString() ??
            raw['message']?.toString() ??
            'Purchase failed';

        if (code == 'WRONG_ACCOUNT_TYPE') {
          msg = 'This lottery is not available for your account type.';
        } else if (code == 'SELLER_NOT_FOUND') {
          msg = 'This lottery requires an approved seller account.';
        }

        showSnack('Purchase Failed', msg, bg: AppColor.red);
        return false;
      }
    } catch (e) {
      isBuying.value = false;
      showSnack('Error', 'Failed to purchase ticket: $e', bg: AppColor.red);
      return false;
    }
  }

  /// 4. GET /api/v1/lotteries/[id]/results
  Future<void> fetchLotteryResults(String id) async {
    if (id.isEmpty) return;
    isResultsLoading.value = true;
    try {
      final res = await dioGet('lotteries/$id/results');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          lotteryResults.value = LotteryResultsResponseModel.fromJson(raw);
        }
      }
    } catch (e) {
      debugPrint('Error fetching lottery results: $e');
    } finally {
      isResultsLoading.value = false;
    }
  }

  /// 5. GET /api/v1/lotteries/my-tickets
  Future<void> fetchMyTickets({bool refresh = true, String? lotteryId}) async {
    if (!hasAuth) {
      if (refresh) myTickets.clear();
      return;
    }

    if (refresh) {
      isMyTicketsLoading.value = true;
      myTicketsCursor.value = null;
    } else {
      if (myTicketsCursor.value == null || isLoadingMoreTickets.value) return;
      isLoadingMoreTickets.value = true;
    }

    try {
      String query = 'limit=20';
      if (lotteryId != null && lotteryId.isNotEmpty) {
        query += '&lotteryId=$lotteryId';
      }
      if (!refresh && myTicketsCursor.value != null) {
        query += '&cursor=${myTicketsCursor.value}';
      }

      final res = await dioGet('lotteries/my-tickets?$query');
      if (res.statusCode == 200 && res.data != null) {
        dynamic raw = res.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          final parsed = MyLotteryTicketsResponseModel.fromJson(raw);
          if (refresh) {
            myTickets.assignAll(parsed.items);
          } else {
            myTickets.addAll(parsed.items);
          }
          myTicketsCursor.value = parsed.nextCursor;
        }
      }
    } catch (e) {
      debugPrint('Error fetching my tickets: $e');
    } finally {
      if (refresh) {
        isMyTicketsLoading.value = false;
      } else {
        isLoadingMoreTickets.value = false;
      }
    }
  }
}
