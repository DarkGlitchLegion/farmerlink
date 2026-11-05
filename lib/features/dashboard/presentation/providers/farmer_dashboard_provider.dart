import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final farmerDashboardProvider = FutureProvider.autoDispose<FarmerDashboardData>(
  (ref) {
    final user = ref.watch(
      authenticationProvider.select((state) => state.user),
    );
    if (user == null || user.role != 'farmer') {
      throw StateError('A signed-in farmer account is required.');
    }
    return ref.watch(farmerDashboardRepositoryProvider).load(user);
  },
);
