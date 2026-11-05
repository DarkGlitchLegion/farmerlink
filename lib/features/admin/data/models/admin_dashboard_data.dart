class AdminDashboardData {
  const AdminDashboardData({
    required this.orders,
    required this.pendingProfiles,
    required this.cropReports,
  });

  final List<AdminOrderPreview> orders;
  final List<AdminProfilePreview> pendingProfiles;
  final List<AdminCropReportPreview> cropReports;
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

  factory AdminProfilePreview.fromJson(
    Map<String, dynamic> json, {
    required bool isBusiness,
  }) => AdminProfilePreview(
    id: _int(json['id']),
    userId: _int(json['user_id']),
    name: '${json[isBusiness ? 'business_name' : 'farm_name'] ?? 'Profile'}',
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
