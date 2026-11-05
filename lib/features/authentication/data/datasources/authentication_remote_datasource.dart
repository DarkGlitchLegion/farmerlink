import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/services/authentication_service.dart';
import '../../domain/entities/avatar_upload.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

class AuthenticationRemoteDataSource {
  AuthenticationRemoteDataSource({AuthenticationService? service})
    : _service = service ?? AuthenticationService();

  final AuthenticationService _service;

  Future<dynamic> login(LoginRequestModel request) =>
      _service.login(email: request.email, password: request.password);

  Future<dynamic> register(
    RegisterRequestModel request, {
    AvatarUpload? avatar,
  }) {
    final file = avatar == null
        ? null
        : http.MultipartFile.fromBytes(
            'avatar',
            avatar.bytes,
            filename: avatar.filename,
            contentType: MediaType.parse(avatar.mimeType),
          );
    return _service.register(request.toFields(), avatar: file);
  }

  Future<dynamic> currentUser() => _service.getCurrentUser();

  void setToken(String? token) => _service.setToken(token);
}
