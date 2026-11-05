import 'dart:convert';

import 'package:farmerlink/core/services/api_client.dart';
import 'package:farmerlink/core/permissions/user_role.dart';
import 'package:farmerlink/core/services/category_service.dart';
import 'package:farmerlink/core/services/harvest_batches_service.dart';
import 'package:farmerlink/core/services/notification_service.dart';
import 'package:farmerlink/core/services/order_service.dart';
import 'package:farmerlink/core/services/product_service.dart';
import 'package:farmerlink/core/services/profile_service.dart';
import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/dashboard/shared/data/shopping_dashboard_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const buyer = AuthUser(
    id: 12,
    firstName: 'Lia',
    lastName: 'Buyer',
    email: 'lia@example.com',
    role: 'buyer',
    status: 'active',
  );
  const businessBuyer = AuthUser(
    id: 13,
    firstName: 'Ben',
    lastName: 'Business',
    email: 'ben@example.com',
    role: 'business_buyer',
    status: 'active',
  );

  test('buyer dashboard loads only supported buyer endpoints and filters own orders', () async {
    final paths = <String>[];
    final api = ApiClient(
      token: 'buyer-test-token',
      role: UserRole.buyer,
      client: MockClient((request) async {
        paths.add(request.url.path);
        switch (request.url.path) {
          case '/api/v1/products':
            return _json([
              _product(id: 1, farmer: 20, category: 4, name: 'Tomato'),
              _product(
                id: 2,
                farmer: 21,
                category: 4,
                name: 'Draft crop',
                status: 'draft',
              ),
            ]);
          case '/api/v1/categories':
            return _json([
              {
                'id': 4,
                'name': 'Vegetables',
                'description': null,
                'image': null,
              },
            ]);
          case '/api/v1/orders':
            return _json([
              _order(
                id: 1,
                buyer: 12,
                farmer: 20,
                amount: 850,
                status: 'pending',
                payment: 'unpaid',
              ),
              _order(
                id: 2,
                buyer: 99,
                farmer: 21,
                amount: 1200,
                status: 'delivered',
                payment: 'paid',
              ),
            ]);
          case '/api/v1/notifications':
            return _json([_notification(id: 1, user: 12)]);
          default:
            return http.Response('{}', 404);
        }
      }),
    );

    final data = await _source(api).load(buyer);
    expect(data.products.map((product) => product.name), ['Tomato']);
    expect(data.categories.single.name, 'Vegetables');
    expect(data.orders.map((order) => order.buyerId), [12]);
    expect(data.activeOrders, 1);
    expect(data.paidPurchases, 0);
    expect(data.unreadNotifications, 1);
    expect(data.batches, isEmpty);
    expect(paths.toSet(), {
      '/api/v1/products',
      '/api/v1/categories',
      '/api/v1/orders',
      '/api/v1/notifications',
    });
  });

  test('business dashboard loads its profile and available batches for real bulk orders', () async {
    final api = ApiClient(
      token: 'business-test-token',
      role: UserRole.businessBuyer,
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/products':
            return _json([
              _product(id: 5, farmer: 44, category: 2, name: 'Rice'),
            ]);
          case '/api/v1/categories':
          case '/api/v1/orders':
          case '/api/v1/notifications':
            return _json(<dynamic>[]);
          case '/api/v1/harvest-batches':
            return _json([
              _batch(id: 8, product: 5, farmer: 44, remaining: 120),
            ]);
          case '/api/v1/business-buyer-profiles/me':
            return _json({
              'id': 7,
              'user_id': 13,
              'business_name': 'Ben’s Market',
              'business_type': 'retailer',
              'business_address': 'Main Street',
              'business_registration_number': 'REG-13',
              'contact_person': 'Ben Business',
              'province': 'Davao del Norte',
              'verification_status': 'approved',
            });
          default:
            return http.Response('{}', 404);
        }
      }),
    );
    final data = await _source(api).load(businessBuyer);

    expect(data.businessProfile?.businessName, 'Ben’s Market');
    expect(data.businessProfile?.verificationStatus, 'approved');
    expect(data.availableSuppliers, 1);
    expect(data.batches.single.remainingQuantity, 120);
  });

  test(
    'bulk purchase and mark-read use only documented request shapes',
    () async {
      final calls = <http.Request>[];
      final api = ApiClient(
        token: 'business-test-token',
        role: UserRole.businessBuyer,
        client: MockClient((request) async {
          calls.add(request);
          if (request.url.path == '/api/v1/orders') {
            return _json(
              _order(
                id: 31,
                buyer: 13,
                farmer: 44,
                amount: 680,
                status: 'pending',
                payment: 'unpaid',
              ),
            );
          }
          return _json(_notification(id: 90, user: 13));
        }),
      );
      final source = _source(api);

      final order = await source.createBulkOrder(
        productId: 5,
        batchId: 8,
        quantity: 8,
      );
      await source.markNotificationRead(90);

      expect(order.orderNumber, 'FL-31');
      expect(calls[0].method, 'POST');
      expect(calls[0].url.path, '/api/v1/orders');
      expect(jsonDecode(calls[0].body), {
        'items': [
          {'product_id': 5, 'harvest_batch_id': 8, 'quantity': 8},
        ],
        'fulfillment_status': 'pickup',
      });
      expect(calls[1].method, 'PATCH');
      expect(calls[1].url.path, '/api/v1/notifications/90');
      expect(jsonDecode(calls[1].body), {'is_read': 'read'});
    },
  );
}

