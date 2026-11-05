import 'api_client.dart';

class CropReportsService {
  CropReportsService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/crop-reports', query: {'offset': offset, 'limit': limit});
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/crop-reports', body: data);
  Future<dynamic> get(int id) => _api.get('/crop-reports/$id');
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/crop-reports/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/crop-reports/$id');
}
