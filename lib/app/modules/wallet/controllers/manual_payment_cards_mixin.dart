// ignore_for_file: library_prefixes

import 'package:dio/dio.dart' as DIO;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/config/functions/dio_function/app_config.dart';
import '../../../data/config/functions/dio_function/my_dio.dart';
import '../../../data/models/manual_payment_model.dart';

mixin ManualPaymentCardsMixin on GetxController {
  final withdrawalAccounts = <WithdrawalAccountModel>[].obs;
  final isLoadingAccounts = false.obs;
  final selectedAccountId = RxnString();
  final isDeletingAccountId = RxnString();
  final pendingDeleteCardId = RxnString();

  final isUploadingReceipt = false.obs;
  final localReceiptPath = RxnString();
  final uploadedReceiptUrl = RxnString();
  final uploadedReceiptName = RxnString();

  final ImagePicker _picker = ImagePicker();

  String? extractError(dynamic data) {
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
              .map((e) => WithdrawalAccountModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          withdrawalAccounts.assignAll(list);

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
          selectedAccountId.value = newCard.id;
          showSnack('Success', 'Bank card added successfully');
          return true;
        }
        await fetchWithdrawalAccounts();
        return true;
      } else {
        final err = extractError(response.data);
        showSnack('Error', err ?? 'Failed to add card');
        return false;
      }
    } catch (e) {
      showSnack('Error', 'Failed to save card: $e');
      return false;
    }
  }

  Future<bool> deleteWithdrawalAccount(String id) async {
    isDeletingAccountId.value = id;
    try {
      final response = await dioDelete('manual-payments/withdrawal-accounts/$id');
      if (response.statusCode == 200) {
        withdrawalAccounts.removeWhere((c) => c.id == id);
        if (selectedAccountId.value == id) {
          selectedAccountId.value =
              withdrawalAccounts.isNotEmpty ? withdrawalAccounts.first.id : null;
        }
        showSnack('Deleted', 'Card removed');
        return true;
      } else if (response.statusCode == 404) {
        await fetchWithdrawalAccounts();
        return false;
      } else {
        final err = extractError(response.data);
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

  Future<void> pickAndUploadReceipt(ImageSource source) async {
    debugPrint('[ManualPayment] pickAndUploadReceipt called: source=$source');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (pickedFile == null) return;

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
        final err = extractError(response.data);
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
}
