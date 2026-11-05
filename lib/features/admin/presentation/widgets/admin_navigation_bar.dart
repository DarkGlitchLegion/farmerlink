import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/icon_only_navigation_bar.dart';

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
