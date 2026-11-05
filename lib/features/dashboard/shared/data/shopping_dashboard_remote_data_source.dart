import '../../../../core/services/api_client.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/services/harvest_batches_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/product_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../authentication/domain/entities/user.dart';
import '../models/shopping_dashboard_models.dart';

class ShoppingDashboardRemoteDataSource {
  ShoppingDashboardRemoteDataSource({
    ProductService? products,
    CategoryService? categories,
    HarvestBatchesService? harvestBatches,
    OrderService? orders,
    NotificationService? notifications,
    ProfileService? profiles,
  }) : _products = products ?? ProductService(),
       _categories = categories ?? CategoryService(),
       _harvestBatches = harvestBatches ?? HarvestBatchesService(),
       _orders = orders ?? OrderService(),
       _notifications = notifications ?? NotificationService(),
       _profiles = profiles ?? ProfileService();

  final ProductService _products;
  final CategoryService _categories;
  final HarvestBatchesService _harvestBatches;
  final OrderService _orders;
  final NotificationService _notifications;
  final ProfileService _profiles;
  static const _pageSize = 500;

  Future<ShoppingDashboardData> load(AuthUser user) async {
    final isBusinessBuyer = user.role == 'business_buyer';
    final results = await Future.wait<dynamic>([
      _loadAll((offset, limit) => _products.list(offset: offset, limit: limit)),
      _loadAll(
        (offset, limit) => _categories.list(offset: offset, limit: limit),
      ),
      _loadAll((offset, limit) => _orders.list(offset: offset, limit: limit)),
      _loadAll(
        (offset, limit) => _notifications.list(offset: offset, limit: limit),
      ),
      if (isBusinessBuyer)
        _loadAll(
          (offset, limit) => _harvestBatches.list(offset: offset, limit: limit),
        ),
      if (isBusinessBuyer) _loadBusinessProfile(),
    ]);

    final products = (results[0] as List<Map<String, dynamic>>)
        .map(MarketProduct.fromJson)
        .where(
          (product) =>
              product.status == 'active' && product.availableQuantity > 0,
        )
        .toList();
    final categories = (results[1] as List<Map<String, dynamic>>)
        .map(MarketCategory.fromJson)
        .toList();
    final orders = (results[2] as List<Map<String, dynamic>>)
        .map(ShoppingOrder.fromJson)
        .where((order) => order.buyerId == user.id)
        .toList();
    final notifications = (results[3] as List<Map<String, dynamic>>)
        .map(ShoppingNotification.fromJson)
        .toList();
    final batches = isBusinessBuyer
        ? (results[4] as List<Map<String, dynamic>>)
              .map(AvailableHarvestBatch.fromJson)
              .where(
                (batch) =>
                    batch.status == 'available' && batch.remainingQuantity > 0,
              )
              .toList()
        : <AvailableHarvestBatch>[];
    final profileJson = isBusinessBuyer
        ? results[5] as Map<String, dynamic>?
        : null;

    return ShoppingDashboardData(
      user: user,
      products: products,
      categories: categories,
      orders: orders,
      notifications: notifications,
      batches: batches,
      businessProfile: profileJson == null
          ? null
          : BusinessProfileData.fromJson(profileJson),
    );
  }

  Future<void> markNotificationRead(int id) async {
    await _notifications.update(id, {'is_read': 'read'});
  }

  Future<ShoppingOrder> createBulkOrder({
    required int productId,
    required int batchId,
    required int quantity,
  }) async {
    final response = await _orders.create({
      'items': [
        {
          'product_id': productId,
          'harvest_batch_id': batchId,
          'quantity': quantity,
        },
      ],
      'fulfillment_status': 'pickup',
    });
    if (response is! Map) {
      throw const FormatException(
        'The server returned an invalid order response.',
      );
    }
    return ShoppingOrder.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Map<String, dynamic>?> _loadBusinessProfile() async {
    try {
      final response = await _profiles.getMyBusinessBuyerProfile();
      if (response is! Map) {
        throw const FormatException(
          'The server returned an invalid business profile.',
        );
      }
      return Map<String, dynamic>.from(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAll(
    Future<dynamic> Function(int offset, int limit) fetch,
  ) async {
    final records = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await fetch(offset, _pageSize);
      if (page is! List) {
        throw const FormatException(
          'The server returned an invalid list response.',
        );
      }
      records.addAll(
        page.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
      );
      if (page.length < _pageSize) return records;
      offset += page.length;
    }
  }
}
