import 'package:http/http.dart' as http;

import 'api_client.dart';

class AuthenticationService {
  AuthenticationService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<dynamic> register(Map<String, String> fields, {http.MultipartFile? avatar}) =>
      _api.postMultipart('/auth/register', fields: fields, file: avatar);

  Future<dynamic> registerBase64(Map<String, dynamic> data) =>
      _api.post('/auth/register/base64', body: data);

  Future<dynamic> login({required String email, required String password}) async {
    final result = await _api.post('/auth/login', body: {'email': email, 'password': password});
    if (result is Map && result['access_token'] is String) {
      _api.token = result['access_token'] as String;
    }
    return result;
  }

  void setToken(String? token) => _api.token = token;
}
