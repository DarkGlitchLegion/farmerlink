import 'api_client.dart';

class OrderService {
  OrderService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/orders', body: data);
  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/orders', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/orders/$id');
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/orders/$id', body: data);
  Future<dynamic> listItems(int orderId, {int offset = 0, int limit = 100}) =>
      _api.get('/orders/$orderId/items', query: {'offset': offset, 'limit': limit});
  Future<dynamic> getItem(int itemId) => _api.get('/order-items/$itemId');
}
