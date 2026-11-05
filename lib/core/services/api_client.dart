import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment.dart';

/// Shared HTTP client for the FarmerLink API.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.token})
    : _client = client ?? http.Client(),
      baseUrl = (baseUrl ?? Environment.apiUrl).replaceFirst(RegExp(r'/$'), '');

  static final ApiClient instance = ApiClient();

  final http.Client _client;
  final String baseUrl;
  String? token;

  Map<String, String> _headers({String? token, bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    'Accept': 'application/json',
    if ((token ?? this.token) != null && (token ?? this.token)!.isNotEmpty)
      'Authorization': 'Bearer ${token ?? this.token}',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = query == null ? null : Map<String, dynamic>.from(query);
    if (normalized != null && normalized['limit'] is num) {
      normalized['limit'] = (normalized['limit'] as num).clamp(1, 500);
    }
    if (normalized != null && normalized['offset'] is num) {
      normalized['offset'] = (normalized['offset'] as num).clamp(0, 1 << 31);
    }
    return Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}').replace(
      queryParameters: normalized?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, String? token}) =>
      _send(_client.get(_uri(path, query), headers: _headers(token: token)));

  Future<dynamic> post(String path, {Object? body, String? token}) => _send(
    _client.post(_uri(path), headers: _headers(token: token), body: jsonEncode(body ?? {})),
  );

  Future<dynamic> patch(String path, {Object? body, String? token}) => _send(
    _client.patch(_uri(path), headers: _headers(token: token), body: jsonEncode(body ?? {})),
  );

  Future<dynamic> delete(String path, {String? token}) =>
      _send(_client.delete(_uri(path), headers: _headers(token: token)));

  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    http.MultipartFile? file,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(token: token, json: false));
    request.fields.addAll(fields);
    if (file != null) request.files.add(file);
    return _send(http.Response.fromStream(await _client.send(request)));
  }

  Future<dynamic> _send(Future<http.Response> request) async {
    final response = await request;
    final text = response.body;
    dynamic data;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } on FormatException {
        data = text;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? (data['detail'] ?? data['message']) : null;
      throw ApiException(response.statusCode, message?.toString() ?? text);
    }
    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
