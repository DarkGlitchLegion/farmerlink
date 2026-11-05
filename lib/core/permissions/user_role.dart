/// Roles returned by the FastAPI authentication endpoints.
enum UserRole {
  admin('admin'),
  farmer('farmer'),
  buyer('buyer'),
  businessBuyer('business_buyer');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole? tryParse(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}
