import 'permission_exception.dart';
import 'user_role.dart';

/// Frontend request gate. Resource ownership remains enforced by the API.
class ApiPermissionChecker {
  const ApiPermissionChecker();

  static const _public = <String>{
    'POST /auth/register',
    'POST /auth/register/base64',
    'POST /auth/login',
    'GET /categories',
    'GET /categories/{id}',
    'GET /products',
    'GET /products/{id}',
    'GET /harvest-batches',
    'GET /harvest-batches/{id}',
    'GET /market-prices',
    'GET /market-prices/{id}',
    'GET /advisories',
    'GET /advisories/{id}',
  };

  static const _admin = <String>{
    'GET /users',
    'POST /users',
    'GET /users/{id}',
    'PATCH /users/{id}',
    'DELETE /users/{id}',
    'POST /categories',
    'PATCH /categories/{id}',
    'DELETE /categories/{id}',
    'POST /products',
    'PATCH /products/{id}',
    'DELETE /products/{id}',
    'POST /harvest-batches',
    'PATCH /harvest-batches/{id}',
    'DELETE /harvest-batches/{id}',
    'POST /market-prices',
    'PATCH /market-prices/{id}',
    'DELETE /market-prices/{id}',
    'POST /advisories',
    'PATCH /advisories/{id}',
    'DELETE /advisories/{id}',
    'GET /farmer-profiles',
    'POST /farmer-profiles',
    'GET /farmer-profiles/{id}',
    'PATCH /farmer-profiles/{id}',
    'DELETE /farmer-profiles/{id}',
    'GET /business-buyer-profiles',
    'POST /business-buyer-profiles',
    'GET /business-buyer-profiles/{id}',
    'PATCH /business-buyer-profiles/{id}',
    'DELETE /business-buyer-profiles/{id}',
    'GET /crop-reports',
    'POST /crop-reports',
    'GET /crop-reports/{id}',
    'PATCH /crop-reports/{id}',
    'DELETE /crop-reports/{id}',
    'GET /notifications',
    'POST /notifications',
    'GET /notifications/{id}',
    'PATCH /notifications/{id}',
    'DELETE /notifications/{id}',
    'GET /orders',
    'GET /orders/{id}',
    'PATCH /orders/{id}',
    'GET /orders/{id}/items',
    'GET /order-items/{id}',
  };

  static const _farmer = <String>{
    'POST /products',
    'PATCH /products/{id}',
    'DELETE /products/{id}',
    'POST /harvest-batches',
    'PATCH /harvest-batches/{id}',
    'DELETE /harvest-batches/{id}',
    'GET /farmer-profiles/me',
    'POST /farmer-profiles',
    'GET /farmer-profiles/{id}',
    'PATCH /farmer-profiles/{id}',
    'DELETE /farmer-profiles/{id}',
    'GET /crop-reports',
    'POST /crop-reports',
    'GET /crop-reports/{id}',
    'GET /orders',
    'GET /orders/{id}',
    'PATCH /orders/{id}',
    'GET /orders/{id}/items',
    'GET /order-items/{id}',
    'GET /notifications',
    'GET /notifications/{id}',
    'PATCH /notifications/{id}',
  };

  static const _buyer = <String>{
    'POST /orders',
    'GET /orders',
    'GET /orders/{id}',
    'PATCH /orders/{id}',
    'GET /orders/{id}/items',
    'GET /order-items/{id}',
    'GET /notifications',
    'GET /notifications/{id}',
    'PATCH /notifications/{id}',
  };

  static const _businessBuyer = <String>{
    ..._buyer,
    'GET /business-buyer-profiles/me',
    'POST /business-buyer-profiles',
    'GET /business-buyer-profiles/{id}',
    'PATCH /business-buyer-profiles/{id}',
    'DELETE /business-buyer-profiles/{id}',
  };

