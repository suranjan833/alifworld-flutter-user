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
    this.rating = 4.9,
    this.reviewsCount = '1.8k',
    this.location = 'Dhaka, Bangladesh',
    this.isVerified = true,
    this.joinedDate = 'Verified Seller',
    this.bio =
        'Official retailer on Alif offering 100% authentic products with brand warranty and fast delivery.',
    this.responseRate = '99%',
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
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 4.9,
      reviewsCount: json['reviewsCount']?.toString() ?? '1.8k',
      location: json['location']?.toString() ?? 'Dhaka, Bangladesh',
      isVerified: json['isVerified'] == true || json['verified'] == true,
      joinedDate: json['joinedDate']?.toString() ?? 'Verified Seller',
      bio: json['bio']?.toString() ??
          'Official retailer on Alif offering 100% authentic products with brand warranty and fast delivery.',
      responseRate: json['responseRate']?.toString() ?? '99%',
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
