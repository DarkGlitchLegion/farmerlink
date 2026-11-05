import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/crop_report_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../data/models/admin_dashboard_data.dart';
import 'admin_analytics_provider.dart';

final adminDashboardDataProvider =
    FutureProvider.autoDispose<AdminDashboardData>((ref) async {
      final analytics = await ref.watch(adminAnalyticsProvider.future);
      final ordersOffset = math.max(0, (analytics.orders.total ?? 0) - 5);
      final reportsOffset = math.max(0, (analytics.cropReports.total ?? 0) - 5);

      final results = await Future.wait<dynamic>([
        OrderService().list(offset: ordersOffset, limit: 5),
        CropReportsService().list(offset: reportsOffset, limit: 5),
        _pendingProfiles(
          total: analytics.profiles.farmerProfilesTotal ?? 0,
          pendingCount:
              analytics.profiles.farmerProfilesByVerification['pending'] ?? 0,
          loadPage: (offset, limit) =>
              ProfileService().listFarmerProfiles(offset: offset, limit: limit),
        ),
        _pendingProfiles(
          total: analytics.profiles.businessBuyerProfilesTotal ?? 0,
          pendingCount:
              analytics
                  .profiles
                  .businessBuyerProfilesByVerification['pending'] ??
              0,
          loadPage: (offset, limit) => ProfileService()
              .listBusinessBuyerProfiles(offset: offset, limit: limit),
        ),
      ]);

      return AdminDashboardData(
        orders: _rows(results[0])
            .map(AdminOrderPreview.fromJson)
            .toList(growable: false),
        cropReports: _rows(results[1])
            .map(AdminCropReportPreview.fromJson)
            .toList(growable: false),
        pendingProfiles:
            [
              ..._rows(results[2]).map(
                (row) => AdminProfilePreview.fromJson(row, isBusiness: false),
              ),
              ..._rows(results[3]).map(
                (row) => AdminProfilePreview.fromJson(row, isBusiness: true),
              ),
            ]..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            ),
      );
    });

Future<List<Map<String, dynamic>>> _pendingProfiles({
  required int total,
  required int pendingCount,
  required Future<dynamic> Function(int offset, int limit) loadPage,
}) async {
  final pending = <Map<String, dynamic>>[];
  var end = total;
  final target = math.min(pendingCount, 5);
  while (end > 0 && pending.length < target) {
    final start = math.max(0, end - 100);
    final rows = _rows(await loadPage(start, end - start));
    pending.addAll(
      rows.where((row) => row['verification_status'] == 'pending'),
    );
    end = start;
  }
  return pending
    ..sort((a, b) {
      final aDate =
          DateTime.tryParse('${a['created_at'] ?? ''}') ?? DateTime(0);
      final bDate =
          DateTime.tryParse('${b['created_at'] ?? ''}') ?? DateTime(0);
      return bDate.compareTo(aDate);
    })
    ..length = math.min(pending.length, 5);
}

List<Map<String, dynamic>> _rows(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map(
            (row) => row.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList()
    : const [];
