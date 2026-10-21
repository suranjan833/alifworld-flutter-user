import 'user_model.dart';

class AuthResponseModel {
  final String? token;
  final String? tokenType;
  final int? expiresIn;
  final UserModel? user;
  final String? message;

  AuthResponseModel({
    this.token,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    String? extractedToken = json['token']?.toString() ??
        json['accessToken']?.toString() ??
        json['access_token']?.toString() ??
        json['authtoken']?.toString();

    UserModel? userObj;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      userObj = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['profile'] != null && json['profile'] is Map<String, dynamic>) {
      userObj = UserModel.fromJson(json['profile'] as Map<String, dynamic>);
    }

    return AuthResponseModel(
      token: extractedToken,
      tokenType: json['tokenType']?.toString() ?? json['token_type']?.toString() ?? 'Bearer',
      expiresIn: json['expiresIn'] is int ? json['expiresIn'] : int.tryParse(json['expiresIn']?.toString() ?? ''),
      user: userObj,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'user': user?.toJson(),
      'message': message,
    };
  }
}
