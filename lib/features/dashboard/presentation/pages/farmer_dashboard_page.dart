import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../data/models/dashboard_models.dart';
import '../providers/farmer_dashboard_provider.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/farmer_profile_header.dart';
import '../widgets/harvest_batches_section.dart';
import '../widgets/surplus_alert_card.dart';

class FarmerDashboardPage extends ConsumerWidget {
  const FarmerDashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      ref.invalidate(farmerDashboardProvider);
      await ref.read(farmerDashboardProvider.future);
    } catch (_) {
      // The refreshed AsyncValue renders the error state in the page.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(farmerDashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboard.when(
        loading: () => _LoadingDashboard(onRefresh: () => _refresh(ref)),
        error: (error, _) => _DashboardError(
          error: error,
          onRetry: () => _refresh(ref),
          onSignIn: () async {
            try {
              await ref.read(authenticationProvider.notifier).logout();
            } catch (_) {
              // Clear local state even when secure storage reports an error.
            }
            if (context.mounted) context.go('/login');
          },
        ),
        data: (data) =>
            _DashboardContent(data: data, onRefresh: () => _refresh(ref)),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});
  final FarmerDashboardData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.primaryGreen,
    onRefresh: onRefresh,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: FarmerProfileHeader(user: data.user, profile: data.profile),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeading(
                  title: 'Your farm at a glance',
                  subtitle: 'A current view of your FarmerLink activity',
                ),
                const SizedBox(height: 15),
                const DashboardQuickActions(),
                const SizedBox(height: 8),
                Text(
                  'Harvest and surplus workflows are not available yet.',
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .52),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 138,
            ),
            delegate: SliverChildListDelegate([
              DashboardStatCard(
                title: 'Monthly revenue',
                value: _peso(data.monthlyPaidRevenue()),
                caption: 'Paid orders created this month',
                icon: Icons.payments_outlined,
              ),
              DashboardStatCard(
                title: 'Active stock',
                value: '${data.availableBatches.length}',
                caption: 'Available harvest batches',
                icon: Icons.inventory_2_outlined,
              ),
              DashboardStatCard(
                title: 'Pending orders',
                value: '${data.pendingOrders}',
                caption: 'Orders awaiting your response',
                icon: Icons.receipt_long_outlined,
              ),
              const DashboardStatCard(
                title: 'Spoilage prevented',
                value: '—',
                caption: 'Not measured by the current API',
                icon: Icons.eco_outlined,
                unavailable: true,
              ),
            ]),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: SurplusAlertCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(child: HarvestBatchesSection(data: data)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(
          color: AppColors.darkGreen.withValues(alpha: .58),
          fontSize: 11.5,
        ),
      ),
    ],
  );
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    color: AppColors.primaryGreen,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 190),
        Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        SizedBox(height: 15),
        Center(
          child: Text(
            'Loading your farm dashboard…',
            style: TextStyle(color: AppColors.darkGreen),
          ),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.error,
    required this.onRetry,
    required this.onSignIn,
  });
  final Object error;
  final Future<void> Function() onRetry;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final expired =
        error is ApiException && (error as ApiException).statusCode == 401;
    final message =
        error is ApiException && (error as ApiException).statusCode >= 500
        ? 'FarmerLink is having trouble right now. Please try again shortly.'
        : error is FormatException
        ? (error as FormatException).message
        : expired
        ? 'Your session has expired. Sign in again to reload your farm data.'
        : 'Could not load your dashboard. Check your connection and try again.';
    return RefreshIndicator(
      onRefresh: onRetry,
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 170),
          const Icon(
            Icons.cloud_off_outlined,
            size: 47,
            color: AppColors.leafGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dashboard unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .65),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: expired
                ? FilledButton(
                    onPressed: onSignIn,
                    child: const Text('Sign in again'),
                  )
                : OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
          ),
        ],
      ),
    );
  }
}

String _peso(int amount) {
  final grouped = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$grouped';
}
