import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../data/models/admin_dashboard_data.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/providers/admin_dashboard_data_provider.dart';
import '../../presentation/widgets/admin_analytics_content.dart';
import '../../presentation/widgets/admin_navigation_panel.dart';
import '../admin_crud_pages.dart' show adminModules;

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminNavigationDrawer(),
      appBar: AppBar(
            backgroundColor: AppColors.cream,
            title: const Text(
              'FarmerLink DAVNOR',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Search management pages',
                onPressed: () => _showManagementSearch(context),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/dashboard/admin/notifications'),
                icon: const Icon(Icons.notifications_none_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'Administrator account',
                onSelected: (value) async {
                  if (value == 'profile') {
                    context.go('/dashboard/admin/profile');
                  } else if (value == 'logout') {
                    await ref.read(authenticationProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: Text('Account profile'),
                  ),
                  PopupMenuItem(value: 'logout', child: Text('Sign out')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _AdminAvatar(
                    firstName: user?.firstName ?? 'Admin',
                    avatar: user?.avatar,
                  ),
                ),
              ),
            ],
      ),
      body: _DashboardBody(userName: user?.firstName ?? 'Administrator'),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 0),
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
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.userName});
  final String userName;

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
        padding: const EdgeInsets.all(24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
                const SizedBox(height: 20),
                analytics.when(
                  loading: () => const _AnalyticsLoading(),
                  error: (error, _) => _RetryPanel(
                    message: _friendlyError(error),
                    onRetry: () => ref.invalidate(adminAnalyticsProvider),
                  ),
                  data: (overview) => AdminAnalyticsContent(overview: overview),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recent activity',
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        .where((module) => module.title.toLowerCase().contains(query.toLowerCase()))
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

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.firstName, this.avatar});
  final String firstName;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final value = avatar ?? '';
    if (value.startsWith('data:image/')) {
      final comma = value.indexOf(',');
      if (comma > 0) {
        try {
          return CircleAvatar(
            backgroundImage: MemoryImage(
              base64Decode(value.substring(comma + 1)),
            ),
          );
        } on FormatException {
          // Show initials if the stored avatar is malformed.
        }
      }
    }
    return CircleAvatar(
      backgroundColor: AppColors.accentGreen.withValues(alpha: .2),
      child: Text(firstName.isEmpty ? 'A' : firstName[0].toUpperCase()),
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
