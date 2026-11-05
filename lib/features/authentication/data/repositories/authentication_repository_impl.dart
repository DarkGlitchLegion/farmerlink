import '../../../../core/storage/token_storage.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/avatar_upload.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/authentication_remote_datasource.dart';
import '../models/authentication_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  AuthenticationRepositoryImpl({
    required this._remote,
    required this._tokenStorage,
  });

  final AuthenticationRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<({AuthUser user, String token})> login(
    String email,
    String password,
  ) async {
    final response = AuthenticationResponseModel.fromJson(
      Map<String, dynamic>.from(
        await _remote.login(LoginRequestModel(email: email, password: password))
            as Map,
      ),
    );
    try {
      await _tokenStorage.write(response.accessToken);
      _remote.setToken(response.accessToken);
      _remote.setRole(response.user.role);
      _remote.setUserId(response.user.id);
    } catch (_) {
      _remote.setToken(null);
      _remote.setRole(null);
      _remote.setUserId(null);
      rethrow;
    }
    return (user: response.user, token: response.accessToken);
  }

  @override
  Future<AuthUser> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    AvatarUpload? avatar,
  }) async {
    final result = await _remote.register(
      RegisterRequestModel(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      ),
      avatar: avatar,
    );
    if (result is! Map) {
      throw const FormatException(
        'The server returned an invalid registration response.',
      );
    }
    return UserModel.fromJson(Map<String, dynamic>.from(result));
  }

  @override
  Future<({AuthUser user, String token})?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;
    _remote.setToken(token);
    try {
      final result = await _remote.currentUser();
      if (result is! Map) {
        throw const FormatException('Invalid current user response.');
      }
      final user = UserModel.fromJson(Map<String, dynamic>.from(result));
      _remote.setRole(user.role);
      _remote.setUserId(user.id);
      return (user: user, token: token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await logout();
      rethrow;
    } catch (_) {
      _remote.setRole(null);
      _remote.setUserId(null);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    _remote.setToken(null);
    _remote.setRole(null);
    _remote.setUserId(null);
    await _tokenStorage.delete();
  }
}
