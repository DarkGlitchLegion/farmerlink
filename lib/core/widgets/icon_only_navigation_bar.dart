import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IconOnlyNavigationItem {
  const IconOnlyNavigationItem({required this.icon, required this.activeIcon});

  final IconData icon;
  final IconData activeIcon;
}

class IconOnlyNavigationBar extends StatelessWidget {
  const IconOnlyNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<IconOnlyNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelected,
    backgroundColor: AppColors.cream,
    indicatorColor: AppColors.accentGreen.withValues(alpha: .16),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    destinations: [
      for (final item in items)
        NavigationDestination(
          icon: Icon(item.icon, color: Colors.grey.shade600, size: 25),
          selectedIcon: Icon(
            item.activeIcon,
            color: AppColors.primaryGreen,
            size: 25,
          ),
          label: '',
        ),
    ],
  );
}
