import '../../categories/models/product_model.dart';

class SearchPaginationModel {
  final String? cursor;
  final bool hasMore;

  SearchPaginationModel({
    this.cursor,
    this.hasMore = false,
  });

  factory SearchPaginationModel.fromJson(Map<String, dynamic> json) {
    return SearchPaginationModel(
      cursor: json['cursor']?.toString(),
      hasMore: json['hasMore'] == true,
    );
  }
}

class SearchRangesModel {
  final int? minPrice;
  final int? maxPrice;
  final int? maxPoints;

  SearchRangesModel({
    this.minPrice,
    this.maxPrice,
    this.maxPoints,
  });

  factory SearchRangesModel.fromJson(Map<String, dynamic> json) {
    return SearchRangesModel(
      minPrice: (json['minPrice'] as num?)?.toInt(),
      maxPrice: (json['maxPrice'] as num?)?.toInt(),
      maxPoints: (json['maxPoints'] as num?)?.toInt(),
    );
  }

  double? get minPriceMajor => minPrice != null ? minPrice! / 100.0 : null;
  double? get maxPriceMajor => maxPrice != null ? maxPrice! / 100.0 : null;
}

class SearchResponseModel {
  final List<ProductModel> products;
  final SearchPaginationModel pagination;
  final SearchRangesModel? ranges;

  SearchResponseModel({
    required this.products,
    required this.pagination,
    this.ranges,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    List<ProductModel> prods = [];
    if (rawData['products'] is List) {
      prods = (rawData['products'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => ProductModel.fromJson(item))
          .toList();
    }

    final pag = rawData['pagination'] is Map<String, dynamic>
        ? SearchPaginationModel.fromJson(
            rawData['pagination'] as Map<String, dynamic>)
        : SearchPaginationModel();

    final rng = rawData['ranges'] is Map<String, dynamic>
        ? SearchRangesModel.fromJson(rawData['ranges'] as Map<String, dynamic>)
        : null;

    return SearchResponseModel(
      products: prods,
      pagination: pag,
      ranges: rng,
    );
  }
}
