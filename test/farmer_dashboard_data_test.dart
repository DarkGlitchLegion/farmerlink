import 'dart:convert';

import 'package:farmerlink/core/services/api_client.dart';
import 'package:farmerlink/core/services/harvest_batches_service.dart';
import 'package:farmerlink/core/services/order_service.dart';
import 'package:farmerlink/core/services/product_service.dart';
import 'package:farmerlink/core/services/profile_service.dart';
import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const user = AuthUser(
    id: 12,
    firstName: 'Ana',
    lastName: 'Santos',
    email: 'ana@example.com',
    role: 'farmer',
    status: 'active',
  );

  test(
    'maps only this farmer’s available batches and paid monthly orders',
    () async {
      final requests = <String>[];
      final now = DateTime.now();
      final client = _client((request) {
        requests.add(request.url.path);
        switch (request.url.path) {
          case '/api/v1/farmer-profiles/me':
            return _json({
              'id': 3,
              'user_id': 12,
              'farm_name': 'Ana’s Farm',
              'farm_address': 'North Road',
              'municipality': 'Tagum City',
              'province': 'Davao del Norte',
              'farm_size': 4,
              'farming_type': 'mixed',
              'verification_status': 'approved',
            });
          case '/api/v1/harvest-batches':
            return _json([
              _batch(id: 1, farmerId: 12, productId: 7),
              _batch(id: 2, farmerId: 99, productId: 8),
            ]);
          case '/api/v1/products':
            return _json([
              {
                'id': 7,
                'farmer_id': 12,
                'name': 'Tomato',
                'unit': 'kg',
                'price_per_unit': 85,
              },
              {
                'id': 8,
                'farmer_id': 99,
                'name': 'Other farm crop',
                'unit': 'kg',
                'price_per_unit': 1,
              },
            ]);
          case '/api/v1/orders':
            return _json([
              _order(
                farmerId: 12,
                total: 1200,
                payment: 'paid',
                status: 'delivered',
                created: now,
              ),
              _order(
                farmerId: 12,
                total: 800,
                payment: 'unpaid',
                status: 'pending',
                created: now,
              ),
              _order(
                farmerId: 12,
                total: 600,
                payment: 'paid',
                status: 'delivered',
                created: DateTime(now.year, now.month - 1, 12),
              ),
              _order(
                farmerId: 99,
                total: 9900,
                payment: 'paid',
                status: 'pending',
                created: now,
              ),
            ]);
          default:
            return http.Response('{}', 404);
        }
      });
      final api = ApiClient(client: client);
      final data = await _source(api).load(user);

      expect(data.profile?.farmName, 'Ana’s Farm');
      expect(data.availableBatches.map((batch) => batch.id), [1]);
      expect(data.productsById[7]?.name, 'Tomato');
      expect(data.orders, hasLength(3));
      expect(data.monthlyPaidRevenue(now: now), 1200);
      expect(data.pendingOrders, 1);
      expect(requests.toSet(), {
        '/api/v1/farmer-profiles/me',
        '/api/v1/harvest-batches',
        '/api/v1/products',
        '/api/v1/orders',
      });
    },
  );

  test(
    'accepts an uncreated farmer profile and empty API collections',
    () async {
      final client = _client((request) {
        if (request.url.path == '/api/v1/farmer-profiles/me') {
          return _json({'detail': 'Farmer profile not found'}, 404);
        }
        return _json(<dynamic>[]);
      });
      final data = await _source(ApiClient(client: client)).load(user);

      expect(data.profile, isNull);
      expect(data.availableBatches, isEmpty);
      expect(data.productsById, isEmpty);
      expect(data.orders, isEmpty);
      expect(data.monthlyPaidRevenue(), 0);
      expect(data.pendingOrders, 0);
    },
  );

  test(
    'propagates an expired-session response from protected orders endpoint',
    () async {
      final client = _client((request) {
        if (request.url.path == '/api/v1/farmer-profiles/me') {
          return _json({'detail': 'No farmer profile'}, 404);
        }
        if (request.url.path == '/api/v1/orders') {
          return _json({'detail': 'Not authenticated'}, 401);
        }
        return _json(<dynamic>[]);
      });

      await expectLater(
        _source(ApiClient(client: client)).load(user),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    },
  );
}

DashboardRemoteDataSource _source(ApiClient api) => DashboardRemoteDataSource(
  harvestBatches: HarvestBatchesService(api: api),
  products: ProductService(api: api),
  orders: OrderService(api: api),
  profiles: ProfileService(api: api),
);

MockClient _client(http.Response Function(http.Request) handler) =>
    MockClient((request) async => handler(request));

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _batch({
  required int id,
  required int farmerId,
  required int productId,
}) => {
  'id': id,
  'farmer_id': farmerId,
  'product_id': productId,
  'batch_code': 'FL-$id',
  'harvest_date': '2026-11-01T08:00:00',
  'available_date': '2026-11-02T08:00:00',
  'quantity': 100,
  'remaining_quantity': 75,
  'expected_expiration_date': '2026-11-20T08:00:00',
  'harvest_location': 'Tagum City',
  'status': 'available',
};

Map<String, dynamic> _order({
  required int farmerId,
  required int total,
  required String payment,
  required String status,
  required DateTime created,
}) => {
  'id': total,
  'farmer_id': farmerId,
  'buyer_id': 2,
  'order_number': 'FL-$total',
  'subtotal': total,
  'total_amount': total,
  'status': status,
  'payment_status': payment,
  'fulfillment_status': 'pickup',
  'delivery_address': null,
  'notes': null,
  'created_at': created.toIso8601String(),
  'updated_at': created.toIso8601String(),
};