  void check({
    required String method,
    required String path,
    required String? token,
    required UserRole? role,
    int? authenticatedUserId,
    Object? body,
  }) {
    final normalized = _normalizePath(path);
    final verb = method.toUpperCase();
    if (_matches(_public, verb, normalized)) return;
    // Session restoration must verify the stored token with /users/me before
    // the server has returned the authoritative role.
    if (normalized == '/users/me' &&
        verb == 'GET' &&
        token != null &&
        token.isNotEmpty) {
      return;
    }
    if (token == null || token.isEmpty || role == null) {
      throw const PermissionException(
        'Sign in with a recognized account to access this endpoint.',
        statusCode: 401,
      );
    }

    final rules = switch (role) {
      UserRole.admin => _admin,
      UserRole.farmer => _farmer,
      UserRole.buyer => _buyer,
      UserRole.businessBuyer => _businessBuyer,
    };
    final shared = <String>{'GET /users/me'};
    if (!_matches(rules, verb, normalized) &&
        !_matches(shared, verb, normalized)) {
      throw PermissionException(
        '${role.apiValue} is not allowed to $verb $normalized.',
      );
    }
    _checkOperation(role, verb, normalized, body, authenticatedUserId);
  }

  String _normalizePath(String path) {
    var result = Uri.parse(path).path;
    final apiPrefix = RegExp(r'^/api/v\d+');
    result = result.replaceFirst(apiPrefix, '');
    if (!result.startsWith('/')) result = '/$result';
    return result.replaceAll(RegExp(r'/+$'), '').isEmpty
        ? '/'
        : result.replaceAll(RegExp(r'/+$'), '');
  }

  bool _matches(Set<String> rules, String method, String path) =>
      rules.any((rule) {
        final split = rule.split(' ');
        if (split[0] != method) return false;
        final patternSource = RegExp.escape(split[1])
            .replaceAll(r'\{id\}', r'\d+');
        final pattern = RegExp(
          '^$patternSource/?'
          r'$',
        );
        return pattern.hasMatch(path);
      });

  void _checkOperation(
    UserRole role,
    String method,
    String path,
    Object? body,
    int? authenticatedUserId,
  ) {
    if (method == 'PATCH' &&
        path.startsWith('/notifications/') &&
        (role == UserRole.farmer ||
            role == UserRole.buyer ||
            role == UserRole.businessBuyer) &&
        (body is! Map || body.length != 1 || body['is_read'] != 'read')) {
      throw const PermissionException(
        'Users may only mark their own notification as read.',
      );
    }

    if (method == 'PATCH' && path.startsWith('/orders/')) {
      final status = body is Map ? body['status'] : null;
      if (role == UserRole.buyer || role == UserRole.businessBuyer) {
        if (body is! Map || body.length != 1 || status != 'cancelled') {
          throw const PermissionException(
            'Buyers may only cancel an order with status=cancelled.',
          );
        }
      } else if (role == UserRole.farmer &&
          (body is! Map ||
              body.length != 1 ||
              !const {
                'confirmed',
                'processing',
                'shipped',
                'delivered',
              }.contains(status))) {
        throw const PermissionException(
          'Farmers may only set the supported order fulfillment statuses.',
        );
      }
    }

    if (body is! Map) return;
    final keys = body.keys.map((key) => key.toString()).toSet();
    final forbidden = <String>{};
    if (role == UserRole.farmer) {
      if (path == '/products' && method == 'POST') {
        if (body['farmer_id'] != authenticatedUserId ||
            authenticatedUserId == null) {
          throw const PermissionException(
            'Product creation must use the authenticated farmer ID required by the API schema.',
          );
        }
      } else if (path == '/products' || path.startsWith('/products/')) {
        forbidden.add('farmer_id');
      }
      if (path == '/harvest-batches' && method == 'POST') {
        if (body['farmer_id'] != authenticatedUserId ||
            authenticatedUserId == null) {
          throw const PermissionException(
            'Harvest batch creation must use the authenticated farmer ID required by the API schema.',
          );
        }
      } else if (path == '/harvest-batches' ||
          path.startsWith('/harvest-batches/')) {
        forbidden.addAll({'farmer_id', 'product_id'});
      }
      if (path == '/farmer-profiles' || path.startsWith('/farmer-profiles/')) {
        forbidden.addAll({'user_id', 'verification_status'});
      }
      if (path == '/crop-reports' || path.startsWith('/crop-reports/')) {
        forbidden.add('farmer_id');
      }
    }
    if (role == UserRole.businessBuyer &&
        path.startsWith('/business-buyer-profiles')) {
      forbidden.addAll({'user_id', 'verification_status'});
    }
    final supplied = keys.intersection(forbidden);
    if (supplied.isNotEmpty) {
      throw PermissionException(
        'The API assigns these protected fields: ${supplied.join(', ')}.',
      );
    }
  }
}
