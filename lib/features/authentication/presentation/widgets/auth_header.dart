import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.eco_rounded,
          color: AppColors.harvestYellow,
          size: 30,
        ),
      ),
      const SizedBox(height: 22),
      Text.rich(
        const TextSpan(
          children: [
            TextSpan(
              text: 'Farmer',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
            TextSpan(
              text: 'Link',
              style: TextStyle(color: AppColors.harvestYellow),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 19),
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.darkGreen,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.darkGreen.withValues(alpha: .68),
        ),
      ),
    ],
  );
}
