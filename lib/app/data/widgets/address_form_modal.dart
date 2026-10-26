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

  // 5-Level Geo Lists using typed Geo models
  List<GeoDivision> _divisions = [];
  List<GeoDistrict> _districts = [];
  List<GeoUpazila> _upazilas = [];
  List<GeoUnion> _unions = [];
  List<GeoArea> _areas = [];

  // Selected Geo Objects
  GeoDivision? _selectedDivision;
  GeoDistrict? _selectedDistrict;
  GeoUpazila? _selectedUpazila;
  GeoUnion? _selectedUnion;
  GeoArea? _selectedArea;

  // Loading states
  bool _isLoadingDivisions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingUpazilas = false;
  bool _isLoadingUnions = false;
  bool _isLoadingAreas = false;
  bool _isSaving = false;

  // Search state
  List<GeoSearchResult> _searchResults = [];
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

  // Helper to normalize Bangladeshi phone to 01XXXXXXXXX
  String _normalizeBdPhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880')) {
      digits = digits.substring(3);
    }
    if (digits.length == 10 && digits.startsWith('1')) {
      digits = '0$digits';
    }
    return digits;
  }

  bool _isValidBdPhone(String input) {
    final normalized = _normalizeBdPhone(input);
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(normalized);
  }

  // --- 5-Level Geo Cascade API Loaders ---

  Future<void> _loadDivisions() async {
    setState(() => _isLoadingDivisions = true);
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

        setState(() {
          _divisions = list;
          _isLoadingDivisions = false;
        });

        // Pre-fill existing address division if editing
        if (widget.address != null && widget.address!.division.isNotEmpty) {
          final target = widget.address!.division.toLowerCase().trim();
          final targetBn = widget.address!.divisionBn.toLowerCase().trim();
          final match = _divisions.firstWhereOrNull(
            (d) =>
                d.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty &&
                    d.bnName.toLowerCase().trim() == targetBn),
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
        final rawList = (data is Map && data['districts'] is List)
            ? (data['districts'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoDistrict.fromJson(j))
            .toList();

        setState(() {
          _districts = list;
          _isLoadingDistricts = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.district.toLowerCase().trim();
          final targetBn = widget.address!.districtBn.toLowerCase().trim();
          final match = _districts.firstWhereOrNull(
            (d) =>
                d.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty &&
                    d.bnName.toLowerCase().trim() == targetBn),
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
        final rawList = (data is Map && data['upazilas'] is List)
            ? (data['upazilas'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoUpazila.fromJson(j))
            .toList();

        setState(() {
          _upazilas = list;
          _isLoadingUpazilas = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.upazila.toLowerCase().trim();
          final targetBn = widget.address!.upazilaBn.toLowerCase().trim();
          final match = _upazilas.firstWhereOrNull(
            (u) =>
                u.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty &&
                    u.bnName.toLowerCase().trim() == targetBn),
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
        final rawList = (data is Map && data['unions'] is List)
            ? (data['unions'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoUnion.fromJson(j))
            .toList();

        setState(() {
          _unions = list;
          _isLoadingUnions = false;
        });

        if (prefill && widget.address != null) {
          final target = widget.address!.union.toLowerCase().trim();
          final targetBn = widget.address!.unionBn.toLowerCase().trim();
          final match = _unions.firstWhereOrNull(
            (u) =>
                u.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty &&
                    u.bnName.toLowerCase().trim() == targetBn),
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
        final rawList = (data is Map && data['areas'] is List)
            ? (data['areas'] as List)
            : <dynamic>[];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => GeoArea.fromJson(j))
            .toList();

        GeoArea? fallbackArea;
        if (list.isEmpty && _selectedUnion != null) {
          final unionName = _selectedUnion!.name;
          final unionBn = _selectedUnion!.bnName;
          fallbackArea = GeoArea(
            id: '',
            name: '$unionName Area',
            bnName: unionBn.isNotEmpty ? '$unionBn এলাকা' : '',
            isVirtual: true,
          );
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
          final targetBn = widget.address!.areaBn.toLowerCase().trim();
          final match = _areas.firstWhereOrNull(
            (a) =>
                a.name.toLowerCase().trim() == target ||
                (targetBn.isNotEmpty &&
                    a.bnName.toLowerCase().trim() == targetBn),
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
  void _onSelectDivision(GeoDivision div, {bool prefill = false}) {
    setState(() => _selectedDivision = div);
    _loadDistricts(div.id, prefill: prefill);
  }

  void _onSelectDistrict(GeoDistrict dist, {bool prefill = false}) {
    setState(() => _selectedDistrict = dist);
    _loadUpazilas(dist.id, prefill: prefill);
  }

  void _onSelectUpazila(GeoUpazila upz, {bool prefill = false}) {
    setState(() => _selectedUpazila = upz);
    _loadUnions(upz.id, prefill: prefill);
  }

  void _onSelectUnion(GeoUnion un, {bool prefill = false}) {
    setState(() => _selectedUnion = un);
    _loadAreas(un.id, prefill: prefill);
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
          final rawList = (data is Map && data['results'] is List)
              ? (data['results'] as List)
              : <dynamic>[];
          final list = rawList
              .whereType<Map<String, dynamic>>()
              .map((j) => GeoSearchResult.fromJson(j))
              .toList();
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

  Future<void> _applySearchResult(GeoSearchResult hit) async {
    final div = hit.division;
    final dist = hit.district;
    final upz = hit.upazila;
    final un = hit.union;
    final ar = hit.area;

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
      await _loadDistricts(div.id);
      if (dist != null) {
        setState(() => _selectedDistrict = dist);
        await _loadUpazilas(dist.id);
        if (upz != null) {
          setState(() => _selectedUpazila = upz);
          await _loadUnions(upz.id);
          if (un != null) {
            setState(() => _selectedUnion = un);
            await _loadAreas(un.id);
            if (ar != null) {
              setState(() => _selectedArea = ar);
            }
          }
        }
      }
    }
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

    final isVirtualArea = _selectedArea?.isVirtual == true;
    final areaName = (_areas.isNotEmpty && !isVirtualArea)
        ? (_selectedArea?.name ?? '')
        : '';

    final payload = <String, dynamic>{
      'label': _selectedLabel,
      'fullName': name,
      'phone': normalizedPhone,
      'addressLine': addressLine,
      'division': _selectedDivision!.name,
      if (_selectedDivision!.bnName.isNotEmpty)
        'divisionBn': _selectedDivision!.bnName,
      'district': _selectedDistrict!.name,
      if (_selectedDistrict!.bnName.isNotEmpty)
        'districtBn': _selectedDistrict!.bnName,
      'upazila': _selectedUpazila!.name,
      if (_selectedUpazila!.bnName.isNotEmpty)
        'upazilaBn': _selectedUpazila!.bnName,
      'union': _selectedUnion != null ? _selectedUnion!.name : '',
      if (_selectedUnion != null && _selectedUnion!.bnName.isNotEmpty)
        'unionBn': _selectedUnion!.bnName,
      'area': areaName,
      if (_selectedArea != null &&
          _selectedArea!.bnName.isNotEmpty &&
          !isVirtualArea)
        'areaBn': _selectedArea!.bnName,
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

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final resData = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        final savedJson = (resData is Map && resData['address'] is Map)
            ? (resData['address'] as Map<String, dynamic>)
            : (resData is Map<String, dynamic> ? resData : payload);

        final saved = AddressModel.fromJson(
          Map<String, dynamic>.from(savedJson),
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
        'Submission Failed',
        'Unable to reach server. Please try again.',
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
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                    SizedBox(height: 30.h),

                

          
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
                                  'Search e.g. Savar, সাভার, Banani, Uttara...',
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
                                  ? Transform.scale(
                                      scale: 0.5,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColor.primaryDark,
                                      ),
                                    )
                                  : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchResults = [];
                                              _isSearching = false;
                                            });
                                          },
                                        )
                                      : null),
                            ),
                          ),

                          // Search Results List
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
                                  return InkWell(
                                    onTap: () => _applySearchResult(hit),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 10.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6.r),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Icon(
                                              Iconsax.location,
                                              size: 14.r,
                                              color: AppColor.primary,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text(
                                              hit.breadcrumb,
                                              style: GoogleFonts.lato(
                                                fontSize: 12.5.sp,
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


                    // 1. Division Dropdown
                    _buildDropdown(
                      label: 'Division *',
                      hint: 'Select Division',
                      isLoading: _isLoadingDivisions,
                      value: _selectedDivision?.displayName,
                      items: _divisions.map((d) => d.displayName).toList(),
                      onChanged: (displayName) {
                        final match = _divisions.firstWhereOrNull(
                          (d) => d.displayName == displayName,
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
                      value: _selectedDistrict?.displayName,
                      items: _districts.map((d) => d.displayName).toList(),
                      onChanged: _selectedDivision == null
                          ? null
                          : (displayName) {
                              final match = _districts.firstWhereOrNull(
                                (d) => d.displayName == displayName,
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
                      value: _selectedUpazila?.displayName,
                      items: _upazilas.map((u) => u.displayName).toList(),
                      onChanged: _selectedDistrict == null
                          ? null
                          : (displayName) {
                              final match = _upazilas.firstWhereOrNull(
                                (u) => u.displayName == displayName,
                              );
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
                      value: _selectedUnion?.displayName,
                      items: _unions.map((u) => u.displayName).toList(),
                      onChanged: (_selectedUpazila == null || _unions.isEmpty)
                          ? null
                          : (displayName) {
                              final match = _unions.firstWhereOrNull(
                                (u) => u.displayName == displayName,
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
                      value: _selectedArea?.displayName,
                      items: _areas.isNotEmpty
                          ? _areas.map((a) => a.displayName).toList()
                          : (_selectedArea != null
                              ? [_selectedArea!.displayName]
                              : const []),
                      onChanged: (_selectedUnion == null || _areas.isEmpty)
                          ? null
                          : (displayName) {
                              final match = _areas.firstWhereOrNull(
                                (a) => a.displayName == displayName,
                              );
                              if (match != null) {
                                setState(() => _selectedArea = match);
                              }
                            },
                    ),
                    SizedBox(height: 18.h),

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
