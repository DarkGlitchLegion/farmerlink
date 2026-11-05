import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_analytics.dart';

class AdminAnalyticsContent extends StatelessWidget {
  const AdminAnalyticsContent({super.key, required this.overview});

  final AdminAnalyticsOverview overview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (overview.generatedAt != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Updated ${_dateTime(overview.generatedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      _sectionTitle(context, 'User overview'),
      _metricGrid([
        _Metric('Total users', overview.users.total, Icons.people_outline),
        _Metric(
          'Farmers',
          overview.users.byRole['farmer'],
          Icons.agriculture_outlined,
        ),
        _Metric(
          'Individual buyers',
          overview.users.byRole['buyer'],
          Icons.shopping_bag_outlined,
        ),
        _Metric(
          'Business buyers',
          overview.users.byRole['business_buyer'],
          Icons.storefront_outlined,
        ),
      ]),
      if (overview.users.byRole.isNotEmpty)
        _BreakdownCard(
          title: 'User distribution',
          values: overview.users.byRole,
        ),
      _sectionTitle(context, 'Catalog and inventory'),
      _metricGrid([
        _Metric(
          'Products',
          overview.catalog.productsTotal,
          Icons.inventory_2_outlined,
        ),
        _Metric(
          'Active products',
          overview.catalog.activeProducts,
          Icons.check_circle_outline,
        ),
        _Metric(
          'Active product quantity',
          overview.catalog.activeProductQuantity,
          Icons.widgets_outlined,
        ),
        _Metric(
          'Harvest batches',
          overview.catalog.harvestBatchesTotal,
          Icons.grass_outlined,
        ),
        _Metric(
          'Available batches',
          overview.catalog.availableHarvestBatches,
          Icons.inventory_outlined,
        ),
        _Metric(
          'Available batch quantity',
          overview.catalog.availableHarvestQuantity,
          Icons.scale_outlined,
        ),
        _Metric(
          'Categories',
          overview.catalog.categoriesTotal,
          Icons.category_outlined,
        ),
        _Metric(
          'Market prices',
          overview.catalog.marketPricesTotal,
          Icons.show_chart,
        ),
        _Metric(
          'Published advisories',
          overview.catalog.publishedAdvisories,
          Icons.campaign_outlined,
        ),
      ]),
      _sectionTitle(context, 'Orders and payments'),
      _metricGrid([
        _Metric(
          'Total orders',
          overview.orders.total,
          Icons.receipt_long_outlined,
        ),
        _Metric(
          'Open orders',
          overview.orders.openOrders,
          Icons.pending_actions_outlined,
        ),
        _Metric(
          'Delivered orders',
          overview.orders.deliveredOrders,
          Icons.local_shipping_outlined,
        ),
        _Metric(
          'Cancelled orders',
          overview.orders.cancelledOrders,
          Icons.cancel_outlined,
        ),
        _Metric(
          'Paid orders',
          overview.orders.paidOrders,
          Icons.payments_outlined,
        ),
        _Metric(
          'Paid sales',
          overview.orders.paidSalesTotal,
          Icons.account_balance_wallet_outlined,
          currency: true,
        ),
        _Metric(
          'Average paid order',
          overview.orders.averagePaidOrderTotal,
          Icons.trending_up_outlined,
          currency: true,
        ),
      ]),
      if (overview.orders.byStatus.isNotEmpty)
        _BreakdownCard(
          title: 'Orders by status',
          values: overview.orders.byStatus,
        ),
      if (overview.orders.byPaymentStatus.isNotEmpty)
        _BreakdownCard(
          title: 'Payments by status',
          values: overview.orders.byPaymentStatus,
        ),
      _sectionTitle(context, 'Profile verification'),
      _metricGrid([
        _Metric(
          'Farmer profiles',
          overview.profiles.farmerProfilesTotal,
          Icons.agriculture_outlined,
        ),
        _Metric(
          'Pending farmer verification',
          overview.profiles.farmerProfilesByVerification['pending'],
          Icons.hourglass_empty,
        ),
        _Metric(
          'Approved farmer profiles',
          overview.profiles.farmerProfilesByVerification['approved'],
          Icons.verified_outlined,
        ),
        _Metric(
          'Business buyer profiles',
          overview.profiles.businessBuyerProfilesTotal,
          Icons.storefront_outlined,
        ),
        _Metric(
          'Pending business verification',
          overview.profiles.businessBuyerProfilesByVerification['pending'],
          Icons.hourglass_empty,
        ),
        _Metric(
          'Approved business profiles',
          overview.profiles.businessBuyerProfilesByVerification['approved'],
          Icons.verified_outlined,
        ),
      ]),
      if (overview.profiles.farmerProfilesByVerification.isNotEmpty)
        _BreakdownCard(
          title: 'Farmer verification status',
          values: overview.profiles.farmerProfilesByVerification,
        ),
      if (overview.profiles.businessBuyerProfilesByVerification.isNotEmpty)
        _BreakdownCard(
          title: 'Business verification status',
          values: overview.profiles.businessBuyerProfilesByVerification,
        ),
      _sectionTitle(context, 'Crop reports'),
      _metricGrid([
        _Metric(
          'Total crop reports',
          overview.cropReports.total,
          Icons.report_outlined,
        ),
        _Metric(
          'Critical reports',
          overview.cropReports.criticalReports,
          Icons.priority_high_rounded,
        ),
      ]),
      if (overview.cropReports.byStatus.isNotEmpty)
        _BreakdownCard(
          title: 'Reports by status',
          values: overview.cropReports.byStatus,
        ),
      if (overview.cropReports.bySeverity.isNotEmpty)
        _BreakdownCard(
          title: 'Reports by severity',
          values: overview.cropReports.bySeverity,
        ),
      if (overview.topDeliveredProducts.isNotEmpty) ...[
        _sectionTitle(context, 'Top delivered products'),
        _TopProductsCard(products: overview.topDeliveredProducts),
      ],
    ],
  );

  static Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.w800),
    ),
  );

  static Widget _metricGrid(List<_Metric> metrics) {
    final available = metrics.where((metric) => metric.value != null).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 440
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in available)
              SizedBox(
                width: width,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, {this.currency = false});
  final String label;
  final num? value;
  final IconData icon;
  final bool currency;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: AppColors.primaryGreen),
          const SizedBox(height: 12),
          Text(
            metric.currency
                ? '₱${_number(metric.value!)}'
                : _number(metric.value!),
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(metric.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.values});
  final String title;
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final entry in values.entries) ...[
              Row(
                children: [
                  Expanded(child: Text(_humanize(entry.key))),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: maxValue == 0 ? 0 : entry.value / maxValue,
                  minHeight: 8,
                  color: AppColors.primaryGreen,
                  backgroundColor: AppColors.accentGreen.withValues(alpha: .15),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});
  final List<TopDeliveredProduct> products;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        for (var index = 0; index < products.length; index++)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentGreen.withValues(alpha: .16),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: AppColors.darkGreen),
              ),
            ),
            title: Text(
              products[index].productName ??
                  'Product ${products[index].productId ?? ''}',
            ),
            subtitle: Text(
              '${products[index].quantityDelivered ?? '—'} delivered',
            ),
            trailing: products[index].deliveredSalesTotal == null
                ? null
                : Text('₱${_number(products[index].deliveredSalesTotal!)}'),
          ),
      ],
    ),
  );
}

String _number(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _humanize(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _dateTime(DateTime value) =>
    '${value.toLocal().year}-${value.toLocal().month.toString().padLeft(2, '0')}-${value.toLocal().day.toString().padLeft(2, '0')} ${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
