// Geo models supporting English and Bangla (bnName) names
// across the 5-level Bangladesh delivery hierarchy:
// Division -> District -> Upazila / City Corporation -> Union / Pourashava -> Area

class GeoDivision {
  final String id;
  final String name;
  final String bnName;

  GeoDivision({
    required this.id,
    required this.name,
    this.bnName = '',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  factory GeoDivision.fromJson(Map<String, dynamic> json) {
    return GeoDivision(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
      };
}

class GeoDistrict {
  final String id;
  final String name;
  final String bnName;

  GeoDistrict({
    required this.id,
    required this.name,
    this.bnName = '',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  factory GeoDistrict.fromJson(Map<String, dynamic> json) {
    return GeoDistrict(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
      };
}

class GeoUpazila {
  final String id;
  final String name;
  final String bnName;
  final String type; // 'upazila' or 'city_corporation'

  GeoUpazila({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'upazila',
  });

  bool get isCityCorporation => type == 'city_corporation';

  String get displayName {
    final typeSuffix = isCityCorporation ? ' [City Corp]' : '';
    if (bnName.trim().isNotEmpty) {
      return '$name ($bnName)$typeSuffix';
    }
    return '$name$typeSuffix';
  }

  factory GeoUpazila.fromJson(Map<String, dynamic> json) {
    return GeoUpazila(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'upazila',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
      };
}

class GeoUnion {
  final String id;
  final String name;
  final String bnName;
  final String type; // 'union' or 'pourashava'

  GeoUnion({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'union',
  });

  bool get isPourashava => type == 'pourashava';

  String get displayName {
    final typeSuffix = isPourashava ? ' [Pourashava]' : ' [Union]';
    if (bnName.trim().isNotEmpty) {
      return '$name ($bnName)$typeSuffix';
    }
    return '$name$typeSuffix';
  }

  factory GeoUnion.fromJson(Map<String, dynamic> json) {
    return GeoUnion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'union',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
      };
}

class GeoArea {
  final String id;
  final String name;
  final String bnName;
  final bool isVirtual;

  GeoArea({
    required this.id,
    required this.name,
    this.bnName = '',
    this.isVirtual = false,
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  factory GeoArea.fromJson(Map<String, dynamic> json) {
    return GeoArea(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      isVirtual: json['isVirtual'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        if (isVirtual) 'isVirtual': true,
      };
}

class GeoSearchResult {
  final String type; // 'area', 'union', 'upazila', 'district', 'division'
  final GeoDivision? division;
  final GeoDistrict? district;
  final GeoUpazila? upazila;
  final GeoUnion? union;
  final GeoArea? area;

  GeoSearchResult({
    required this.type,
    this.division,
    this.district,
    this.upazila,
    this.union,
    this.area,
  });

  factory GeoSearchResult.fromJson(Map<String, dynamic> json) {
    return GeoSearchResult(
      type: json['type']?.toString() ?? '',
      division: json['division'] is Map<String, dynamic>
          ? GeoDivision.fromJson(json['division'])
          : null,
      district: json['district'] is Map<String, dynamic>
          ? GeoDistrict.fromJson(json['district'])
          : null,
      upazila: json['upazila'] is Map<String, dynamic>
          ? GeoUpazila.fromJson(json['upazila'])
          : null,
      union: json['union'] is Map<String, dynamic>
          ? GeoUnion.fromJson(json['union'])
          : null,
      area: json['area'] is Map<String, dynamic>
          ? GeoArea.fromJson(json['area'])
          : null,
    );
  }

  String get breadcrumb {
    final parts = [
      if (area != null) area!.displayName,
      if (union != null) union!.displayName,
      if (upazila != null) upazila!.displayName,
      if (district != null) district!.displayName,
      if (division != null) division!.displayName,
    ];
    return parts.join(' › ');
  }
}
