// Geo models supporting English and Bangla (bnName) names
// and dynamic admin-managed kinds across the 5-level Bangladesh delivery hierarchy.

class GeoTypeOption {
  final String type;
  final String label;
  final String? bnName;
  final bool isDefault;

  const GeoTypeOption({
    required this.type,
    required this.label,
    this.bnName,
    this.isDefault = false,
  });

  String localizedLabel(bool isBangla) {
    if (isBangla && bnName != null && bnName!.trim().isNotEmpty) {
      return bnName!.trim();
    }
    return label.trim().isNotEmpty ? label.trim() : type;
  }

  factory GeoTypeOption.fromJson(Map<String, dynamic> json) {
    return GeoTypeOption(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      bnName: json['bnName']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}

class GeoLevelTypes {
  final String level;
  final List<GeoTypeOption> types;

  const GeoLevelTypes({
    required this.level,
    required this.types,
  });

  String fieldLabel(bool isBangla) {
    return types
        .map((t) => t.localizedLabel(isBangla))
        .where((s) => s.isNotEmpty)
        .join(' / ');
  }

  factory GeoLevelTypes.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['types'] is List ? (json['types'] as List) : const [];
    return GeoLevelTypes(
      level: json['level']?.toString() ?? '',
      types: rawTypes
          .whereType<Map>()
          .map((e) => GeoTypeOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class GeoDropdownOption {
  final String id;
  final String label;

  const GeoDropdownOption({
    required this.id,
    required this.label,
  });
}

List<GeoDropdownOption> buildGeoDropdownOptions<T>(
  List<T> items, {
  required String Function(T) getId,
  required String Function(T) getName,
  required String Function(T, bool hasCollision) getLabel,
}) {
  final nameCounts = <String, int>{};
  for (final item in items) {
    final key = getName(item).trim().toLowerCase();
    nameCounts[key] = (nameCounts[key] ?? 0) + 1;
  }
  return items.map((item) {
    final key = getName(item).trim().toLowerCase();
    final hasCollision = (nameCounts[key] ?? 0) > 1;
    return GeoDropdownOption(
      id: getId(item),
      label: getLabel(item, hasCollision),
    );
  }).toList();
}

String _formatGeoDisplay(
  String name,
  String bnName,
  String type,
  String typeLabel,
  bool hasCollision,
) {
  final base = bnName.trim().isNotEmpty ? '$name ($bnName)' : name;
  if (!hasCollision) return base;
  final suffix = typeLabel.trim().isNotEmpty ? typeLabel.trim() : type.trim();
  return suffix.isNotEmpty ? '$base ($suffix)' : base;
}

class GeoDivision {
  final String id;
  final String name;
  final String bnName;
  final String type;
  final String typeLabel;

  GeoDivision({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'division',
    this.typeLabel = 'Division',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  String displayWithCollision(bool hasCollision) =>
      _formatGeoDisplay(name, bnName, type, typeLabel, hasCollision);

  factory GeoDivision.fromJson(Map<String, dynamic> json) {
    return GeoDivision(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'division',
      typeLabel: json['typeLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
        if (typeLabel.isNotEmpty) 'typeLabel': typeLabel,
      };
}

class GeoDistrict {
  final String id;
  final String name;
  final String bnName;
  final String type;
  final String typeLabel;

  GeoDistrict({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'district',
    this.typeLabel = 'District',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  String displayWithCollision(bool hasCollision) =>
      _formatGeoDisplay(name, bnName, type, typeLabel, hasCollision);

  factory GeoDistrict.fromJson(Map<String, dynamic> json) {
    return GeoDistrict(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'district',
      typeLabel: json['typeLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
        if (typeLabel.isNotEmpty) 'typeLabel': typeLabel,
      };
}

class GeoUpazila {
  final String id;
  final String name;
  final String bnName;
  final String type;
  final String typeLabel;

  GeoUpazila({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'upazila',
    this.typeLabel = '',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  String displayWithCollision(bool hasCollision) =>
      _formatGeoDisplay(name, bnName, type, typeLabel, hasCollision);

  factory GeoUpazila.fromJson(Map<String, dynamic> json) {
    return GeoUpazila(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'upazila',
      typeLabel: json['typeLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
        if (typeLabel.isNotEmpty) 'typeLabel': typeLabel,
      };
}

class GeoUnion {
  final String id;
  final String name;
  final String bnName;
  final String type;
  final String typeLabel;

  GeoUnion({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'union',
    this.typeLabel = '',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  String displayWithCollision(bool hasCollision) =>
      _formatGeoDisplay(name, bnName, type, typeLabel, hasCollision);

  factory GeoUnion.fromJson(Map<String, dynamic> json) {
    return GeoUnion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'union',
      typeLabel: json['typeLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
        if (typeLabel.isNotEmpty) 'typeLabel': typeLabel,
      };
}

class GeoArea {
  final String id;
  final String name;
  final String bnName;
  final String type;
  final String typeLabel;

  GeoArea({
    required this.id,
    required this.name,
    this.bnName = '',
    this.type = 'area',
    this.typeLabel = '',
  });

  String get displayName =>
      bnName.trim().isNotEmpty ? '$name ($bnName)' : name;

  String displayWithCollision(bool hasCollision) =>
      _formatGeoDisplay(name, bnName, type, typeLabel, hasCollision);

  factory GeoArea.fromJson(Map<String, dynamic> json) {
    return GeoArea(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bnName: json['bnName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'area',
      typeLabel: json['typeLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bnName': bnName,
        'type': type,
        if (typeLabel.isNotEmpty) 'typeLabel': typeLabel,
      };
}

class GeoSearchResult {
  final String type;
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
