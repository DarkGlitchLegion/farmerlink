import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/cache_snapshot_provider.dart';
import '../../../../core/storage/cache_snapshot_store.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/farmer_dashboard_repository_impl.dart';
import '../../domain/repositories/farmer_dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(),
);

final farmerDashboardRepositoryProvider = Provider<FarmerDashboardRepository>(
  (ref) => FarmerDashboardRepositoryImpl(
    ref.watch(dashboardRemoteDataSourceProvider),
  ),
);

final farmerDashboardProvider = StreamProvider.autoDispose<FarmerDashboardData>(
  (ref) {
    final user = ref.watch(
      authenticationProvider.select((state) => state.user),
    );
    if (user == null || user.role != 'farmer') {
      throw StateError('A signed-in farmer account is required.');
    }
    final repository = ref.watch(farmerDashboardRepositoryProvider);
    final cache = ref.watch(cacheSnapshotStoreProvider);
    final scope = CacheScope.user(role: user.role, userId: user.id);
    return cacheFirstRefresh(
      store: cache,
      scope: scope,
      key: 'farmer_dashboard',
      decode: (json) => FarmerDashboardData.fromJson(
        Map<String, dynamic>.from(json as Map),
        user: user,
      ),
      encode: (data) => data.toJson(),
      fetch: () => repository.load(user),
    );
  },
);
