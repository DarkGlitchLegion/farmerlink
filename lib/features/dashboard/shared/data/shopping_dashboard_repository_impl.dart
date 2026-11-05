import '../../../authentication/domain/entities/user.dart';
import '../domain/shopping_dashboard_repository.dart';
import '../models/shopping_dashboard_models.dart';
import 'shopping_dashboard_remote_data_source.dart';

class ShoppingDashboardRepositoryImpl implements ShoppingDashboardRepository {
  const ShoppingDashboardRepositoryImpl(this._remote);
  final ShoppingDashboardRemoteDataSource _remote;

  @override
  Future<ShoppingDashboardData> load(AuthUser user) => _remote.load(user);

  @override
  Future<void> markNotificationRead(int notificationId) =>
      _remote.markNotificationRead(notificationId);

  @override
  Future<ShoppingOrder> createBulkOrder({
    required int productId,
    required int batchId,
    required int quantity,
    String fulfillmentStatus = 'pickup',
  }) => _remote.createBulkOrder(
    productId: productId,
    batchId: batchId,
    quantity: quantity,
    fulfillmentStatus: fulfillmentStatus,
  );
}
