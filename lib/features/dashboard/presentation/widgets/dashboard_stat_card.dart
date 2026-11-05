import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.unavailable = false,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final bool unavailable;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 132),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE8ECDF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B1A3824),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              icon,
              size: 17,
              color: unavailable ? Colors.black38 : AppColors.leafGreen,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          value,
          style: TextStyle(
            color: unavailable ? Colors.black38 : AppColors.darkGreen,
            fontSize: 25,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .56),
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
