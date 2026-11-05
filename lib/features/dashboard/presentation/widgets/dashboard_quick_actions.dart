import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _QuickAction(
          icon: Icons.inventory_2_outlined,
          label: 'My Products',
          onTap: () => context.go('/dashboard/farmer/products'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _QuickAction(
          icon: Icons.agriculture_rounded,
          label: 'Add Harvest Batch',
          onTap: () => context.push('/dashboard/farmer/batches/new'),
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 17),
    ),
  );
}
