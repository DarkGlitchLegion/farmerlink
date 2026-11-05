import '../../../../core/services/api_client.dart';
import '../../../../core/services/harvest_batches_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/product_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../authentication/domain/entities/user.dart';
import '../models/dashboard_models.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource({
    HarvestBatchesService? harvestBatches,
    ProductService? products,
    OrderService? orders,
    ProfileService? profiles,
  }) : _harvestBatches = harvestBatches ?? HarvestBatchesService(),
       _products = products ?? ProductService(),
       _orders = orders ?? OrderService(),
       _profiles = profiles ?? ProfileService();

  final HarvestBatchesService _harvestBatches;
  final ProductService _products;
  final OrderService _orders;
  final ProfileService _profiles;

  static const _pageSize = 500;

  Future<FarmerDashboardData> load(AuthUser user) async {
    final results = await Future.wait<dynamic>([
      _loadProfile(),
      _loadAll(
        (offset, limit) => _harvestBatches.list(offset: offset, limit: limit),
      ),
      _loadAll((offset, limit) => _products.list(offset: offset, limit: limit)),
      _loadAll((offset, limit) => _orders.list(offset: offset, limit: limit)),
    ]);

    final profileJson = results[0] as Map<String, dynamic>?;
    final batchesJson = results[1] as List<Map<String, dynamic>>;
    final productsJson = results[2] as List<Map<String, dynamic>>;
    final ordersJson = results[3] as List<Map<String, dynamic>>;
    final batches =
        batchesJson
            .map(HarvestBatchData.fromJson)
            .where(
              (batch) =>
                  batch.farmerId == user.id &&
                  batch.status == 'available' &&
                  batch.remainingQuantity > 0,
            )
            .toList()
          ..sort(
            (a, b) => (a.expirationDate ?? DateTime(9999)).compareTo(
              b.expirationDate ?? DateTime(9999),
            ),
          );
    final products = productsJson
        .map(FarmerProductData.fromJson)
        .where(
          (product) =>
              product.farmerId == user.id &&
              batches.any((batch) => batch.productId == product.id),
        )
        .fold<Map<int, FarmerProductData>>({}, (map, product) {
          map[product.id] = product;
          return map;
        });

    return FarmerDashboardData(
      user: user,
      profile: profileJson == null
          ? null
          : FarmerProfileData.fromJson(profileJson),
      availableBatches: List.unmodifiable(batches),
      productsById: Map.unmodifiable(products),
      orders: List.unmodifiable(
        ordersJson
            .map(FarmerOrderData.fromJson)
            .where((order) => order.farmerId == user.id),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    try {
      final response = await _profiles.getMyFarmerProfile();
      if (response is! Map) {
        throw const FormatException(
          'The server returned an invalid farmer profile.',
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
      final mapped = page
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      records.addAll(mapped);
      if (page.length < _pageSize) return records;
      offset += page.length;
    }
  }
}
