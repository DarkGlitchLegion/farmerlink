import '../../../authentication/domain/entities/user.dart';

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _dateValue(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

class FarmerProfileData {
  const FarmerProfileData({
    required this.farmName,
    required this.farmAddress,
    required this.municipality,
    required this.province,
    required this.verificationStatus,
  });

  final String farmName;
  final String farmAddress;
  final String municipality;
  final String province;
  final String verificationStatus;

  factory FarmerProfileData.fromJson(Map<String, dynamic> json) =>
      FarmerProfileData(
        farmName: json['farm_name'] as String? ?? '',
        farmAddress: json['farm_address'] as String? ?? '',
        municipality: json['municipality'] as String? ?? '',
        province: json['province'] as String? ?? '',
        verificationStatus: json['verification_status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
    'farm_name': farmName,
    'farm_address': farmAddress,
    'municipality': municipality,
    'province': province,
    'verification_status': verificationStatus,
  };
}

class HarvestBatchData {
  const HarvestBatchData({
    required this.id,
    required this.batchCode,
    required this.farmerId,
    required this.productId,
    required this.harvestDate,
    required this.availableDate,
    required this.expirationDate,
    required this.remainingQuantity,
    required this.harvestLocation,
    required this.status,
  });

  final int id;
  final String batchCode;
  final int farmerId;
  final int productId;
  final DateTime? harvestDate;
  final DateTime? availableDate;
  final DateTime? expirationDate;
  final int remainingQuantity;
  final String harvestLocation;
  final String status;

  factory HarvestBatchData.fromJson(Map<String, dynamic> json) =>
      HarvestBatchData(
        id: _intValue(json['id']),
        batchCode: json['batch_code'] as String? ?? 'Batch ${json['id'] ?? ''}',
        farmerId: _intValue(json['farmer_id']),
        productId: _intValue(json['product_id']),
        harvestDate: _dateValue(json['harvest_date']),
        availableDate: _dateValue(json['available_date']),
        expirationDate: _dateValue(json['expected_expiration_date']),
        remainingQuantity: _intValue(json['remaining_quantity']),
        harvestLocation: json['harvest_location'] as String? ?? '',
        status: json['status'] as String? ?? 'available',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_code': batchCode,
    'farmer_id': farmerId,
    'product_id': productId,
    'harvest_date': harvestDate?.toIso8601String(),
    'available_date': availableDate?.toIso8601String(),
    'expected_expiration_date': expirationDate?.toIso8601String(),
    'remaining_quantity': remainingQuantity,
    'harvest_location': harvestLocation,
    'status': status,
  };
}

class FarmerProductData {
  const FarmerProductData({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.unit,
    required this.pricePerUnit,
  });

  final int id;
  final int farmerId;
  final String name;
  final String unit;
  final int pricePerUnit;

  factory FarmerProductData.fromJson(Map<String, dynamic> json) =>
      FarmerProductData(
        id: _intValue(json['id']),
        farmerId: _intValue(json['farmer_id']),
        name: json['name'] as String? ?? 'Produce',
        unit: json['unit'] as String? ?? 'unit',
        pricePerUnit: _intValue(json['price_per_unit']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'name': name,
    'unit': unit,
    'price_per_unit': pricePerUnit,
  };
}

class FarmerOrderData {
  const FarmerOrderData({
    required this.farmerId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  final int farmerId;
  final int totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;

  factory FarmerOrderData.fromJson(Map<String, dynamic> json) =>
      FarmerOrderData(
        farmerId: _intValue(json['farmer_id']),
        totalAmount: _intValue(json['total_amount']),
        status: json['status'] as String? ?? '',
        paymentStatus: json['payment_status'] as String? ?? '',
        createdAt: _dateValue(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'total_amount': totalAmount,
    'status': status,
    'payment_status': paymentStatus,
    'created_at': createdAt?.toIso8601String(),
  };
}

class FarmerDashboardData {
  const FarmerDashboardData({
    required this.user,
    required this.availableBatches,
    required this.productsById,
    required this.orders,
    this.profile,
  });

  final AuthUser user;
  final FarmerProfileData? profile;
  final List<HarvestBatchData> availableBatches;
  final Map<int, FarmerProductData> productsById;
  final List<FarmerOrderData> orders;

  Map<String, dynamic> toJson() => {
    'profile': profile?.toJson(),
    'available_batches': availableBatches
        .map((batch) => batch.toJson())
        .toList(),
    'products': productsById.values.map((product) => product.toJson()).toList(),
    'orders': orders.map((order) => order.toJson()).toList(),
  };

  factory FarmerDashboardData.fromJson(
    Map<String, dynamic> json, {
    required AuthUser user,
  }) {
    final profile = json['profile'];
    final products = (json['products'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) => FarmerProductData.fromJson(Map<String, dynamic>.from(item)),
        )
        .fold<Map<int, FarmerProductData>>({}, (map, product) {
          map[product.id] = product;
          return map;
        });
    return FarmerDashboardData(
      user: user,
      profile: profile is Map
          ? FarmerProfileData.fromJson(Map<String, dynamic>.from(profile))
          : null,
      availableBatches: (json['available_batches'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                HarvestBatchData.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      productsById: Map.unmodifiable(products),
      orders: (json['orders'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => FarmerOrderData.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  int monthlyPaidRevenue({DateTime? now}) {
    final current = now ?? DateTime.now();
    return orders
        .where((order) {
          final created = order.createdAt?.toLocal();
          return order.paymentStatus == 'paid' &&
              created != null &&
              created.year == current.year &&
              created.month == current.month;
        })
        .fold(0, (total, order) => total + order.totalAmount);
  }

  int get pendingOrders =>
      orders.where((order) => order.status == 'pending').length;
}
