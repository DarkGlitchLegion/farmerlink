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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image};
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'category_id': categoryId,
    'name': name,
    'unit': unit,
    'price_per_unit': pricePerUnit,
    'available_quantity': availableQuantity,
    'minimum_order_quantity': minimumOrderQuantity,
    'status': status,
    'variety': variety,
    'quality_grade': qualityGrade,
    'description': description,
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'buyer_id': buyerId,
    'farmer_id': farmerId,
    'total_amount': totalAmount,
    'status': status,
    'payment_status': paymentStatus,
    'fulfillment_status': fulfillmentStatus,
    'created_at': createdAt?.toIso8601String(),
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'product_id': productId,
    'batch_code': batchCode,
    'remaining_quantity': remainingQuantity,
    'status': status,
  };
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

  Map<String, dynamic> toJson() => {
    'business_name': businessName,
    'business_type': businessType,
    'business_address': businessAddress,
    'business_registration_number': registrationNumber,
    'contact_person': contactPerson,
    'province': province,
    'verification_status': verificationStatus,
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'is_read': isRead ? 'read' : 'unread',
    'created_at': createdAt?.toIso8601String(),
  };
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

  Map<String, dynamic> toJson() => {
    'business_profile': businessProfile?.toJson(),
    'products': products.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'orders': orders.map((item) => item.toJson()).toList(),
    'notifications': notifications.map((item) => item.toJson()).toList(),
    'batches': batches.map((item) => item.toJson()).toList(),
  };

  factory ShoppingDashboardData.fromJson(
    Map<String, dynamic> json, {
    required AuthUser user,
  }) => ShoppingDashboardData(
    user: user,
    businessProfile: json['business_profile'] is Map
        ? BusinessProfileData.fromJson(
            Map<String, dynamic>.from(json['business_profile'] as Map),
          )
        : null,
    products: _jsonObjects(json['products'])
        .map(MarketProduct.fromJson)
        .toList(),
    categories: _jsonObjects(json['categories'])
        .map(MarketCategory.fromJson)
        .toList(),
    orders: _jsonObjects(json['orders']).map(ShoppingOrder.fromJson).toList(),
    notifications: _jsonObjects(json['notifications'])
        .map(ShoppingNotification.fromJson)
        .toList(),
    batches: _jsonObjects(json['batches'])
        .map(AvailableHarvestBatch.fromJson)
        .toList(),
  );

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

List<Map<String, dynamic>> _jsonObjects(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];
