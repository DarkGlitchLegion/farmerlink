import 'user_model.dart';

class AuthenticationResponseModel {
  const AuthenticationResponseModel({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final int expiresIn;
  final UserModel user;

  factory AuthenticationResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (json['access_token'] is! String || userJson is! Map) {
      throw const FormatException(
        'The server returned an invalid login response.',
      );
    }
    return AuthenticationResponseModel(
      accessToken: json['access_token'] as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      user: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }
}
