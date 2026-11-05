class AppValidators {
  static String? required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address.';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    return value.length >= 8 ? null : 'Password must be at least 8 characters.';
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value.trim())
        ? null
        : 'Enter 7 to 15 digits, with an optional leading +.';
  }
}
