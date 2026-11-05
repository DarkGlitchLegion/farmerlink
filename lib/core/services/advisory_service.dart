import 'api_client.dart';

class AdvisoryService {
  AdvisoryService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/advisories', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/advisories/$id');
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/advisories', body: data);
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/advisories/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/advisories/$id');
}
