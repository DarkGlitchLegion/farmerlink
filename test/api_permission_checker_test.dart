import 'package:farmerlink/core/permissions/api_permission_checker.dart';
import 'package:farmerlink/core/permissions/permission_exception.dart';
import 'package:farmerlink/core/permissions/user_role.dart';
import 'package:farmerlink/core/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const checker = ApiPermissionChecker();
  const token = 'test-token';

  void allow(UserRole role, String method, String path, {Object? body}) =>
      checker.check(
        method: method,
        path: path,
        token: token,
        role: role,
        authenticatedUserId: 12,
        body: body,
      );

  void deny(UserRole role, String method, String path, {Object? body}) {
    expect(
      () => allow(role, method, path, body: body),
      throwsA(isA<PermissionException>()),
      reason: '${role.apiValue} should be blocked from $method $path',
    );
  }

  test('public catalog and authentication routes work without a session', () {
    for (final entry in const [
      ('GET', '/api/v1/products'),
      ('GET', '/api/v1/products/12'),
      ('GET', '/api/v1/harvest-batches/3'),
      ('GET', '/api/v1/advisories'),
      ('POST', '/api/v1/auth/login'),
    ]) {
      checker.check(method: entry.$1, path: entry.$2, token: null, role: null);
    }
  });

  test(
    'admin can administer resources and read all orders but cannot place one',
    () {
      allow(UserRole.admin, 'GET', '/users');
      allow(UserRole.admin, 'DELETE', '/products/42');
      allow(UserRole.admin, 'POST', '/harvest-batches');
      allow(UserRole.admin, 'GET', '/orders/8/items');
      deny(UserRole.admin, 'POST', '/orders');
    },
  );

  test(
    'farmers can manage farm resources but not admin or report moderation',
    () {
      allow(
        UserRole.farmer,
        'POST',
        '/products',
        body: {'name': 'Corn', 'farmer_id': 12},
      );
      allow(
        UserRole.farmer,
        'POST',
        '/harvest-batches',
        body: {'batch_code': 'A-1', 'farmer_id': 12, 'product_id': 5},
      );
      allow(
        UserRole.farmer,
        'POST',
        '/crop-reports',
        body: {'crop_name': 'Corn', 'farmer_id': 12},
      );
      allow(UserRole.farmer, 'GET', '/orders');
      allow(
        UserRole.farmer,
        'PATCH',
        '/orders/12',
        body: {'status': 'processing'},
      );
      deny(UserRole.farmer, 'GET', '/users');
      deny(UserRole.farmer, 'PATCH', '/crop-reports/7');
      deny(
        UserRole.farmer,
        'PATCH',
        '/orders/12',
        body: {'status': 'cancelled'},
      );
      deny(UserRole.farmer, 'POST', '/products', body: {'farmer_id': 99});
      deny(
        UserRole.farmer,
        'POST',
        '/harvest-batches',
        body: {'product_id': 4},
      );
    },
  );

  test(
    'buyers may order, cancel, and read notices but cannot manage catalog',
    () {
      allow(UserRole.buyer, 'POST', '/orders', body: {'items': []});
      allow(
        UserRole.buyer,
        'PATCH',
        '/orders/9',
        body: {'status': 'cancelled'},
      );
      allow(
        UserRole.buyer,
        'PATCH',
        '/notifications/6',
        body: {'is_read': 'read'},
      );
      deny(
        UserRole.buyer,
        'PATCH',
        '/notifications/6',
        body: {'is_read': 'unread'},
      );
      deny(UserRole.buyer, 'PATCH', '/orders/9', body: {'status': 'delivered'});
      deny(UserRole.buyer, 'POST', '/products');
      deny(UserRole.buyer, 'POST', '/notifications');
    },
  );

  test('business buyers have buyer access and only safe profile payloads', () {
    allow(UserRole.businessBuyer, 'GET', '/business-buyer-profiles/me');
    allow(
      UserRole.businessBuyer,
      'POST',
      '/business-buyer-profiles',
      body: {'business_name': 'Market'},
    );
    deny(
      UserRole.businessBuyer,
      'PATCH',
      '/business-buyer-profiles/5',
      body: {'verification_status': 'approved'},
    );
    deny(
      UserRole.businessBuyer,
      'PATCH',
      '/business-buyer-profiles/5',
      body: {'user_id': 1},
    );
    deny(UserRole.businessBuyer, 'GET', '/farmer-profiles/me');
  });

  test('unknown role and missing authentication fail closed', () {
    expect(UserRole.tryParse('superuser'), isNull);
    expect(
      () => checker.check(
        method: 'GET',
        path: '/orders',
        token: token,
        role: null,
      ),
      throwsA(isA<PermissionException>()),
    );
    expect(
      () => checker.check(
        method: 'GET',
        path: '/orders',
        token: null,
        role: UserRole.buyer,
      ),
      throwsA(isA<PermissionException>()),
    );
  });

  test('denied service calls never reach the HTTP client', () {
    var requests = 0;
    final api = ApiClient(
      client: MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      }),
      token: token,
      role: UserRole.buyer,
    );
    expect(
      () => api.post('/orders/9', body: {}),
      throwsA(isA<PermissionException>()),
    );
    expect(
      () => api.post('/products', body: {}),
      throwsA(isA<PermissionException>()),
    );
    expect(requests, 0);
  });

  test('401 responses notify the authentication session handler', () async {
    var cleared = false;
    final api = ApiClient(
      client: MockClient(
        (request) async => http.Response('{"detail":"expired"}', 401),
      ),
      token: token,
      role: UserRole.buyer,
    )..onUnauthorized = () async => cleared = true;

    await expectLater(
      api.get('/orders'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(cleared, isTrue);
  });
}
