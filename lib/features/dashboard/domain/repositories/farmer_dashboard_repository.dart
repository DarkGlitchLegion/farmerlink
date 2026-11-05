import '../../../authentication/domain/entities/user.dart';
import '../../data/models/dashboard_models.dart';

abstract interface class FarmerDashboardRepository {
  Future<FarmerDashboardData> load(AuthUser user);
}
