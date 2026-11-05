import '../../../authentication/domain/entities/user.dart';
import '../models/shopping_dashboard_models.dart';

abstract interface class ShoppingDashboardRepository {
  Future<ShoppingDashboardData> load(AuthUser user);
  Future<void> markNotificationRead(int notificationId);
  Future<ShoppingOrder> createBulkOrder({
    required int productId,
    required int batchId,
    required int quantity,
    String fulfillmentStatus = 'pickup',
  });
}
