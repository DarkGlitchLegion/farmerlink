import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/icon_only_navigation_bar.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) => const Drawer(
    child: SafeArea(child: AdminNavigationPanel(inDrawer: true)),
  );
}

class AdminResponsiveShell extends StatelessWidget {
  const AdminResponsiveShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 1120
        ? child
        : Row(
            children: [
              Container(
                width: 272,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(right: BorderSide(color: Color(0xFFE4E8D8))),
                ),
                child: const AdminNavigationPanel(),
              ),
              Expanded(child: child),
            ],
          ),
  );
}

class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) => IconOnlyNavigationBar(
    selectedIndex: selectedIndex,
    onSelected: (index) => context.go(
      const [
        '/dashboard/admin',
        '/dashboard/admin/users',
        '/dashboard/admin/products',
        '/dashboard/admin/crop-reports',
        '/dashboard/admin/profile',
      ][index],
    ),
    items: const [
      IconOnlyNavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
      ),
      IconOnlyNavigationItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
      ),
      IconOnlyNavigationItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
      ),
      IconOnlyNavigationItem(
        icon: Icons.assessment_outlined,
        activeIcon: Icons.assessment,
      ),
      IconOnlyNavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ],
  );
}

class AdminNavigationPanel extends ConsumerWidget {
  const AdminNavigationPanel({super.key, this.inDrawer = false});
  final bool inDrawer;

  static const _groups = <(String, List<(String, String, IconData)>)>[
    (
      'MAIN',
      [
        ('Dashboard', '/dashboard/admin', Icons.dashboard_outlined),
        ('Analytics', '/dashboard/admin/analytics', Icons.insights_outlined),
      ],
    ),
    (
      'MANAGEMENT',
      [
        ('Users', '/dashboard/admin/users', Icons.people_outline),
        (
          'Farmer profiles',
          '/dashboard/admin/farmer-profiles',
          Icons.agriculture_outlined,
        ),
        (
          'Business profiles',
          '/dashboard/admin/business-buyer-profiles',
          Icons.storefront_outlined,
        ),
        ('Products', '/dashboard/admin/products', Icons.inventory_2_outlined),
        ('Categories', '/dashboard/admin/categories', Icons.category_outlined),
        (
          'Harvest batches',
          '/dashboard/admin/harvest-batches',
          Icons.grass_outlined,
        ),
        ('Orders', '/dashboard/admin/orders', Icons.receipt_long_outlined),
      ],
    ),
    (
      'AGRICULTURAL INFORMATION',
      [
        ('Market prices', '/dashboard/admin/market-prices', Icons.show_chart),
        ('Advisories', '/dashboard/admin/advisories', Icons.campaign_outlined),
        (
          'Crop reports',
          '/dashboard/admin/crop-reports',
          Icons.report_outlined,
        ),
      ],
    ),
    (
      'ADMINISTRATION',
      [
        (
          'Notifications',
          '/dashboard/admin/notifications',
          Icons.notifications_none,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    final location = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .path;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Icon(Icons.eco_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'FarmerLink DAVNOR',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              if (inDrawer)
                IconButton(
                  tooltip: 'Close navigation',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final group in _groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                  child: Text(
                    group.$1,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                for (final item in group.$2)
                  _NavigationItem(
                    title: item.$1,
                    path: item.$2,
                    icon: item.$3,
                    closeDrawer: inDrawer,
                    selected:
                        location == item.$2 ||
                        location.startsWith('${item.$2}/'),
                  ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.accentGreen.withValues(alpha: .18),
            child: Text(
              user?.firstName.isNotEmpty == true
                  ? user!.firstName[0].toUpperCase()
                  : 'A',
              style: const TextStyle(color: AppColors.darkGreen),
            ),
          ),
          title: Text(
            user?.fullName ?? 'Administrator',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('Administrator'),
          trailing: IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authenticationProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ),
      ],
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.title,
    required this.path,
    required this.icon,
    required this.selected,
    required this.closeDrawer,
  });

  final String title;
  final String path;
  final IconData icon;
  final bool selected;
  final bool closeDrawer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: ListTile(
      selected: selected,
      selectedColor: AppColors.darkGreen,
      selectedTileColor: AppColors.accentGreen.withValues(alpha: .16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        if (closeDrawer) Navigator.of(context).pop();
        context.go(path);
      },
    ),
  );
}
