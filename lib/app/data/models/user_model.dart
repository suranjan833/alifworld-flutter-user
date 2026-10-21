class UserModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? role;
  final String? status;
  final String? gender;
  final String? dateOfBirth;
  final String? sellerStatus;
  final String? riderStatus;
  final String? referralCode;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.role,
    this.status,
    this.gender,
    this.dateOfBirth,
    this.sellerStatus,
    this.riderStatus,
    this.referralCode,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    final parts = [firstName, lastName]
        .where((s) => s != null && s.toString().trim().isNotEmpty)
        .join(' ');
    if (parts.isNotEmpty) return parts;
    if (phone != null && phone!.trim().isNotEmpty) return phone!.trim();
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    return 'User';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final first = json['firstName']?.toString();
    final last = json['lastName']?.toString();
    final constructedName = [first, last]
        .where((s) => s != null && s.toString().trim().isNotEmpty)
        .join(' ');

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      firstName: first,
      lastName: last,
      name: (json['name']?.toString() ?? json['fullName']?.toString()) ??
          (constructedName.isNotEmpty ? constructedName : null),
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      avatar: json['avatar']?.toString() ??
          json['profileImage']?.toString() ??
          json['avatarUrl']?.toString(),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString() ?? json['dob']?.toString(),
      sellerStatus: json['sellerStatus']?.toString(),
      riderStatus: json['riderStatus']?.toString(),
      referralCode: json['referralCode']?.toString() ??
          json['referral_code']?.toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'status': status,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'sellerStatus': sellerStatus,
      'riderStatus': riderStatus,
      'referralCode': referralCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
