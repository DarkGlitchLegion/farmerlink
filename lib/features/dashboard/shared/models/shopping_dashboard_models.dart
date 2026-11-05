import '../../../authentication/domain/entities/user.dart';

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
DateTime? _dateValue(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

class MarketCategory {
  const MarketCategory({required this.id, required this.name, this.image});
  final int id;
  final String name;
  final String? image;

  factory MarketCategory.fromJson(Map<String, dynamic> json) => MarketCategory(
    id: _intValue(json['id']),
    name: json['name'] as String? ?? 'Category',
    image: json['image'] as String?,
  );
}

class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.farmerId,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.pricePerUnit,
    required this.availableQuantity,
    required this.minimumOrderQuantity,
    required this.status,
    this.variety,
    this.qualityGrade,
    this.description,
  });

  final int id;
  final int farmerId;
  final int categoryId;
  final String name;
  final String unit;
  final int pricePerUnit;
  final int availableQuantity;
  final int minimumOrderQuantity;
  final String status;
  final String? variety;
  final String? qualityGrade;
  final String? description;

  factory MarketProduct.fromJson(Map<String, dynamic> json) => MarketProduct(
    id: _intValue(json['id']),
    farmerId: _intValue(json['farmer_id']),
    categoryId: _intValue(json['category_id']),
    name: json['name'] as String? ?? 'Produce',
    unit: json['unit'] as String? ?? 'unit',
    pricePerUnit: _intValue(json['price_per_unit']),
    availableQuantity: _intValue(json['available_quantity']),
    minimumOrderQuantity: _intValue(json['minimum_order_quantity']),
    status: json['status'] as String? ?? '',
    variety: json['variety'] as String?,
    qualityGrade: json['quality_grade'] as String?,
    description: json['description'] as String?,
  );
}

class ShoppingOrder {
  const ShoppingOrder({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.farmerId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.createdAt,
  });

  final int id;
  final String orderNumber;
  final int buyerId;
  final int farmerId;
  final int totalAmount;
  final String status;
  final String paymentStatus;
  final String fulfillmentStatus;
  final DateTime? createdAt;

  factory ShoppingOrder.fromJson(Map<String, dynamic> json) => ShoppingOrder(
    id: _intValue(json['id']),
    orderNumber: json['order_number'] as String? ?? 'Order ${json['id'] ?? ''}',
    buyerId: _intValue(json['buyer_id']),
    farmerId: _intValue(json['farmer_id']),
    totalAmount: _intValue(json['total_amount']),
    status: json['status'] as String? ?? '',
    paymentStatus: json['payment_status'] as String? ?? '',
    fulfillmentStatus: json['fulfillment_status'] as String? ?? '',
    createdAt: _dateValue(json['created_at']),
  );
}

class AvailableHarvestBatch {
  const AvailableHarvestBatch({
    required this.id,
    required this.farmerId,
    required this.productId,
    required this.batchCode,
    required this.remainingQuantity,
    required this.status,
  });

  final int id;
  final int farmerId;
  final int productId;
  final String batchCode;
  final int remainingQuantity;
  final String status;

  factory AvailableHarvestBatch.fromJson(Map<String, dynamic> json) =>
      AvailableHarvestBatch(
        id: _intValue(json['id']),
        farmerId: _intValue(json['farmer_id']),
        productId: _intValue(json['product_id']),
        batchCode: json['batch_code'] as String? ?? 'Batch ${json['id'] ?? ''}',
        remainingQuantity: _intValue(json['remaining_quantity']),
        status: json['status'] as String? ?? '',
      );
}

class BusinessProfileData {
  const BusinessProfileData({
    required this.businessName,
    required this.businessType,
    required this.businessAddress,
    required this.registrationNumber,
    required this.contactPerson,
    required this.province,
    required this.verificationStatus,
  });

  final String businessName;
  final String businessType;
  final String businessAddress;
  final String registrationNumber;
  final String contactPerson;
  final String province;
  final String verificationStatus;

  factory BusinessProfileData.fromJson(Map<String, dynamic> json) =>
      BusinessProfileData(
        businessName: json['business_name'] as String? ?? '',
        businessType: json['business_type'] as String? ?? '',
        businessAddress: json['business_address'] as String? ?? '',
        registrationNumber:
            json['business_registration_number'] as String? ?? '',
        contactPerson: json['contact_person'] as String? ?? '',
        province: json['province'] as String? ?? '',
        verificationStatus: json['verification_status'] as String? ?? 'pending',
      );
}

class ShoppingNotification {
  const ShoppingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory ShoppingNotification.fromJson(Map<String, dynamic> json) =>
      ShoppingNotification(
        id: _intValue(json['id']),
        title: json['title'] as String? ?? 'Notification',
        message: json['message'] as String? ?? '',
        isRead: json['is_read'] == 'read',
        createdAt: _dateValue(json['created_at']),
      );
}

class ShoppingDashboardData {
  ShoppingDashboardData({
    required this.user,
    required List<MarketProduct> products,
    required List<MarketCategory> categories,
    required List<ShoppingOrder> orders,
    required List<ShoppingNotification> notifications,
    required List<AvailableHarvestBatch> batches,
    this.businessProfile,
  }) : products = List.unmodifiable(products),
       categories = List.unmodifiable(categories),
       orders = List.unmodifiable(orders),
       notifications = List.unmodifiable(notifications),
       batches = List.unmodifiable(batches);

  final AuthUser user;
  final BusinessProfileData? businessProfile;
  final List<MarketProduct> products;
  final List<MarketCategory> categories;
  final List<ShoppingOrder> orders;
  final List<ShoppingNotification> notifications;
  final List<AvailableHarvestBatch> batches;

  int get activeOrders => orders
      .where(
        (order) => const {
          'pending',
          'confirmed',
          'processing',
          'shipped',
        }.contains(order.status),
      )
      .length;

  int get completedOrders =>
      orders.where((order) => order.status == 'delivered').length;

  int get paidPurchases => orders
      .where((order) => order.paymentStatus == 'paid')
      .fold(0, (sum, order) => sum + order.totalAmount);

  int get availableSuppliers =>
      products.map((product) => product.farmerId).toSet().length;

  int get unreadNotifications =>
      notifications.where((notification) => !notification.isRead).length;

  List<ShoppingOrder> get recentOrders {
    final sorted = [...orders]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    return sorted;
  }

  List<MarketProduct> get productsInStock => products
      .where(
        (product) =>
            product.status == 'active' && product.availableQuantity > 0,
      )
      .toList(growable: false);
}
