class ProductReviewsResponse {
  final ReviewSummary summary;
  final List<ProductReviewItem> reviews;
  final String? nextCursor;

  ProductReviewsResponse({
    required this.summary,
    required this.reviews,
    this.nextCursor,
  });

  factory ProductReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ProductReviewsResponse(
      summary: ReviewSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : (json['summary'] is Map
                  ? Map<String, dynamic>.from(json['summary'] as Map)
                  : {}),
      ),
      reviews: (json['reviews'] as List? ?? [])
          .map(
            (r) => ProductReviewItem.fromJson(
              r is Map<String, dynamic>
                  ? r
                  : (r is Map ? Map<String, dynamic>.from(r) : {}),
            ),
          )
          .toList(),
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}

class ReviewSummary {
  final double average;
  final int count;
  final Map<String, int> distribution;

  ReviewSummary({
    required this.average,
    required this.count,
    required this.distribution,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final dist = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    if (json['distribution'] is Map) {
      json['distribution'].forEach((k, v) {
        dist[k.toString()] = (v is num) ? v.toInt() : 0;
      });
    }
    final rawAvg =
        json['average'] ?? json['avg'] ?? json['rating'] ?? json['avgRating'];
    final rawCount = json['count'] ?? json['total'] ?? json['totalReviews'];
    return ReviewSummary(
      average: (rawAvg is num) ? rawAvg.toDouble() : 0.0,
      count: (rawCount is num) ? rawCount.toInt() : 0,
      distribution: dist,
    );
  }
}

class ProductReviewItem {
  final String id;
  final int rating;
  final String? title;
  final String? body;
  final String? reply;
  final List<String> photos;
  final String? reviewerName;
  String? get authorName => reviewerName;
  final DateTime createdAt;

  ProductReviewItem({
    required this.id,
    required this.rating,
    this.title,
    this.body,
    this.reply,
    this.photos = const [],
    String? reviewerName,
    String? authorName,
    required this.createdAt,
  }) : reviewerName = reviewerName ?? authorName;

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photoList = <String>[];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is String && p.isNotEmpty) {
          photoList.add(p);
        } else if (p is Map && p['url'] != null) {
          photoList.add(p['url'].toString());
        }
      }
    }

    String? name = json['reviewerName']?.toString() ??
        json['customerName']?.toString() ??
        json['userName']?.toString() ??
        json['authorName']?.toString() ??
        json['name']?.toString();
    if (name == null || name.isEmpty) {
      if (json['user'] is Map) {
        name = json['user']['name']?.toString() ??
            json['user']['displayName']?.toString() ??
            json['user']['fullName']?.toString();
      } else if (json['customer'] is Map) {
        name = json['customer']['name']?.toString() ??
            json['customer']['displayName']?.toString();
      }
    }

    return ProductReviewItem(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : 5,
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      reply: json['reply']?.toString(),
      photos: photoList,
      reviewerName: name,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