ShoppingDashboardRemoteDataSource _source(ApiClient api) =>
    ShoppingDashboardRemoteDataSource(
      products: ProductService(api: api),
      categories: CategoryService(api: api),
      harvestBatches: HarvestBatchesService(api: api),
      orders: OrderService(api: api),
      notifications: NotificationService(api: api),
      profiles: ProfileService(api: api),
    );

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _product({
  required int id,
  required int farmer,
  required int category,
  required String name,
  String status = 'active',
}) => {
  'id': id,
  'farmer_id': farmer,
  'category_id': category,
  'name': name,
  'description': null,
  'variety': null,
  'unit': 'kg',
  'price_per_unit': 85,
  'available_quantity': 200,
  'minimum_order_quantity': 5,
  'quality_grade': 'A',
  'status': status,
};

Map<String, dynamic> _order({
  required int id,
  required int buyer,
  required int farmer,
  required int amount,
  required String status,
  required String payment,
}) => {
  'id': id,
  'order_number': 'FL-$id',
  'buyer_id': buyer,
  'farmer_id': farmer,
  'subtotal': amount,
  'total_amount': amount,
  'status': status,
  'payment_status': payment,
  'fulfillment_status': 'pickup',
  'delivery_address': null,
  'notes': null,
  'created_at': '2026-11-05T08:00:00',
  'updated_at': '2026-11-05T08:00:00',
};

Map<String, dynamic> _batch({
  required int id,
  required int product,
  required int farmer,
  required int remaining,
}) => {
  'id': id,
  'farmer_id': farmer,
  'product_id': product,
  'batch_code': 'B-$id',
  'harvest_date': '2026-11-01T08:00:00',
  'available_date': '2026-11-02T08:00:00',
  'quantity': remaining,
  'remaining_quantity': remaining,
  'expected_expiration_date': '2026-11-20T08:00:00',
  'harvest_location': 'Tagum City',
  'status': 'available',
};

Map<String, dynamic> _notification({required int id, required int user}) => {
  'id': id,
  'user_id': user,
  'title': 'Order updated',
  'message': 'Your order status changed.',
  'is_read': 'unread',
  'created_at': '2026-11-05T08:00:00',
  'updated_at': '2026-11-05T08:00:00',
};
