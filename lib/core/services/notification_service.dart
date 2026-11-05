import 'api_client.dart';

class NotificationService {
  NotificationService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/notifications', query: {'offset': offset, 'limit': limit});
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/notifications', body: data);
  Future<dynamic> get(int id) => _api.get('/notifications/$id');
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/notifications/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/notifications/$id');
}
