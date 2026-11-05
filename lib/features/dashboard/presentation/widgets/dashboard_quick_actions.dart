import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Expanded(
        child: _UnavailableAction(
          icon: Icons.agriculture_rounded,
          label: 'Log Harvest',
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _UnavailableAction(
          icon: Icons.spa_outlined,
          label: 'Move to Surplus',
        ),
      ),
    ],
  );
}

class _UnavailableAction extends StatelessWidget {
  const _UnavailableAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'This workflow is not available in the app yet.',
    child: Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EBDD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen.withValues(alpha: .48),
            size: 21,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .55),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
