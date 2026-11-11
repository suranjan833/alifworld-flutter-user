import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/functions/dio_function/my_dio.dart';

class WalletPinStatus {
  final bool isSet;
  final DateTime? lockedUntil;

  WalletPinStatus({required this.isSet, this.lockedUntil});

  bool get isLocked {
    if (lockedUntil == null) return false;
    return lockedUntil!.isAfter(DateTime.now());
  }

  factory WalletPinStatus.fromJson(Map<String, dynamic> json) {
    DateTime? lockTime;
    if (json['lockedUntil'] != null) {
      try {
        lockTime = DateTime.parse(json['lockedUntil'].toString());
      } catch (_) {}
    }
    return WalletPinStatus(
      isSet: json['set'] == true,
      lockedUntil: lockTime,
    );
  }
}

class WalletPinService extends GetxService {
  static WalletPinService get to => Get.find<WalletPinService>();

  final pinStatus = Rxn<WalletPinStatus>();
  final isLoading = false.obs;

  /// GET /api/v1/account/wallet-pin
  Future<WalletPinStatus?> checkStatus() async {
    try {
      isLoading.value = true;
      final response = await dioGet('account/wallet-pin');
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is Map<String, dynamic>) {
          final status = WalletPinStatus.fromJson(raw);
          pinStatus.value = status;
          return status;
        }
      }
    } catch (e) {
      debugPrint('Error checking wallet PIN status: $e');
    } finally {
      isLoading.value = false;
    }
    return pinStatus.value;
  }

  /// POST /api/v1/account/wallet-pin - Set new PIN or change existing PIN
  Future<Map<String, dynamic>> setOrChangePin({
    required String pin,
    String? currentPin,
  }) async {
    try {
      isLoading.value = true;
      final payload = <String, dynamic>{
        'pin': pin.trim(),
        if (currentPin != null && currentPin.trim().isNotEmpty)
          'currentPin': currentPin.trim(),
      };

      final response = await dioPost(
        endUrl: 'account/wallet-pin',
        data: payload,
        isJson: true,
      );

      final statusCode = response.statusCode ?? 500;
      final raw = response.data is Map ? response.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode >= 200 && statusCode < 300) {
        await checkStatus();
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'code': error?['code'] ?? 'HTTP_$statusCode',
          'message': error?['message'] ?? raw['message'] ?? 'Failed to update PIN',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /api/v1/account/wallet-pin/reset-request
  Future<Map<String, dynamic>> requestReset() async {
    try {
      isLoading.value = true;
      final response = await dioPost(
        endUrl: 'account/wallet-pin/reset-request',
        isJson: true,
      );

      final statusCode = response.statusCode ?? 500;
      final raw = response.data is Map ? response.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode >= 200 && statusCode < 300) {
        return {
          'success': true,
          'mobileSent': data['mobileSent'] == true,
          'emailSent': data['emailSent'] == true,
        };
      } else {
        return {
          'success': false,
          'code': error?['code'] ?? 'HTTP_$statusCode',
          'message': error?['message'] ?? raw['message'] ?? 'Failed to send reset code',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /api/v1/account/wallet-pin/reset-confirm
  Future<Map<String, dynamic>> confirmReset({
    String? mobileCode,
    String? emailCode,
    required String newPin,
  }) async {
    try {
      isLoading.value = true;
      final payload = <String, dynamic>{
        'newPin': newPin.trim(),
        if (mobileCode != null && mobileCode.trim().isNotEmpty)
          'mobileCode': mobileCode.trim(),
        if (emailCode != null && emailCode.trim().isNotEmpty)
          'emailCode': emailCode.trim(),
      };

      final response = await dioPost(
        endUrl: 'account/wallet-pin/reset-confirm',
        data: payload,
        isJson: true,
      );

      final statusCode = response.statusCode ?? 500;
      final raw = response.data is Map ? response.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (statusCode >= 200 && statusCode < 300) {
        await checkStatus();
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'code': error?['code'] ?? 'HTTP_$statusCode',
          'message': error?['message'] ?? raw['message'] ?? 'Reset confirmation failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    } finally {
      isLoading.value = false;
    }
  }
}
