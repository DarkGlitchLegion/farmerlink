import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/widgets/admin_analytics_content.dart';
import '../../presentation/widgets/admin_navigation_bar.dart';

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.darkGreen,
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: () => ref.invalidate(adminAnalyticsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 0),
      body: analytics.when(
        loading: () => const _LoadingAnalytics(),
        error: (error, _) => _AnalyticsError(
          error: error,
          onRetry: () => ref.invalidate(adminAnalyticsProvider),
        ),
        data: (overview) => RefreshIndicator(
          onRefresh: () async => ref.refresh(adminAnalyticsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Platform analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Current aggregate metrics returned by the FarmerLink API.',
              ),
              AdminAnalyticsContent(overview: overview),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingAnalytics extends StatelessWidget {
  const _LoadingAnalytics();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const LinearProgressIndicator(color: AppColors.primaryGreen),
      const SizedBox(height: 24),
      for (var i = 0; i < 6; i++)
        Card(
          color: Colors.white,
          child: Container(
            height: 82,
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECE2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
    ],
  );
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = error.toString();
    final message = status.contains('403')
        ? 'Your account is not allowed to view analytics.'
        : status.contains('401')
        ? 'Your session expired. Sign in again to continue.'
        : 'Analytics could not be loaded. Check your connection and retry.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 44,
              color: AppColors.darkGreen,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
