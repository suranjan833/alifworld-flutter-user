import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../models/address_model.dart';
import 'address_geo_mixin.dart';

class AddressFormController extends GetxController with AddressGeoMixin {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressLineController = TextEditingController();
  final postalCodeController = TextEditingController();
  final searchController = TextEditingController();

  final selectedLabel = 'Home'.obs;
  final isDefault = false.obs;
  final isSaving = false.obs;

  AddressModel? editingAddress;
  ValueChanged<AddressModel>? onSavedCallback;

  @override
  AddressModel? get currentEditingAddress => editingAddress;

  static String normalizeBdPhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('88')) {
      digits = digits.substring(2);
      if (digits.isNotEmpty && !digits.startsWith('0')) {
        digits = '0$digits';
      }
    } else if (digits.length == 10 && digits.startsWith('1')) {
      digits = '0$digits';
    }
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    return digits;
  }

  static bool isValidBdPhone(String input) {
    final normalized = normalizeBdPhone(input);
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(normalized);
  }

  void init({
    AddressModel? address,
    required ValueChanged<AddressModel> onSaved,
  }) {
    editingAddress = address;
    onSavedCallback = onSaved;

    final defaultName = getBox.read(USER_NAME)?.toString() ?? '';
    final defaultPhone = getBox.read(USER_PHONE)?.toString() ?? '';

    final rawPhone = address != null ? address.phone : defaultPhone;
    final initialPhone = normalizeBdPhone(rawPhone);

    nameController.text = address != null ? address.fullName : defaultName;
    phoneController.text = initialPhone;
    addressLineController.text = address != null ? address.addressLine : '';
    postalCodeController.text = address != null ? address.postalCode : '';
    searchController.clear();

    selectedLabel.value = address != null ? address.label : 'Home';
    isDefault.value = address != null ? address.isDefault : false;

    loadDivisions();
  }

  void handleSearchResult(GeoSearchResult hit) {
    applySearchResult(
      hit,
      onClearQuery: (_) => searchController.clear(),
    );
  }

  Future<void> saveAddress(BuildContext context) async {
    final name = nameController.text.trim();
    final rawPhone = phoneController.text.trim();
    final addressLine = addressLineController.text.trim();
    final postalCode = postalCodeController.text.trim();

    if (name.isEmpty) {
      showSnack('Missing Name', 'Please enter your full name', bg: AppColor.red);
      return;
    }

    if (!isValidBdPhone(rawPhone)) {
      showSnack(
        'Invalid Phone',
        'Please enter a valid 11-digit BD mobile number (01XXXXXXXXX)',
        bg: AppColor.red,
      );
      return;
    }

    if (addressLine.isEmpty) {
      showSnack('Missing Address', 'Please enter your full house/street address', bg: AppColor.red);
      return;
    }

    if (selectedDivision.value == null) {
      showSnack('Missing Division', 'Please select your division', bg: AppColor.red);
      return;
    }

    if (selectedDistrict.value == null) {
      showSnack('Missing District', 'Please select your district', bg: AppColor.red);
      return;
    }

    if (selectedUpazila.value == null) {
      showSnack('Missing Upazila', 'Please select your upazila', bg: AppColor.red);
      return;
    }

    if (unions.isNotEmpty && selectedUnion.value == null) {
      showSnack('Missing Union', 'Please select your union', bg: AppColor.red);
      return;
    }

    if (selectedArea.value == null) {
      showSnack('Missing Area', 'Please select your area', bg: AppColor.red);
      return;
    }

    isSaving.value = true;

    final normalizedPhone = normalizeBdPhone(rawPhone);
    final isEditing = editingAddress != null;
    final isVirtualArea = selectedArea.value?.isVirtual == true;
    final areaName = (areas.isNotEmpty && !isVirtualArea)
        ? (selectedArea.value?.name ?? '')
        : '';

    final payload = <String, dynamic>{
      'label': selectedLabel.value,
      'fullName': name,
      'phone': normalizedPhone,
      'addressLine': addressLine,
      'division': selectedDivision.value!.name,
      if (selectedDivision.value!.bnName.isNotEmpty)
        'divisionBn': selectedDivision.value!.bnName,
      'district': selectedDistrict.value!.name,
      if (selectedDistrict.value!.bnName.isNotEmpty)
        'districtBn': selectedDistrict.value!.bnName,
      'upazila': selectedUpazila.value!.name,
      if (selectedUpazila.value!.bnName.isNotEmpty)
        'upazilaBn': selectedUpazila.value!.bnName,
      'union': selectedUnion.value != null ? selectedUnion.value!.name : '',
      if (selectedUnion.value != null && selectedUnion.value!.bnName.isNotEmpty)
        'unionBn': selectedUnion.value!.bnName,
      'area': areaName,
      if (selectedArea.value != null &&
          selectedArea.value!.bnName.isNotEmpty &&
          !isVirtualArea)
        'areaBn': selectedArea.value!.bnName,
      'postalCode': postalCode,
      'isDefault': isDefault.value,
    };

    try {
      dynamic response;
      if (isEditing) {
        response = await dioPatch(
          endUrl: 'addresses/${editingAddress!.id}',
          data: payload,
          isJson: true,
        );
      } else {
        response = await dioPost(
          endUrl: 'addresses',
          data: payload,
          isJson: true,
        );
      }

      isSaving.value = false;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final resData = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        final savedJson = (resData is Map && resData['address'] is Map)
            ? (resData['address'] as Map<String, dynamic>)
            : (resData is Map<String, dynamic> ? resData : payload);

        final saved = AddressModel.fromJson(Map<String, dynamic>.from(savedJson));

        showSnack(
          isEditing ? 'Address Updated' : 'Address Added',
          isEditing
              ? 'Your delivery address has been updated.'
              : 'New delivery address added successfully.',
          bg: AppColor.teal,
        );

        if (context.mounted) {
          Navigator.of(context).pop();
        }
        onSavedCallback?.call(saved);
      } else {
        String msg = 'Could not save address. Please check your inputs.';
        if (response.data is Map &&
            response.data['error'] is Map &&
            response.data['error']['message'] != null) {
          msg = response.data['error']['message'].toString();
        } else if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        }
        showSnack('Address Error', msg, bg: AppColor.red);
      }
    } catch (e) {
      isSaving.value = false;
      showSnack('Submission Failed', 'Unable to reach server. Please try again.', bg: AppColor.red);
    }
  }

  @override
  void onClose() {
    disposeGeo();
    nameController.dispose();
    phoneController.dispose();
    addressLineController.dispose();
    postalCodeController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
