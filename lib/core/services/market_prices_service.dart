import 'api_client.dart';

class MarketPricesService {
  MarketPricesService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/market-prices', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/market-prices/$id');
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/market-prices', body: data);
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/market-prices/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/market-prices/$id');
}
