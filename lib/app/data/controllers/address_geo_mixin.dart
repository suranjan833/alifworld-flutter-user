import 'dart:async';
import 'package:get/get.dart';

import '../config/functions/dio_function/my_dio.dart';
import '../models/address_model.dart';

mixin AddressGeoMixin on GetxController {
  final divisions = <GeoDivision>[].obs;
  final districts = <GeoDistrict>[].obs;
  final upazilas = <GeoUpazila>[].obs;
  final unions = <GeoUnion>[].obs;
  final areas = <GeoArea>[].obs;

  final selectedDivision = Rxn<GeoDivision>();
  final selectedDistrict = Rxn<GeoDistrict>();
  final selectedUpazila = Rxn<GeoUpazila>();
  final selectedUnion = Rxn<GeoUnion>();
  final selectedArea = Rxn<GeoArea>();

  final isLoadingDivisions = false.obs;
  final isLoadingDistricts = false.obs;
  final isLoadingUpazilas = false.obs;
  final isLoadingUnions = false.obs;
  final isLoadingAreas = false.obs;

  final searchResults = <GeoSearchResult>[].obs;
  final isSearching = false.obs;
  Timer? searchDebounce;

  AddressModel? get currentEditingAddress;

  Future<void> loadDivisions() async {
    isLoadingDivisions.value = true;
    try {
      final res = await dioGet('geo/divisions');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final rawList = (data is Map && data['divisions'] is List)
            ? (data['divisions'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoDivision.fromJson(j))
            .toList();

        divisions.assignAll(list);

        final editAddr = currentEditingAddress;
        if (editAddr != null && editAddr.division.isNotEmpty) {
          final target = editAddr.division.toLowerCase().trim();
          final targetBn = editAddr.divisionBn.toLowerCase().trim();
          final match = divisions.firstWhereOrNull(
            (d) =>
                d.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty && d.bnName.toLowerCase().trim() == targetBn),
          );
          if (match != null) {
            onSelectDivision(match, prefill: true);
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingDivisions.value = false;
    }
  }

  Future<void> loadDistricts(String divisionId, {bool prefill = false}) async {
    isLoadingDistricts.value = true;
    districts.clear();
    selectedDistrict.value = null;
    upazilas.clear();
    selectedUpazila.value = null;
    unions.clear();
    selectedUnion.value = null;
    areas.clear();
    selectedArea.value = null;

    try {
      final res = await dioGet('geo/districts?divisionId=$divisionId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final rawList = (data is Map && data['districts'] is List)
            ? (data['districts'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoDistrict.fromJson(j))
            .toList();

        districts.assignAll(list);

        final editAddr = currentEditingAddress;
        if (prefill && editAddr != null) {
          final target = editAddr.district.toLowerCase().trim();
          final targetBn = editAddr.districtBn.toLowerCase().trim();
          final match = districts.firstWhereOrNull(
            (d) =>
                d.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty && d.bnName.toLowerCase().trim() == targetBn),
          );
          if (match != null) {
            onSelectDistrict(match, prefill: true);
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  Future<void> loadUpazilas(String districtId, {bool prefill = false}) async {
    isLoadingUpazilas.value = true;
    upazilas.clear();
    selectedUpazila.value = null;
    unions.clear();
    selectedUnion.value = null;
    areas.clear();
    selectedArea.value = null;

    try {
      final res = await dioGet('geo/upazilas?districtId=$districtId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final rawList = (data is Map && data['upazilas'] is List)
            ? (data['upazilas'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoUpazila.fromJson(j))
            .toList();

        upazilas.assignAll(list);

        final editAddr = currentEditingAddress;
        if (prefill && editAddr != null) {
          final target = editAddr.upazila.toLowerCase().trim();
          final targetBn = editAddr.upazilaBn.toLowerCase().trim();
          final match = upazilas.firstWhereOrNull(
            (u) =>
                u.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty && u.bnName.toLowerCase().trim() == targetBn),
          );
          if (match != null) {
            onSelectUpazila(match, prefill: true);
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingUpazilas.value = false;
    }
  }

  Future<void> loadUnions(String upazilaId, {bool prefill = false}) async {
    isLoadingUnions.value = true;
    unions.clear();
    selectedUnion.value = null;
    areas.clear();
    selectedArea.value = null;

    try {
      final res = await dioGet('geo/unions?upazilaId=$upazilaId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final rawList = (data is Map && data['unions'] is List)
            ? (data['unions'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoUnion.fromJson(j))
            .toList();

        unions.assignAll(list);

        final editAddr = currentEditingAddress;
        if (prefill && editAddr != null) {
          final target = editAddr.union.toLowerCase().trim();
          final targetBn = editAddr.unionBn.toLowerCase().trim();
          final match = unions.firstWhereOrNull(
            (u) =>
                u.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty && u.bnName.toLowerCase().trim() == targetBn),
          );
          if (match != null) {
            onSelectUnion(match, prefill: true);
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingUnions.value = false;
    }
  }

  Future<void> loadAreas(String unionId, {bool prefill = false}) async {
    isLoadingAreas.value = true;
    areas.clear();
    selectedArea.value = null;

    try {
      final res = await dioGet('geo/areas?unionId=$unionId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final rawList = (data is Map && data['areas'] is List)
            ? (data['areas'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoArea.fromJson(j))
            .toList();

        GeoArea? fallbackArea;
        if (list.isEmpty && selectedUnion.value != null) {
          final unionName = selectedUnion.value!.name;
          final unionBn = selectedUnion.value!.bnName;
          fallbackArea = GeoArea(
            id: '',
            name: '$unionName Area',
            bnName: unionBn.isNotEmpty ? '$unionBn এলাকা' : '',
            isVirtual: true,
          );
        }

        areas.assignAll(list);
        if (fallbackArea != null) {
          selectedArea.value = fallbackArea;
        }

        final editAddr = currentEditingAddress;
        if (prefill && editAddr != null) {
          final target = editAddr.area.toLowerCase().trim();
          final targetBn = editAddr.areaBn.toLowerCase().trim();
          final match = areas.firstWhereOrNull(
            (a) =>
                a.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty && a.bnName.toLowerCase().trim() == targetBn),
          );
          if (match != null) {
            selectedArea.value = match;
          }
        }
      }
    } catch (_) {
    } finally {
      isLoadingAreas.value = false;
    }
  }

  void onSelectDivision(GeoDivision div, {bool prefill = false}) {
    selectedDivision.value = div;
    loadDistricts(div.id, prefill: prefill);
  }

  void onSelectDistrict(GeoDistrict dist, {bool prefill = false}) {
    selectedDistrict.value = dist;
    loadUpazilas(dist.id, prefill: prefill);
  }

  void onSelectUpazila(GeoUpazila upz, {bool prefill = false}) {
    selectedUpazila.value = upz;
    loadUnions(upz.id, prefill: prefill);
  }

  void onSelectUnion(GeoUnion un, {bool prefill = false}) {
    selectedUnion.value = un;
    loadAreas(un.id, prefill: prefill);
  }

  void onSearchChanged(String query) {
    searchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      isSearching.value = true;
      try {
        final res = await dioGet('geo/search?q=${Uri.encodeComponent(q)}');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final rawList = (data is Map && data['results'] is List)
              ? (data['results'] as List)
              : <dynamic>[];
          final list = rawList
              .whereType<Map<String, dynamic>>()
              .map((j) => GeoSearchResult.fromJson(j))
              .toList();
          searchResults.assignAll(list);
        }
      } catch (_) {
      } finally {
        isSearching.value = false;
      }
    });
  }

  Future<void> applySearchResult(
    GeoSearchResult hit, {
    required Function(String) onClearQuery,
  }) async {
    final div = hit.division;
    final dist = hit.district;
    final upz = hit.upazila;
    final un = hit.union;
    final ar = hit.area;

    searchResults.clear();
    onClearQuery('');
    selectedDivision.value = div;
    selectedDistrict.value = dist;
    selectedUpazila.value = upz;
    selectedUnion.value = un;
    selectedArea.value = ar;

    if (div != null) {
      await loadDistricts(div.id);
      if (dist != null) {
        selectedDistrict.value = dist;
        await loadUpazilas(dist.id);
        if (upz != null) {
          selectedUpazila.value = upz;
          await loadUnions(upz.id);
          if (un != null) {
            selectedUnion.value = un;
            await loadAreas(un.id);
            if (ar != null) {
              selectedArea.value = ar;
            }
          }
        }
      }
    }
  }

  void disposeGeo() {
    searchDebounce?.cancel();
  }
}
