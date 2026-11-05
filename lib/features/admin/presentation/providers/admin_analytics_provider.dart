import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_analytics.dart';
import '../../data/services/admin_analytics_service.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';

final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>(
  (ref) => AdminAnalyticsService(),
);

final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalyticsOverview>((ref) async {
      final auth = ref.watch(authenticationProvider);
      if (!auth.isAuthenticated || auth.user?.role != 'admin') {
        throw const _AdminAnalyticsAccessException();
      }
      return ref.watch(adminAnalyticsServiceProvider).getOverview();
    });

class _AdminAnalyticsAccessException implements Exception {
  const _AdminAnalyticsAccessException();
}
