class AddressModel {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String fullName;
  final String phone;
  final String addressLine;
  final String division;
  final String district;
  final String upazila;
  final String union;
  final String area;
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
    required this.district,
    required this.upazila,
    this.union = '',
    this.area = '',
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
    final district = clean(json['district'] ?? json['city']);
    final upazila = clean(json['upazila'] ?? json['zone']);
    final union = clean(json['union']);
    final area = clean(json['area']);
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
      district: district,
      upazila: upazila,
      union: union,
      area: area,
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
      'district': district,
      'upazila': upazila,
      'union': union,
      'area': area,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }
}

