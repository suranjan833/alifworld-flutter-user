export 'geo_model.dart';

class AddressModel {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String fullName;
  final String phone;
  final String addressLine;
  final String division;
  final String divisionBn;
  final String district;
  final String districtBn;
  final String upazila;
  final String upazilaBn;
  final String union;
  final String unionBn;
  final String area;
  final String areaBn;
  final String postalCode;
  bool isDefault;
  final String? createdAt;
  final String? updatedAt;

  AddressModel({
    required this.id,
    this.userId = '',
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.division,
    this.divisionBn = '',
    required this.district,
    this.districtBn = '',
    required this.upazila,
    this.upazilaBn = '',
    this.union = '',
    this.unionBn = '',
    this.area = '',
    this.areaBn = '',
    this.postalCode = '',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  // Backward-compatibility getters for existing views & controllers
  String get name => fullName;
  String get street => addressLine;
  String get city => district.isNotEmpty ? district : division;
  String get state => division;
  String get zone => upazila.isNotEmpty ? upazila : union;
  String get pincode => postalCode;
  String get type => label;

  /// Full formatted address string for display
  String get formattedAddress {
    final parts = [addressLine, area, union, upazila, district, division]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final base = parts.isNotEmpty ? parts.join(', ') : addressLine;
    if (postalCode.trim().isNotEmpty) {
      return '$base - $postalCode';
    }
    return base;
  }

  /// Formatted geo hierarchy: Area, Union, Upazila, District, Division
  String get formattedGeo {
    final parts = [area, union, upazila, district, division]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Formatted Bangla address string if bn names are present
  String get formattedAddressBn {
    final parts = [
      addressLine,
      areaBn.isNotEmpty ? areaBn : area,
      unionBn.isNotEmpty ? unionBn : union,
      upazilaBn.isNotEmpty ? upazilaBn : upazila,
      districtBn.isNotEmpty ? districtBn : district,
      divisionBn.isNotEmpty ? divisionBn : division,
    ].where((s) => s.trim().isNotEmpty).toList();
    final base = parts.isNotEmpty ? parts.join(', ') : addressLine;
    if (postalCode.trim().isNotEmpty) {
      return '$base - $postalCode';
    }
    return base;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    String clean(dynamic v) {
      if (v == null) return '';
      var s = v.toString().trim();
      while (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
        s = s.substring(1, s.length - 1).trim();
      }
      return s.replaceAll('"', '').trim();
    }

    final id = clean(json['id'] ?? json['_id']);
    final userId = clean(json['userId'] ?? json['user_id']);
    final rawLabel = clean(json['label'] ?? json['type']);
    final label = rawLabel.isNotEmpty ? rawLabel : 'Home';
    final fullName = clean(
      json['fullName'] ?? json['name'] ?? json['recipientName'] ?? 'Customer',
    );
    final phone = clean(json['phone']);
    final addressLine = clean(
      json['addressLine'] ?? json['street'] ?? json['address'],
    );
    final division = clean(json['division'] ?? json['state']);
    final divisionBn = clean(json['divisionBn'] ?? json['division_bn']);
    final district = clean(json['district'] ?? json['city']);
    final districtBn = clean(json['districtBn'] ?? json['district_bn']);
    final upazila = clean(json['upazila'] ?? json['zone']);
    final upazilaBn = clean(json['upazilaBn'] ?? json['upazila_bn']);
    final union = clean(json['union']);
    final unionBn = clean(json['unionBn'] ?? json['union_bn']);
    final area = clean(json['area']);
    final areaBn = clean(json['areaBn'] ?? json['area_bn']);
    final postalCode = clean(json['postalCode'] ?? json['pincode']);
    final isDefault = json['isDefault'] == true;

    return AddressModel(
      id: id,
      userId: userId,
      label: label,
      fullName: fullName,
      phone: phone,
      addressLine: addressLine,
      division: division,
      divisionBn: divisionBn,
      district: district,
      districtBn: districtBn,
      upazila: upazila,
      upazilaBn: upazilaBn,
      union: union,
      unionBn: unionBn,
      area: area,
      areaBn: areaBn,
      postalCode: postalCode,
      isDefault: isDefault,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'label': label,
      'fullName': fullName,
      'phone': phone,
      'addressLine': addressLine,
      'division': division,
      if (divisionBn.isNotEmpty) 'divisionBn': divisionBn,
      'district': district,
      if (districtBn.isNotEmpty) 'districtBn': districtBn,
      'upazila': upazila,
      if (upazilaBn.isNotEmpty) 'upazilaBn': upazilaBn,
      'union': union,
      if (unionBn.isNotEmpty) 'unionBn': unionBn,
      'area': area,
      if (areaBn.isNotEmpty) 'areaBn': areaBn,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }
}
