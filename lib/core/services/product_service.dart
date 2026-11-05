import 'api_client.dart';

class ProductService {
  ProductService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/products', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/products/$id');
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/products', body: data);
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/products/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/products/$id');
}
