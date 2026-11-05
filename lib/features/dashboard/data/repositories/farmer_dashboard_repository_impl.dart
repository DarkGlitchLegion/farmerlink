import '../../../authentication/domain/entities/user.dart';
import '../../domain/repositories/farmer_dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_models.dart';

class FarmerDashboardRepositoryImpl implements FarmerDashboardRepository {
  const FarmerDashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<FarmerDashboardData> load(AuthUser user) => _remote.load(user);
}
