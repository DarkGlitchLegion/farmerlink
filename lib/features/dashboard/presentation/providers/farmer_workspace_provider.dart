import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/services/harvest_batches_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/product_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';

class FarmerWorkspaceData {
  const FarmerWorkspaceData({
    required this.products,
    required this.categories,
    required this.batches,
    required this.orders,
    required this.notifications,
    required this.profile,
  });

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic>? profile;
}

final farmerWorkspaceProvider = FutureProvider.autoDispose<FarmerWorkspaceData>(
  (ref) async {
    final auth = ref.watch(authenticationProvider);
    final user = auth.user;
    if (!auth.isAuthenticated || user == null || user.role != 'farmer') {
      throw StateError('A signed-in farmer account is required.');
    }

    final productsApi = ProductService();
    final categoriesApi = CategoryService();
    final batchesApi = HarvestBatchesService();
    final ordersApi = OrderService();
    final notificationsApi = NotificationService();
    final profilesApi = ProfileService();
    final results = await Future.wait<dynamic>([
      productsApi.list(limit: 500),
      categoriesApi.list(limit: 500),
      batchesApi.list(limit: 500),
      ordersApi.list(limit: 500),
      notificationsApi.list(limit: 500),
      _myProfile(profilesApi),
    ]);
    final products = _maps(results[0])
        .where((row) => row['farmer_id'] == user.id)
        .toList();
    final batches = _maps(results[2])
        .where((row) => row['farmer_id'] == user.id)
        .toList();
    final orders = _maps(results[3])
        .where((row) => row['farmer_id'] == user.id)
        .toList();
    return FarmerWorkspaceData(
      products: products,
      categories: _maps(results[1]),
      batches: batches,
      orders: orders,
      notifications: _maps(results[4]),
      profile: results[5] as Map<String, dynamic>?,
    );
  },
);

Future<Map<String, dynamic>?> _myProfile(ProfileService service) async {
  try {
    final result = await service.getMyFarmerProfile();
    return result is Map ? Map<String, dynamic>.from(result) : null;
  } on ApiException catch (error) {
    if (error.statusCode == 404) return null;
    rethrow;
  }
}

List<Map<String, dynamic>> _maps(dynamic result) {
  if (result is! List) {
    throw const FormatException('The server returned an invalid list.');
  }
  return result
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}
