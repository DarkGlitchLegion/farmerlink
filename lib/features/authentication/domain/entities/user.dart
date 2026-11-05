class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.middleName = '',
  });

  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String role;
  final String status;

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');
}
