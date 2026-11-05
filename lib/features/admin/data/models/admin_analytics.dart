class AdminAnalyticsOverview {
  const AdminAnalyticsOverview({
    required this.generatedAt,
    required this.users,
    required this.catalog,
    required this.orders,
    required this.profiles,
    required this.cropReports,
    required this.topDeliveredProducts,
  });

  final DateTime? generatedAt;
  final UserAnalytics users;
  final CatalogAnalytics catalog;
  final OrderAnalytics orders;
  final ProfileAnalytics profiles;
  final CropReportAnalytics cropReports;
  final List<TopDeliveredProduct> topDeliveredProducts;

  factory AdminAnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      AdminAnalyticsOverview(
        generatedAt: DateTime.tryParse('${json['generated_at'] ?? ''}'),
        users: UserAnalytics.fromJson(_object(json['users'])),
        catalog: CatalogAnalytics.fromJson(_object(json['catalog'])),
        orders: OrderAnalytics.fromJson(_object(json['orders'])),
        profiles: ProfileAnalytics.fromJson(_object(json['profiles'])),
        cropReports: CropReportAnalytics.fromJson(
          _object(json['crop_reports']),
        ),
        topDeliveredProducts: (json['top_delivered_products'] as List? ?? [])
            .whereType<Map>()
            .map((item) => TopDeliveredProduct.fromJson(_object(item)))
            .toList(growable: false),
      );
}

class UserAnalytics {
  const UserAnalytics({
    this.total,
    this.byRole = const {},
    this.byStatus = const {},
  });
  final int? total;
  final Map<String, int> byRole;
  final Map<String, int> byStatus;

  factory UserAnalytics.fromJson(Map<String, dynamic> json) => UserAnalytics(
    total: _integer(json['total']),
    byRole: _integerMap(json['by_role']),
    byStatus: _integerMap(json['by_status']),
  );
}

class CatalogAnalytics {
  const CatalogAnalytics({
    this.categoriesTotal,
    this.productsTotal,
    this.productsByStatus = const {},
    this.activeProducts,
    this.activeProductQuantity,
    this.harvestBatchesTotal,
    this.availableHarvestBatches,
    this.availableHarvestQuantity,
    this.marketPricesTotal,
    this.publishedAdvisories,
  });
  final int? categoriesTotal;
  final int? productsTotal;
  final Map<String, int> productsByStatus;
  final int? activeProducts;
  final int? activeProductQuantity;
  final int? harvestBatchesTotal;
  final int? availableHarvestBatches;
  final int? availableHarvestQuantity;
  final int? marketPricesTotal;
  final int? publishedAdvisories;

  factory CatalogAnalytics.fromJson(Map<String, dynamic> json) =>
      CatalogAnalytics(
        categoriesTotal: _integer(json['categories_total']),
        productsTotal: _integer(json['products_total']),
        productsByStatus: _integerMap(json['products_by_status']),
        activeProducts: _integer(json['active_products']),
        activeProductQuantity: _integer(json['active_product_quantity']),
        harvestBatchesTotal: _integer(json['harvest_batches_total']),
        availableHarvestBatches: _integer(json['available_harvest_batches']),
        availableHarvestQuantity: _integer(json['available_harvest_quantity']),
        marketPricesTotal: _integer(json['market_prices_total']),
        publishedAdvisories: _integer(json['published_advisories']),
      );
}

class OrderAnalytics {
  const OrderAnalytics({
    this.total,
    this.byStatus = const {},
    this.byPaymentStatus = const {},
    this.openOrders,
    this.deliveredOrders,
    this.cancelledOrders,
    this.paidOrders,
    this.paidSalesTotal,
    this.averagePaidOrderTotal,
  });
  final int? total;
  final Map<String, int> byStatus;
  final Map<String, int> byPaymentStatus;
  final int? openOrders;
  final int? deliveredOrders;
  final int? cancelledOrders;
  final int? paidOrders;
  final int? paidSalesTotal;
  final double? averagePaidOrderTotal;

  factory OrderAnalytics.fromJson(Map<String, dynamic> json) => OrderAnalytics(
    total: _integer(json['total']),
    byStatus: _integerMap(json['by_status']),
    byPaymentStatus: _integerMap(json['by_payment_status']),
    openOrders: _integer(json['open_orders']),
    deliveredOrders: _integer(json['delivered_orders']),
    cancelledOrders: _integer(json['cancelled_orders']),
    paidOrders: _integer(json['paid_orders']),
    paidSalesTotal: _integer(json['paid_sales_total']),
    averagePaidOrderTotal: _decimal(json['average_paid_order_total']),
  );
}

class ProfileAnalytics {
  const ProfileAnalytics({
    this.farmerProfilesTotal,
    this.farmerProfilesByVerification = const {},
    this.businessBuyerProfilesTotal,
    this.businessBuyerProfilesByVerification = const {},
  });
  final int? farmerProfilesTotal;
  final Map<String, int> farmerProfilesByVerification;
  final int? businessBuyerProfilesTotal;
  final Map<String, int> businessBuyerProfilesByVerification;

  factory ProfileAnalytics.fromJson(Map<String, dynamic> json) =>
      ProfileAnalytics(
        farmerProfilesTotal: _integer(json['farmer_profiles_total']),
        farmerProfilesByVerification: _integerMap(
          json['farmer_profiles_by_verification'],
        ),
        businessBuyerProfilesTotal: _integer(
          json['business_buyer_profiles_total'],
        ),
        businessBuyerProfilesByVerification: _integerMap(
          json['business_buyer_profiles_by_verification'],
        ),
      );
}

class CropReportAnalytics {
  const CropReportAnalytics({
    this.total,
    this.byStatus = const {},
    this.bySeverity = const {},
    this.criticalReports,
  });
  final int? total;
  final Map<String, int> byStatus;
  final Map<String, int> bySeverity;
  final int? criticalReports;

  factory CropReportAnalytics.fromJson(Map<String, dynamic> json) =>
      CropReportAnalytics(
        total: _integer(json['total']),
        byStatus: _integerMap(json['by_status']),
        bySeverity: _integerMap(json['by_severity']),
        criticalReports: _integer(json['critical_reports']),
      );
}

class TopDeliveredProduct {
  const TopDeliveredProduct({
    this.productId,
    this.productName,
    this.quantityDelivered,
    this.deliveredSalesTotal,
  });
  final int? productId;
  final String? productName;
  final int? quantityDelivered;
  final int? deliveredSalesTotal;

  factory TopDeliveredProduct.fromJson(Map<String, dynamic> json) =>
      TopDeliveredProduct(
        productId: _integer(json['product_id']),
        productName: json['product_name'] as String?,
        quantityDelivered: _integer(json['quantity_delivered']),
        deliveredSalesTotal: _integer(json['delivered_sales_total']),
      );
}

Map<String, dynamic> _object(dynamic value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const {};

int? _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double? _decimal(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

Map<String, int> _integerMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    final number = _integer(entry.value);
    if (number != null) result[entry.key.toString()] = number;
  }
  return result;
}
