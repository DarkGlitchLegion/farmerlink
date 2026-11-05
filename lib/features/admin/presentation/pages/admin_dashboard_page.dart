import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../data/models/admin_analytics.dart';
import '../../data/models/admin_dashboard_data.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/providers/admin_dashboard_data_provider.dart';
import '../../presentation/widgets/admin_navigation_bar.dart';
import '../../../dashboard/shared/widgets/agricultural_dashboard_header.dart';
import '../admin_crud_pages.dart' show adminModules;

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _DashboardBody(
        userName: user?.firstName ?? 'Administrator',
        avatar: user?.avatar,
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 0),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.userName, this.avatar});
  final String userName;
  final String? avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);
    final records = ref.watch(adminDashboardDataProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(adminAnalyticsProvider.future),
          ref.refresh(adminDashboardDataProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: AgriculturalDashboardHeader(
                eyebrow: _greeting(),
                title: userName,
                subtitle:
                    'Manage marketplace activity and FarmerLink operations.',
                avatar: avatar,
                onAvatarTap: () => context.go('/dashboard/admin/profile'),
                onNotifications: () =>
                    context.go('/dashboard/admin/notifications'),
                onSignOut: () async {
                  await ref.read(authenticationProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor marketplace activity, manage users, and oversee FarmerLink DAVNOR operations.',
                  ),
                  const SizedBox(height: 4),
                  Text(_today(), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SearchBar(
                    leading: const Icon(Icons.search),
                    hintText: 'Search management pages',
                    onTap: () => _showManagementSearch(context),
                    trailing: const [Icon(Icons.arrow_forward)],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/dashboard/admin/analytics'),
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('View analytics'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  analytics.when(
                    loading: () => const _AnalyticsLoading(),
                    error: (error, _) => _RetryPanel(
                      message: _friendlyError(error),
                      onRetry: () => ref.invalidate(adminAnalyticsProvider),
                    ),
                    data: (overview) =>
                        _DashboardAnalyticsSummary(overview: overview),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recent records',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  records.when(
                    loading: () => const _AnalyticsLoading(compact: true),
                    error: (error, _) => _RetryPanel(
                      message: _friendlyError(error),
                      onRetry: () => ref.invalidate(adminDashboardDataProvider),
                    ),
                    data: (data) => _RecentSections(data: data),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManagementSearch(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => const _ManagementSearchDialog(),
    );
    if (selected != null && context.mounted) {
      context.go('/dashboard/admin/$selected');
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return '$greeting, administrator';
  }
}

class _DashboardAnalyticsSummary extends StatelessWidget {
  const _DashboardAnalyticsSummary({required this.overview});
  final AdminAnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String, IconData)>[
      ('Users', _format(overview.users.total), Icons.people_outline),
      (
        'Products',
        _format(overview.catalog.productsTotal),
        Icons.inventory_2_outlined,
      ),
      ('Orders', _format(overview.orders.total), Icons.receipt_long_outlined),
      (
        'Pending farmer reviews',
        _format(overview.profiles.farmerProfilesByVerification['pending']),
        Icons.verified_user_outlined,
      ),
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 600 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in metrics)
                  SizedBox(
                    width: width,
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE7EADF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.$3,
                              size: 19,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$2,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    item.$1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (overview.topDeliveredProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE7EADF)),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.trending_up,
                  color: AppColors.primaryGreen,
                ),
                title: Text(
                  overview.topDeliveredProducts.first.productName ??
                      'Top delivered product',
                ),
                subtitle: Text(
                  '${overview.topDeliveredProducts.first.quantityDelivered ?? 0} delivered',
                ),
                trailing: TextButton(
                  onPressed: () => context.go('/dashboard/admin/analytics'),
                  child: const Text('Analytics'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _format(num? value) => value == null ? '—' : value.toInt().toString();
}

class _RecentSections extends StatelessWidget {
  const _RecentSections({required this.data});
  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionCard(
        context,
        title: 'Recent orders',
        action: 'View all',
        onAction: () => context.go('/dashboard/admin/orders'),
        children: [
          if (data.orders.isEmpty)
            const _EmptyLine('No orders are available.')
          else
            for (final order in data.orders)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text(order.orderNumber),
                subtitle: Text(
                  'Buyer #${order.buyerId} · ${_date(order.createdAt)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱${order.totalAmount}'),
                    _StatusLabel(order.status),
                  ],
                ),
                onTap: () => context.go('/dashboard/admin/orders/${order.id}'),
              ),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        context,
        title: 'Pending verifications',
        action: 'Review profiles',
        onAction: () => context.go('/dashboard/admin/farmer-profiles'),
        children: [
          if (data.pendingProfiles.isEmpty)
            const _EmptyLine('No pending profiles were found.'),
          for (final profile in data.pendingProfiles)
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  profile.isBusiness
                      ? Icons.storefront_outlined
                      : Icons.agriculture_outlined,
                ),
              ),
              title: Text(profile.name),
              subtitle: Text(
                '${profile.isBusiness ? 'Business buyer' : 'Farmer'} · ${_date(profile.createdAt)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(
                '/dashboard/admin/${profile.isBusiness ? 'business-buyer-profiles' : 'farmer-profiles'}/${profile.id}',
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        context,
        title: 'Recent crop reports',
        action: 'View all',
        onAction: () => context.go('/dashboard/admin/crop-reports'),
        children: [
          if (data.cropReports.isEmpty)
            const _EmptyLine('No crop reports are available.')
          else
            for (final report in data.cropReports)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.report_outlined)),
                title: Text(_humanize(report.reportType)),
                subtitle: Text(
                  'Farmer #${report.farmerId} · ${report.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _StatusLabel(report.status),
                onTap: () =>
                    context.go('/dashboard/admin/crop-reports/${report.id}'),
              ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Recent records are shown from the existing Orders and Crop Reports endpoints. The API does not provide an audit activity feed.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String action,
    required VoidCallback onAction,
    required List<Widget> children,
  }) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.accentGreen.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      _humanize(status),
      style: const TextStyle(fontSize: 11, color: AppColors.darkGreen),
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Text(message, style: const TextStyle(color: Colors.black54)),
  );
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: List.generate(
      compact ? 3 : 6,
      (index) => Container(
        width: compact ? 300 : 190,
        height: compact ? 80 : 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: 90),
            SizedBox(height: 14),
            _SkeletonLine(width: 130, height: 22),
          ],
        ),
      ),
    ),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 10});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE8ECE2),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.darkGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _ManagementSearchDialog extends StatefulWidget {
  const _ManagementSearchDialog();
  @override
  State<_ManagementSearchDialog> createState() =>
      _ManagementSearchDialogState();
}

class _ManagementSearchDialogState extends State<_ManagementSearchDialog> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final analyticsMatches = 'analytics'.contains(query.toLowerCase());
    final results = adminModules
        .where(
          (module) => module.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return AlertDialog(
      title: const Text('Find a management page'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search management pages',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (analyticsMatches)
                    ListTile(
                      leading: const Icon(Icons.insights_outlined),
                      title: const Text('Analytics'),
                      onTap: () => Navigator.pop(context, 'analytics'),
                    ),
                  for (final module in results)
                    ListTile(
                      leading: Icon(module.icon),
                      title: Text(module.title),
                      onTap: () => Navigator.pop(context, module.key),
                    ),
                  if (results.isEmpty && !analyticsMatches)
                    const ListTile(title: Text('No matching management pages')),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _humanize(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _date(DateTime? value) {
  if (value == null) return 'Date unavailable';
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _friendlyError(Object error) {
  if (error.toString().contains('403')) {
    return 'You do not have permission to view this information.';
  }
  if (error.toString().contains('401')) {
    return 'Your session expired. Sign in again to continue.';
  }
  return 'Could not load dashboard data. Check your connection and retry.';
}
