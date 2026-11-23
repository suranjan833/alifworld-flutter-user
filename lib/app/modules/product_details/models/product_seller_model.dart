class ProductSellerModel {
  final String id;
  final String shopName;
  final String slug;
  final String avatar;
  final double rating;
  final String reviewsCount;
  final String location;
  final bool isVerified;
  final String joinedDate;
  final String bio;
  final String responseRate;

  ProductSellerModel({
    this.id = '',
    required this.shopName,
    this.slug = '',
    this.avatar = '',
    this.rating = 0.0,
    this.reviewsCount = '',
    this.location = '',
    this.isVerified = false,
    this.joinedDate = '',
    this.bio = '',
    this.responseRate = '',
  });

  factory ProductSellerModel.fromJson(Map<String, dynamic> json) {
    return ProductSellerModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ??
          json['storeName']?.toString() ??
          json['name']?.toString() ??
          'Alif Official Store',
      slug: json['slug']?.toString() ?? '',
      avatar: json['avatar']?.toString() ??
          json['logoUrl']?.toString() ??
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=200&auto=format&fit=crop',
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 0.0,
      reviewsCount: json['reviewsCount']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      isVerified: json['isVerified'] == true || json['verified'] == true,
      joinedDate: json['joinedDate']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      responseRate: json['responseRate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'slug': slug,
      'avatar': avatar,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'location': location,
      'isVerified': isVerified,
      'joinedDate': joinedDate,
      'bio': bio,
      'responseRate': responseRate,
    };
  }
}
