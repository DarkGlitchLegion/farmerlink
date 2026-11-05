import 'api_client.dart';

class HarvestBatchesService {
  HarvestBatchesService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> list({int offset = 0, int limit = 100}) => _api.get('/harvest-batches', query: {'offset': offset, 'limit': limit});
  Future<dynamic> get(int id) => _api.get('/harvest-batches/$id');
  Future<dynamic> create(Map<String, dynamic> data) => _api.post('/harvest-batches', body: data);
  Future<dynamic> update(int id, Map<String, dynamic> data) => _api.patch('/harvest-batches/$id', body: data);
  Future<dynamic> delete(int id) => _api.delete('/harvest-batches/$id');
}
