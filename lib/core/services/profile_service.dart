import 'api_client.dart';

/// User, farmer profile, and business buyer profile endpoints.
class ProfileService {
  ProfileService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> getMe() => _api.get('/users/me');
  Future<dynamic> listUsers({int offset = 0, int limit = 100}) =>
      _api.get('/users', query: {'offset': offset, 'limit': limit});
  Future<dynamic> createUser(Map<String, dynamic> data) => _api.post('/users', body: data);
  Future<dynamic> getUser(int id) => _api.get('/users/$id');
  Future<dynamic> updateUser(int id, Map<String, dynamic> data) => _api.patch('/users/$id', body: data);
  Future<dynamic> deleteUser(int id) => _api.delete('/users/$id');

  Future<dynamic> getMyFarmerProfile() => _api.get('/farmer-profiles/me');
  Future<dynamic> listFarmerProfiles({int offset = 0, int limit = 100}) =>
      _api.get('/farmer-profiles', query: {'offset': offset, 'limit': limit});
  Future<dynamic> createFarmerProfile(Map<String, dynamic> data) =>
      _api.post('/farmer-profiles', body: data);
  Future<dynamic> getFarmerProfile(int id) => _api.get('/farmer-profiles/$id');
  Future<dynamic> updateFarmerProfile(int id, Map<String, dynamic> data) =>
      _api.patch('/farmer-profiles/$id', body: data);
  Future<dynamic> deleteFarmerProfile(int id) => _api.delete('/farmer-profiles/$id');

  Future<dynamic> getMyBusinessBuyerProfile() => _api.get('/business-buyer-profiles/me');
  Future<dynamic> listBusinessBuyerProfiles({int offset = 0, int limit = 100}) =>
      _api.get('/business-buyer-profiles', query: {'offset': offset, 'limit': limit});
  Future<dynamic> createBusinessBuyerProfile(Map<String, dynamic> data) =>
      _api.post('/business-buyer-profiles', body: data);
  Future<dynamic> getBusinessBuyerProfile(int id) => _api.get('/business-buyer-profiles/$id');
  Future<dynamic> updateBusinessBuyerProfile(int id, Map<String, dynamic> data) =>
      _api.patch('/business-buyer-profiles/$id', body: data);
  Future<dynamic> deleteBusinessBuyerProfile(int id) => _api.delete('/business-buyer-profiles/$id');
}
