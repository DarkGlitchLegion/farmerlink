class PermissionException implements Exception {
  const PermissionException(this.message, {this.statusCode = 403});

  final String message;
  final int statusCode;

  @override
  String toString() => 'PermissionException($statusCode): $message';
}
