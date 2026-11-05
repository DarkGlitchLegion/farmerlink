class RegisterRequestModel {
  const RegisterRequestModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String role;

  Map<String, String> toFields() => {
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'password': password,
    'role': role,
  };
}
