import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/domain/entities/user.dart';
import 'cache_snapshot_provider.dart';
import 'cache_snapshot_store.dart';

Future<void> invalidateUserDashboardCache(WidgetRef ref, AuthUser user) async {
  final keys = switch (user.role) {
    'farmer' => const ['farmer_dashboard'],
    'buyer' || 'business_buyer' => const ['shopping_dashboard'],
    _ => const <String>[],
  };
  final store = ref.read(cacheSnapshotStoreProvider);
  final scope = CacheScope.user(role: user.role, userId: user.id);
  await Future.wait(keys.map((key) => store.invalidate(scope, key)));
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
    'report' || 'profile' => const ['farmer_dashboard'],
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
