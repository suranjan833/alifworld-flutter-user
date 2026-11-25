class VariantAddonOptionModel {
  final String label;
  final int priceMinor;

  VariantAddonOptionModel({
    required this.label,
    required this.priceMinor,
  });

  double get priceMajor => priceMinor / 100.0;

  factory VariantAddonOptionModel.fromJson(Map<String, dynamic> json) {
    return VariantAddonOptionModel(
      label: json['label']?.toString() ?? '',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'priceMinor': priceMinor,
    };
  }
}

class VariantAddonModel {
  final String id;
  final String name;
  final String type; // dropdown | checkbox | radio | multi_select
  final int priceMinor;
  final List<VariantAddonOptionModel> options;
  final bool required;
  final int sortOrder;

  VariantAddonModel({
    required this.id,
    required this.name,
    required this.type,
    this.priceMinor = 0,
    this.options = const [],
    this.required = false,
    this.sortOrder = 0,
  });

  double get priceMajor => priceMinor / 100.0;

  factory VariantAddonModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<VariantAddonOptionModel> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .whereType<Map>()
          .map((e) => VariantAddonOptionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return VariantAddonModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'checkbox',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      options: parsedOptions,
      required: json['required'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'priceMinor': priceMinor,
      'options': options.map((e) => e.toJson()).toList(),
      'required': required,
      'sortOrder': sortOrder,
    };
  }
}
