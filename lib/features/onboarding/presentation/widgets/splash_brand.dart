import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 66 : 74,
          height: compact ? 66 : 74,
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.cream.withValues(alpha: 0.18)),
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.harvestYellow, size: 40),
        ),
        const SizedBox(height: 15),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Farmer', style: TextStyle(color: AppColors.cream)),
              TextSpan(text: 'Link', style: TextStyle(color: AppColors.harvestYellow)),
            ],
          ),
          style: TextStyle(
            fontSize: compact ? 35 : 39,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'From Farm to Table, Connecting Communities.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.cream.withValues(alpha: 0.91),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Text(
            'Empowering local farmers and making fresh produce accessible to every community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cream.withValues(alpha: 0.68),
              fontSize: compact ? 12 : 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
