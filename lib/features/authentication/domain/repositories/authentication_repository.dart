import '../entities/user.dart';
import '../entities/avatar_upload.dart';

abstract interface class AuthenticationRepository {
  Future<({AuthUser user, String token})> login(String email, String password);
  Future<AuthUser> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    AvatarUpload? avatar,
  });
  Future<({AuthUser user, String token})?> restoreSession();
  Future<void> logout();
}
