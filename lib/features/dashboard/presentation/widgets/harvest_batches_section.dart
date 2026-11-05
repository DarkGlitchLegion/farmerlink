import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_models.dart';
import 'harvest_batch_card.dart';

class HarvestBatchesSection extends StatelessWidget {
  const HarvestBatchesSection({super.key, required this.data});

  final FarmerDashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Harvest batches',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${data.availableBatches.length} available',
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .56),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (data.availableBatches.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EBDD)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.leafGreen,
                size: 31,
              ),
              const SizedBox(height: 9),
              const Text(
                'No available harvest batches',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Only batches currently marked available are returned by the API.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .57),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        )
      else
        ...data.availableBatches.map(
          (batch) => HarvestBatchCard(
            key: ValueKey(batch.id),
            batch: batch,
            product: data.productsById[batch.productId],
          ),
        ),
    ],
  );
}
