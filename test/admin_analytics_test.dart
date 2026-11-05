import 'dart:convert';

import 'package:farmerlink/core/permissions/permission_exception.dart';
import 'package:farmerlink/core/permissions/user_role.dart';
import 'package:farmerlink/core/services/api_client.dart';
import 'package:farmerlink/features/admin/data/services/admin_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'analytics service uses the shared admin client and maps API fields',
    () async {
      late http.Request captured;
      final client = ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(_response), 200);
        }),
        baseUrl: 'http://farmerlink.test/api/v1',
        token: 'admin-token',
        role: UserRole.admin,
        currentUserId: 1,
      );

      final result = await AdminAnalyticsService(api: client).getOverview();

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/analytics/overview');
      expect(captured.headers['authorization'], 'Bearer admin-token');
      expect(result.users.total, 42);
      expect(result.users.byRole['farmer'], 20);
      expect(result.catalog.availableHarvestQuantity, 83);
      expect(result.orders.byStatus['delivered'], 12);
      expect(result.profiles.farmerProfilesByVerification['pending'], 3);
      expect(result.cropReports.bySeverity['critical'], 1);
      expect(result.topDeliveredProducts.single.productName, 'Tomato');
      expect(result.topDeliveredProducts.single.quantityDelivered, 50);
    },
  );

  test('analytics endpoint is rejected locally for non-admin roles', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'http://farmerlink.test/api/v1',
      token: 'farmer-token',
      role: UserRole.farmer,
      currentUserId: 2,
    );

    expect(
      AdminAnalyticsService(api: client).getOverview(),
      throwsA(isA<PermissionException>()),
    );
  });
}

const _response = {
  'generated_at': '2026-11-05T08:00:00Z',
  'users': {
    'total': 42,
    'by_role': {'admin': 1, 'farmer': 20, 'buyer': 15, 'business_buyer': 6},
    'by_status': {'active': 40, 'pending': 2},
  },
  'catalog': {
    'categories_total': 5,
    'products_total': 18,
    'products_by_status': {'active': 15, 'archived': 3},
    'active_products': 15,
    'active_product_quantity': 205,
    'harvest_batches_total': 14,
    'available_harvest_batches': 8,
    'available_harvest_quantity': 83,
    'market_prices_total': 10,
    'published_advisories': 4,
  },
  'orders': {
    'total': 24,
    'by_status': {'pending': 2, 'delivered': 12, 'cancelled': 1},
    'by_payment_status': {'paid': 14, 'unpaid': 10},
    'open_orders': 11,
    'delivered_orders': 12,
    'cancelled_orders': 1,
    'paid_orders': 14,
    'paid_sales_total': 56000,
    'average_paid_order_total': 4000.0,
  },
  'profiles': {
    'farmer_profiles_total': 20,
    'farmer_profiles_by_verification': {'pending': 3, 'approved': 17},
    'business_buyer_profiles_total': 6,
    'business_buyer_profiles_by_verification': {'pending': 1, 'approved': 5},
  },
  'crop_reports': {
    'total': 8,
    'by_status': {'submitted': 4, 'reviewing': 3, 'resolved': 1},
    'by_severity': {'low': 2, 'medium': 4, 'critical': 1, 'high': 1},
    'critical_reports': 1,
  },
  'top_delivered_products': [
    {
      'product_id': 3,
      'product_name': 'Tomato',
      'quantity_delivered': 50,
      'delivered_sales_total': 5000,
    },
  ],
};
