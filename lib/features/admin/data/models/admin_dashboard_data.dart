class AdminDashboardData {
  const AdminDashboardData({
    required this.orders,
    required this.pendingProfiles,
    required this.cropReports,
  });

  final List<AdminOrderPreview> orders;
  final List<AdminProfilePreview> pendingProfiles;
  final List<AdminCropReportPreview> cropReports;

  Map<String, dynamic> toJson() => {
    'orders': orders.map((item) => item.toJson()).toList(),
    'pending_profiles': pendingProfiles.map((item) => item.toJson()).toList(),
    'crop_reports': cropReports.map((item) => item.toJson()).toList(),
  };

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        orders: _objects(json['orders'])
            .map(AdminOrderPreview.fromJson)
            .toList(growable: false),
        pendingProfiles: _objects(json['pending_profiles'])
            .map(
              (item) => AdminProfilePreview.fromJson(
                item,
                isBusiness: item['is_business'] == true,
              ),
            )
            .toList(growable: false),
        cropReports: _objects(json['crop_reports'])
            .map(AdminCropReportPreview.fromJson)
            .toList(growable: false),
      );
}

class AdminOrderPreview {
  const AdminOrderPreview({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.totalAmount,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String orderNumber;
  final int buyerId;
  final int totalAmount;
  final String status;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'buyer_id': buyerId,
    'total_amount': totalAmount,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  factory AdminOrderPreview.fromJson(Map<String, dynamic> json) =>
      AdminOrderPreview(
        id: _int(json['id']),
        orderNumber: '${json['order_number'] ?? 'Order #${json['id'] ?? ''}'}',
        buyerId: _int(json['buyer_id']),
        totalAmount: _int(json['total_amount']),
        status: '${json['status'] ?? ''}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      );
}

class AdminProfilePreview {
  const AdminProfilePreview({
    required this.id,
    required this.userId,
    required this.name,
    required this.isBusiness,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String name;
  final bool isBusiness;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'is_business': isBusiness,
    'created_at': createdAt?.toIso8601String(),
  };

  factory AdminProfilePreview.fromJson(
    Map<String, dynamic> json, {
    required bool isBusiness,
  }) => AdminProfilePreview(
    id: _int(json['id']),
    userId: _int(json['user_id']),
    name:
        '${json['name'] ?? json[isBusiness ? 'business_name' : 'farm_name'] ?? 'Profile'}',
    isBusiness: isBusiness,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
  );
}

class AdminCropReportPreview {
  const AdminCropReportPreview({
    required this.id,
    required this.reportType,
    required this.description,
    required this.farmerId,
    required this.severity,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String reportType;
  final String description;
  final int farmerId;
  final String severity;
  final String status;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_type': reportType,
    'description': description,
    'farmer_id': farmerId,
    'severity': severity,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  factory AdminCropReportPreview.fromJson(Map<String, dynamic> json) =>
      AdminCropReportPreview(
        id: _int(json['id']),
        reportType: '${json['report_type'] ?? 'Crop report'}',
        description: '${json['description'] ?? ''}',
        farmerId: _int(json['farmer_id']),
        severity: '${json['severity'] ?? ''}',
        status: '${json['status'] ?? ''}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      );
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

List<Map<String, dynamic>> _objects(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];
