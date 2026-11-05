import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/cache_snapshot_provider.dart';
import '../../../../core/storage/cache_snapshot_store.dart';
import '../../data/models/admin_analytics.dart';
import '../../data/services/admin_analytics_service.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';

final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>(
  (ref) => AdminAnalyticsService(),
);

final adminAnalyticsProvider =
    StreamProvider.autoDispose<AdminAnalyticsOverview>((ref) {
      final auth = ref.watch(authenticationProvider);
      if (!auth.isAuthenticated || auth.user?.role != 'admin') {
        throw const _AdminAnalyticsAccessException();
      }
      final user = auth.user!;
      return cacheFirstRefresh(
        store: ref.watch(cacheSnapshotStoreProvider),
        scope: CacheScope.user(role: user.role, userId: user.id),
        key: 'admin_analytics',
        decode: (json) => AdminAnalyticsOverview.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
        encode: (data) => data.toJson(),
        fetch: () => ref.watch(adminAnalyticsServiceProvider).getOverview(),
      );
    });

class _AdminAnalyticsAccessException implements Exception {
  const _AdminAnalyticsAccessException();
}
