import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SurplusAlertCard extends StatelessWidget {
  const SurplusAlertCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E3),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF3E2B9)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.harvestYellow.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.wb_sunny_outlined,
            color: AppColors.darkGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Surplus window',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Surplus alerts and save-harvest actions are not supported by the current API.',
                style: TextStyle(
                  color: Color(0xFF6D6042),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
