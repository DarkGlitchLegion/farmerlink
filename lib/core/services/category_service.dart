import 'api_client.dart';

class CategoryService {
  CategoryService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/categories', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/categories/$id');
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/categories', body: data);
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/categories/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/categories/$id');
}
