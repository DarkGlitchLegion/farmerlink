import '../../domain/entities/user.dart';

class UserModel extends AuthUser {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.role,
    required super.status,
    super.middleName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] as num).toInt(),
    firstName: json['first_name'] as String? ?? '',
    middleName: json['middle_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
    status: json['status'] as String? ?? '',
  );
}
