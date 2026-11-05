import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_models.dart';

class HarvestBatchCard extends StatelessWidget {
  const HarvestBatchCard({super.key, required this.batch, this.product});

  final HarvestBatchData batch;
  final FarmerProductData? product;

  @override
  Widget build(BuildContext context) {
    final productName = product?.name ?? 'Product #${batch.productId}';
    final unit = product?.unit ?? 'units';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6EBDD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081A3824),
            blurRadius: 13,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  color: AppColors.primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      batch.batchCode,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .57),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _BatchStatus(status: batch.status),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .5),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${batch.remainingQuantity} $unit',
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (product != null)
                Text(
                  '${_peso(product!.pricePerUnit)} / ${product!.unit}',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF0E9)),
          const SizedBox(height: 11),
          Wrap(
            spacing: 15,
            runSpacing: 8,
            children: [
              _BatchDetail(
                icon: Icons.calendar_today_outlined,
                label: 'Harvested ${_date(batch.harvestDate)}',
              ),
              if (batch.expirationDate != null)
                _BatchDetail(
                  icon: Icons.schedule_rounded,
                  label: 'Expires ${_date(batch.expirationDate)}',
                ),
              if (batch.harvestLocation.isNotEmpty)
                _BatchDetail(
                  icon: Icons.location_on_outlined,
                  label: batch.harvestLocation,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _peso(int amount) {
    final digits = amount.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$grouped';
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _BatchStatus extends StatelessWidget {
  const _BatchStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final text = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3E5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text[0].toUpperCase() + text.substring(1),
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BatchDetail extends StatelessWidget {
  const _BatchDetail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.leafGreen),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: AppColors.darkGreen.withValues(alpha: .65),
        ),
      ),
    ],
  );
}
