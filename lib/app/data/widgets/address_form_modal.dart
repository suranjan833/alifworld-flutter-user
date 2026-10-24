import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../models/address_model.dart';

class AddressFormModal extends StatefulWidget {
  final AddressModel? address;
  final ValueChanged<AddressModel> onSaved;

  const AddressFormModal({
    super.key,
    this.address,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    AddressModel? address,
    required ValueChanged<AddressModel> onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.transparent,
      builder: (ctx) => AddressFormModal(
        address: address,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AddressFormModal> createState() => _AddressFormModalState();
}

class _AddressFormModalState extends State<AddressFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLineController;
  late TextEditingController _postalCodeController;
  late TextEditingController _searchController;

  String _selectedLabel = 'Home';
  bool _isDefault = false;

  // 5-Level Geo Lists
  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _upazilas = [];
  List<Map<String, dynamic>> _unions = [];
  List<Map<String, dynamic>> _areas = [];

  // Selected Geo Objects { id, name, type }
  Map<String, dynamic>? _selectedDivision;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedUpazila;
  Map<String, dynamic>? _selectedUnion;
  Map<String, dynamic>? _selectedArea;

  // Loading states
  bool _isLoadingDivisions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingUpazilas = false;
  bool _isLoadingUnions = false;
  bool _isLoadingAreas = false;
  bool _isSaving = false;

  // Search state
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final defaultName = getBox.read(USER_NAME)?.toString() ?? '';
    final defaultPhone = getBox.read(USER_PHONE)?.toString() ?? '';

    _nameController = TextEditingController(
      text: a != null ? a.fullName : defaultName,
    );
    _phoneController = TextEditingController(
      text: a != null ? a.phone : defaultPhone,
    );
    _addressLineController = TextEditingController(
      text: a != null ? a.addressLine : '',
    );
    _postalCodeController = TextEditingController(
      text: a != null ? a.postalCode : '',
    );
    _searchController = TextEditingController();

    _selectedLabel = a != null ? a.label : 'Home';
    _isDefault = a != null ? a.isDefault : false;

    _loadDivisions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _postalCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Normalizes BD phone number to 01XXXXXXXXX ---
  String _normalizeBdPhone(String input) {
    var clean = input.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('880')) {
      clean = clean.substring(3);
    }
    while (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '0$clean';
  }

  bool _isValidBdPhone(String phone) {
    final normalized = _normalizeBdPhone(phone);
    return normalized.length == 11 && normalized.startsWith('01');
  }

  // --- Geo API Fetchers ---
  Future<void> _loadDivisions() async {
    setState(() => _isLoadingDivisions = true);
    try {
      final res = await dioGet('geo/divisions');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final list = (data is Map && data['divisions'] is List)
            ? (data['divisions'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        setState(() {
          _divisions = list;
          _isLoadingDivisions = false;
        });

        // Pre-fill existing address division if editing
        if (widget.address != null && widget.address!.division.isNotEmpty) {
          final target = widget.address!.division.toLowerCase().trim();
          final match = _divisions.firstWhereOrNull(
            (d) => d['name']?.toString().toLowerCase().trim() == target,
          );
          if (match != null) {
            _onSelectDivision(match, prefill: true);
          }
        }
      } else {
        setState(() => _isLoadingDivisions = false);
      }
    } catch (_) {
      setState(() => _isLoadingDivisions = false);
    }
  }

  Future<void> _loadDistricts(String divisionId, {bool prefill = false}) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _upazilas = [];
      _selectedUpazila = null;
      _unions = [];
      _selectedUnion = null;
      _areas = [];
      _selectedArea = null;
    });

    try {
      final res = await dioGet('geo/districts?divisionId=$divisionId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final list = (data is Map && data['districts'] is List)
            ? (data['districts'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        setState(() {
          _districts = list;
          _isLoadingDistricts = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.district.toLowerCase().trim();
          final match = _districts.firstWhereOrNull(
            (d) => d['name']?.toString().toLowerCase().trim() == target,
          );
          if (match != null) {
            _onSelectDistrict(match, prefill: true);
          }
        }
      } else {
        setState(() => _isLoadingDistricts = false);
      }
    } catch (_) {
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadUpazilas(String districtId, {bool prefill = false}) async {
    setState(() {
      _isLoadingUpazilas = true;
      _upazilas = [];
      _selectedUpazila = null;
      _unions = [];
      _selectedUnion = null;
      _areas = [];
      _selectedArea = null;
    });

    try {
      final res = await dioGet('geo/upazilas?districtId=$districtId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final list = (data is Map && data['upazilas'] is List)
            ? (data['upazilas'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        setState(() {
          _upazilas = list;
          _isLoadingUpazilas = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.upazila.toLowerCase().trim();
          final match = _upazilas.firstWhereOrNull(
            (u) => u['name']?.toString().toLowerCase().trim() == target,
          );
          if (match != null) {
            _onSelectUpazila(match, prefill: true);
          }
        }
      } else {
        setState(() => _isLoadingUpazilas = false);
      }
    } catch (_) {
      setState(() => _isLoadingUpazilas = false);
    }
  }

  Future<void> _loadUnions(String upazilaId, {bool prefill = false}) async {
    setState(() {
      _isLoadingUnions = true;
      _unions = [];
      _selectedUnion = null;
      _areas = [];
      _selectedArea = null;
    });

    try {
      final res = await dioGet('geo/unions?upazilaId=$upazilaId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final list = (data is Map && data['unions'] is List)
            ? (data['unions'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        setState(() {
          _unions = list;
          _isLoadingUnions = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.union.toLowerCase().trim();
          final match = _unions.firstWhereOrNull(
            (u) => u['name']?.toString().toLowerCase().trim() == target,
          );
          if (match != null) {
            _onSelectUnion(match, prefill: true);
          }
        }
      } else {
        setState(() => _isLoadingUnions = false);
      }
    } catch (_) {
      setState(() => _isLoadingUnions = false);
    }
  }

  Future<void> _loadAreas(String unionId, {bool prefill = false}) async {
    setState(() {
      _isLoadingAreas = true;
      _areas = [];
      _selectedArea = null;
    });

    try {
      final res = await dioGet('geo/areas?unionId=$unionId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map && res.data['data'] != null
            ? res.data['data']
            : res.data;
        final list = (data is Map && data['areas'] is List)
            ? (data['areas'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        Map<String, dynamic>? fallbackArea;
        if (list.isEmpty && _selectedUnion != null) {
          final unionName = _selectedUnion!['name']?.toString() ?? 'Default';
          fallbackArea = {
            'id': '',
            'name': '$unionName Area',
            'isVirtual': true,
          };
        }

        setState(() {
          _areas = list;
          _isLoadingAreas = false;
          if (fallbackArea != null) {
            _selectedArea = fallbackArea;
          }
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.area.toLowerCase().trim();
          final match = _areas.firstWhereOrNull(
            (a) => a['name']?.toString().toLowerCase().trim() == target,
          );
          if (match != null) {
            setState(() => _selectedArea = match);
          }
        }
      } else {
        setState(() => _isLoadingAreas = false);
      }
    } catch (_) {
      setState(() => _isLoadingAreas = false);
    }
  }

  // --- Dropdown Selection Handlers ---
  void _onSelectDivision(Map<String, dynamic> div, {bool prefill = false}) {
    setState(() => _selectedDivision = div);
    _loadDistricts(div['id'].toString(), prefill: prefill);
  }

  void _onSelectDistrict(Map<String, dynamic> dist, {bool prefill = false}) {
    setState(() => _selectedDistrict = dist);
    _loadUpazilas(dist['id'].toString(), prefill: prefill);
  }

  void _onSelectUpazila(Map<String, dynamic> upz, {bool prefill = false}) {
    setState(() => _selectedUpazila = upz);
    _loadUnions(upz['id'].toString(), prefill: prefill);
  }

  void _onSelectUnion(Map<String, dynamic> un, {bool prefill = false}) {
    setState(() => _selectedUnion = un);
    _loadAreas(un['id'].toString(), prefill: prefill);
  }

  // --- Combined Geo Search (GET /geo/search?q=...) ---
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final res = await dioGet('geo/search?q=${Uri.encodeComponent(q)}');
        if (res.statusCode == 200 && res.data != null) {
          final data = res.data is Map && res.data['data'] != null
              ? res.data['data']
              : res.data;
          final list = (data is Map && data['results'] is List)
              ? (data['results'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
          setState(() {
            _searchResults = list;
            _isSearching = false;
          });
        } else {
          setState(() => _isSearching = false);
        }
      } catch (_) {
        setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _applySearchResult(Map<String, dynamic> item) async {
    final div = item['division'] as Map<String, dynamic>?;
    final dist = item['district'] as Map<String, dynamic>?;
    final upz = item['upazila'] as Map<String, dynamic>?;
    final un = item['union'] as Map<String, dynamic>?;
    final ar = item['area'] as Map<String, dynamic>?;

    setState(() {
      _searchResults = [];
      _searchController.clear();
      _selectedDivision = div;
      _selectedDistrict = dist;
      _selectedUpazila = upz;
      _selectedUnion = un;
      _selectedArea = ar;
    });

    if (div != null) {
      await _loadDistricts(div['id'].toString());
      if (dist != null) {
        setState(() => _selectedDistrict = dist);
        await _loadUpazilas(dist['id'].toString());
        if (upz != null) {
          setState(() => _selectedUpazila = upz);
          await _loadUnions(upz['id'].toString());
          if (un != null) {
            setState(() => _selectedUnion = un);
            await _loadAreas(un['id'].toString());
            if (ar != null) {
              setState(() => _selectedArea = ar);
            }
          }
        }
      }
    }
  }

  // Helper to format union display name with type disambiguation
  String _formatUnionName(Map<String, dynamic> u) {
    final name = u['name']?.toString() ?? '';
    final type = u['type']?.toString().toLowerCase() ?? '';
    final count = _unions
        .where(
          (x) =>
              x['name']?.toString().toLowerCase().trim() ==
              name.toLowerCase().trim(),
        )
        .length;
    if (count > 1 && type.isNotEmpty) {
      final capType = '${type[0].toUpperCase()}${type.substring(1)}';
      return '$name ($capType)';
    }
    return name;
  }

  // --- Save / Update Address ---
  Future<void> _saveAddress() async {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final addressLine = _addressLineController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    if (name.isEmpty) {
      showSnack('Missing Name', 'Please enter your full name', bg: AppColor.red);
      return;
    }

    if (!_isValidBdPhone(rawPhone)) {
      showSnack(
        'Invalid Phone',
        'Please enter a valid 11-digit BD mobile number (01XXXXXXXXX)',
        bg: AppColor.red,
      );
      return;
    }

    if (addressLine.isEmpty) {
      showSnack(
        'Missing Address',
        'Please enter your full house/street address',
        bg: AppColor.red,
      );
      return;
    }

    if (_selectedDivision == null) {
      showSnack('Missing Division', 'Please select your division', bg: AppColor.red);
      return;
    }

    if (_selectedDistrict == null) {
      showSnack('Missing District', 'Please select your district', bg: AppColor.red);
      return;
    }

    if (_selectedUpazila == null) {
      showSnack('Missing Upazila', 'Please select your upazila', bg: AppColor.red);
      return;
    }

    if (_unions.isNotEmpty && _selectedUnion == null) {
      showSnack('Missing Union', 'Please select your union', bg: AppColor.red);
      return;
    }

    if (_selectedArea == null) {
      showSnack('Missing Area', 'Please select your area', bg: AppColor.red);
      return;
    }

    setState(() => _isSaving = true);

    final normalizedPhone = _normalizeBdPhone(rawPhone);
    final isEditing = widget.address != null;

    final isVirtualArea = _selectedArea?['isVirtual'] == true;
    final areaName = (_areas.isNotEmpty && !isVirtualArea)
        ? (_selectedArea?['name']?.toString() ?? '')
        : '';

    final payload = <String, dynamic>{
      'label': _selectedLabel,
      'fullName': name,
      'phone': normalizedPhone,
      'addressLine': addressLine,
      'division': _selectedDivision!['name']?.toString(),
      'district': _selectedDistrict!['name']?.toString(),
      'upazila': _selectedUpazila!['name']?.toString(),
      'union': _selectedUnion != null ? _selectedUnion!['name']?.toString() : '',
      'area': areaName,
      'postalCode': postalCode,
      'isDefault': _isDefault,
    };

    try {
      dynamic response;
      if (isEditing) {
        response = await dioPatch(
          endUrl: 'addresses/${widget.address!.id}',
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

      setState(() => _isSaving = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData['data'] != null) {
          rawData = rawData['data'];
        }
        Map<String, dynamic> addrJson = {};
        if (rawData is Map && rawData['address'] is Map) {
          addrJson = (rawData['address'] as Map).cast<String, dynamic>();
        } else if (rawData is Map) {
          addrJson = rawData.cast<String, dynamic>();
        }

        final saved = AddressModel.fromJson(
          addrJson.isNotEmpty ? addrJson : payload,
        );

        showSnack(
          isEditing ? 'Address Updated' : 'Address Added',
          isEditing
              ? 'Your delivery address has been updated.'
              : 'New delivery address added successfully.',
          bg: AppColor.teal,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSaved(saved);
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
      setState(() => _isSaving = false);
      showSnack(
        'Address Error',
        'Something went wrong. Please try again.',
        bg: AppColor.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.h),
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        isEditing ? Iconsax.edit_2 : Iconsax.location_add,
                        color: AppColor.primaryDark,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      isEditing ? 'Edit Address' : 'Add New Address',
                      style: GoogleFonts.lato(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColor.textSecondary,
                    size: 22.r,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Quick Geo Search Box ---
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.search_normal_1,
                                size: 16.r,
                                color: AppColor.primaryDark,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Quick Area Search (1-Tap Fill)',
                                style: GoogleFonts.lato(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.lato(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search e.g. Savar, Banani, Mirpur, Uttara...',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 12.5.sp,
                                color: AppColor.textHint,
                              ),
                              filled: true,
                              fillColor: AppColor.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: AppColor.primary,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _isSearching
                                  ? Padding(
                                      padding: EdgeInsets.all(12.r),
                                      child: SizedBox(
                                        width: 14.r,
                                        height: 14.r,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColor.primaryDark,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Search Result List
                          if (_searchResults.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Container(
                              constraints: BoxConstraints(maxHeight: 180.h),
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (ctx, idx) {
                                  final hit = _searchResults[idx];
                                  final div = hit['division']?['name'] ?? '';
                                  final dist = hit['district']?['name'] ?? '';
                                  final upz = hit['upazila']?['name'] ?? '';
                                  final un = hit['union']?['name'] ?? '';
                                  final ar = hit['area']?['name'] ?? '';
                                  final parts = [ar, un, upz, dist, div]
                                      .where((p) => p.toString().isNotEmpty)
                                      .toList();
                                  final breadcrumb = parts.join(' › ');

                                  return InkWell(
                                    onTap: () => _applySearchResult(hit),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Iconsax.location,
                                            size: 15.r,
                                            color: AppColor.primary,
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              breadcrumb,
                                              style: GoogleFonts.lato(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // --- 5-Level Cascade Dropdowns ---
                    Text(
                      'Select Region (Division › District › Upazila › Union › Area)',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // 1. Division Dropdown
                    _buildDropdown(
                      label: 'Division *',
                      hint: 'Select Division',
                      isLoading: _isLoadingDivisions,
                      value: _selectedDivision?['name']?.toString(),
                      items: _divisions.map((d) => d['name'].toString()).toList(),
                      onChanged: (name) {
                        final match = _divisions.firstWhereOrNull(
                          (d) => d['name'].toString() == name,
                        );
                        if (match != null) _onSelectDivision(match);
                      },
                    ),
                    SizedBox(height: 10.h),

                    // 2. District Dropdown
                    _buildDropdown(
                      label: 'District *',
                      hint: _selectedDivision == null
                          ? 'Select division first'
                          : 'Select District',
                      isLoading: _isLoadingDistricts,
                      value: _selectedDistrict?['name']?.toString(),
                      items: _districts.map((d) => d['name'].toString()).toList(),
                      onChanged: _selectedDivision == null
                          ? null
                          : (name) {
                              final match = _districts.firstWhereOrNull(
                                (d) => d['name'].toString() == name,
                              );
                              if (match != null) _onSelectDistrict(match);
                            },
                    ),
                    SizedBox(height: 10.h),

                    // 3. Upazila / City Corporation Dropdown
                    _buildDropdown(
                      label: 'Upazila / City Corporation *',
                      hint: _selectedDistrict == null
                          ? 'Select district first'
                          : 'Select Upazila / City Corporation',
                      isLoading: _isLoadingUpazilas,
                      value: _selectedUpazila != null
                          ? '${_selectedUpazila!['name']}${_selectedUpazila!['type'] == 'city_corporation' ? ' (City Corp)' : ''}'
                          : null,
                      items: _upazilas.map((u) {
                        final isCityCorp = u['type'] == 'city_corporation';
                        return '${u['name']}${isCityCorp ? ' (City Corp)' : ''}';
                      }).toList(),
                      onChanged: _selectedDistrict == null
                          ? null
                          : (itemDisplay) {
                              final match = _upazilas.firstWhereOrNull((u) {
                                final isCityCorp =
                                    u['type'] == 'city_corporation';
                                final disp =
                                    '${u['name']}${isCityCorp ? ' (City Corp)' : ''}';
                                return disp == itemDisplay;
                              });
                              if (match != null) _onSelectUpazila(match);
                            },
                    ),
                    SizedBox(height: 10.h),

                    // 4. Union / Pourashava Dropdown
                    _buildDropdown(
                      label: 'Union / Pourashava *',
                      hint: _selectedUpazila == null
                          ? 'Select upazila first'
                          : (_unions.isEmpty
                              ? 'No unions for this area'
                              : 'Select Union / Pourashava'),
                      isLoading: _isLoadingUnions,
                      value: _selectedUnion != null
                          ? _formatUnionName(_selectedUnion!)
                          : null,
                      items: _unions.map(_formatUnionName).toList(),
                      onChanged: (_selectedUpazila == null || _unions.isEmpty)
                          ? null
                          : (unionDisplay) {
                              final match = _unions.firstWhereOrNull(
                                (u) => _formatUnionName(u) == unionDisplay,
                              );
                              if (match != null) _onSelectUnion(match);
                            },
                    ),
                    SizedBox(height: 10.h),

                    // 5. Area Dropdown
                    _buildDropdown(
                      label: 'Area *',
                      hint: _selectedUnion == null
                          ? 'Select union first'
                          : (_isLoadingAreas
                              ? 'Loading areas...'
                              : 'Select Area'),
                      isLoading: _isLoadingAreas,
                      value: _selectedArea?['name']?.toString(),
                      items: _areas.isNotEmpty
                          ? _areas.map((a) => a['name'].toString()).toList()
                          : (_selectedArea != null
                              ? [_selectedArea!['name'].toString()]
                              : const []),
                      onChanged: (_selectedUnion == null || _areas.isEmpty)
                          ? null
                          : (name) {
                              final match = _areas.firstWhereOrNull(
                                (a) => a['name'].toString() == name,
                              );
                              if (match != null) {
                                setState(() => _selectedArea = match);
                              }
                            },
                    ),
                    SizedBox(height: 18.h),

                    // --- Recipient & Contact Details ---
                    Text(
                      'Recipient & Address Details',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Full Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      hint: 'Mohan Biswas',
                      icon: Iconsax.user,
                    ),
                    SizedBox(height: 10.h),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number (01XXXXXXXXX) *',
                      hint: '01700000000',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Address Line (House, Road, Block)
                    _buildTextField(
                      controller: _addressLineController,
                      label: 'Full Street Address (House, Road, Block) *',
                      hint: 'House 12, Road 5, Block C',
                      icon: Iconsax.home_2,
                      maxLines: 2,
                    ),
                    SizedBox(height: 10.h),

                    // Postal Code
                    _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code (Optional)',
                      hint: '1340',
                      icon: Iconsax.code,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Label (Home / Work / Other)
                    Text(
                      'Address Label',
                      style: GoogleFonts.lato(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: ['Home', 'Work', 'Other'].map((label) {
                        final isSelected = _selectedLabel == label;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedLabel = label),
                            selectedColor: AppColor.primaryLight,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.lato(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColor.primaryDark
                                  : AppColor.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColor.primaryDark
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 14.h),

                    // Default Address Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          activeColor: AppColor.primary,
                          onChanged: (val) =>
                              setState(() => _isDefault = val ?? false),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isDefault = !_isDefault),
                            child: Text(
                              'Set as default delivery address',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Save Address',
                                style: GoogleFonts.lato(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required bool isLoading,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: onChanged == null ? const Color(0xFFF8FAFC) : AppColor.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: onChanged == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.primaryDark,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('Loading...', style: GoogleFonts.lato(fontSize: 12.sp)),
                      ],
                    )
                  : Text(
                      hint,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: AppColor.textHint,
                      ),
                    ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: isLoading ? null : onChanged,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: onChanged == null
                    ? const Color(0xFF94A3B8)
                    : AppColor.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.lato(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(
              fontSize: 13.sp,
              color: AppColor.textHint,
            ),
            prefixIcon: Icon(icon, size: 18.r, color: AppColor.textSecondary),
            filled: true,
            fillColor: AppColor.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                color: AppColor.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
