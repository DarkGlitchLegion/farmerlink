import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/providers/authentication_provider.dart';
import '../../features/authentication/domain/entities/user.dart';
import 'cache_snapshot_provider.dart';
import 'cache_snapshot_store.dart';

Future<void> invalidateUserDashboardCache(WidgetRef ref, AuthUser user) async {
  final keys = switch (user.role) {
    'farmer' => const ['farmer_dashboard'],
    'buyer' || 'business_buyer' => const ['shopping_dashboard'],
    'admin' => const ['admin_dashboard', 'admin_analytics'],
    _ => const <String>[],
  };
  final store = ref.read(cacheSnapshotStoreProvider);
  final scope = CacheScope.user(role: user.role, userId: user.id);
  await Future.wait(keys.map((key) => store.invalidate(scope, key)));
}

Future<void> invalidateCachesForAdminResource(
  WidgetRef ref,
  String resource,
) async {
  final keys = switch (resource) {
    'categories' => const ['shopping_dashboard', 'public_marketplace_0'],
    'products' => const ['shopping_dashboard', 'farmer_dashboard'],
    'harvest-batches' => const [
      'shopping_dashboard',
      'farmer_dashboard',
      'public_marketplace_2',
    ],
    'market-prices' => const ['public_marketplace_1'],
    'advisories' => const ['public_marketplace_3'],
    'orders' => const ['shopping_dashboard', 'farmer_dashboard'],
    'notifications' => const ['shopping_dashboard'],
    _ => const <String>[],
  };
  final store = ref.read(cacheSnapshotStoreProvider);
  await Future.wait(keys.map(store.invalidateAcrossScopes));
  final admin = ref.read(authenticationProvider).user;
  if (admin != null) await invalidateUserDashboardCache(ref, admin);
}

Future<void> invalidateCachesForFarmerMutation(
  WidgetRef ref,
  AuthUser farmer, {
  required String resource,
}) async {
  final store = ref.read(cacheSnapshotStoreProvider);
  final keys = switch (resource) {
    'product' => const ['shopping_dashboard'],
    'batch' => const ['shopping_dashboard', 'public_marketplace_2'],
    'order' => const ['shopping_dashboard'],
    'report' || 'profile' => const ['admin_dashboard', 'admin_analytics'],
    _ => const <String>[],
  };
  await Future.wait(keys.map(store.invalidateAcrossScopes));
  await invalidateUserDashboardCache(ref, farmer);
}

Future<void> invalidateShopperOrderMutation(
  WidgetRef ref, {
  required AuthUser buyer,
  required int farmerId,
}) async {
  final store = ref.read(cacheSnapshotStoreProvider);
  await Future.wait([
    store.invalidate(
      CacheScope.user(role: buyer.role, userId: buyer.id),
      'shopping_dashboard',
    ),
    store.invalidate(
      CacheScope.user(role: 'farmer', userId: farmerId),
      'farmer_dashboard',
    ),
  ]);
}
