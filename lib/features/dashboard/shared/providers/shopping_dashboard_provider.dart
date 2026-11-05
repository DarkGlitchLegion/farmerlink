import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/cache_snapshot_provider.dart';
import '../../../../core/storage/cache_snapshot_store.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../data/shopping_dashboard_remote_data_source.dart';
import '../data/shopping_dashboard_repository_impl.dart';
import '../domain/shopping_dashboard_repository.dart';
import '../models/shopping_dashboard_models.dart';

final shoppingDashboardRemoteDataSourceProvider =
    Provider<ShoppingDashboardRemoteDataSource>(
      (ref) => ShoppingDashboardRemoteDataSource(),
    );

final shoppingDashboardRepositoryProvider =
    Provider<ShoppingDashboardRepository>(
      (ref) => ShoppingDashboardRepositoryImpl(
        ref.watch(shoppingDashboardRemoteDataSourceProvider),
      ),
    );

final shoppingDashboardProvider = StreamProvider.autoDispose
    .family<ShoppingDashboardData, String>((ref, requiredRole) {
      final user = ref.watch(
        authenticationProvider.select((state) => state.user),
      );
      if (user == null ||
          user.role != requiredRole ||
          !const {'buyer', 'business_buyer'}.contains(user.role)) {
        throw StateError('A matching signed-in shopper account is required.');
      }
      final repository = ref.watch(shoppingDashboardRepositoryProvider);
      final cache = ref.watch(cacheSnapshotStoreProvider);
      final scope = CacheScope.user(role: user.role, userId: user.id);
      return cacheFirstRefresh(
        store: cache,
        scope: scope,
        key: 'shopping_dashboard',
        decode: (json) => ShoppingDashboardData.fromJson(
          Map<String, dynamic>.from(json as Map),
          user: user,
        ),
        encode: (data) => data.toJson(),
        fetch: () => repository.load(user),
      );
    });
