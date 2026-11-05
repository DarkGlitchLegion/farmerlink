import '../../../../core/services/api_client.dart';
import '../models/admin_analytics.dart';

class AdminAnalyticsService {
  AdminAnalyticsService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<AdminAnalyticsOverview> getOverview() async {
    final response = await _api.get('/analytics/overview');
    if (response is! Map) {
      throw const FormatException(
        'The analytics endpoint returned invalid data.',
      );
    }
    return AdminAnalyticsOverview.fromJson(
      response.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
