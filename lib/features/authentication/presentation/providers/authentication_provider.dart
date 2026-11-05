import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show ClientException;

import '../../../../core/services/api_client.dart';
import '../../../../core/services/authentication_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/authentication_remote_datasource.dart';
import '../../data/repositories/authentication_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/avatar_upload.dart';
import '../../domain/repositories/authentication_repository.dart';

enum AuthenticationStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthenticationState {
  const AuthenticationState({
    this.status = AuthenticationStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.successMessage,
  });

  final AuthenticationStatus status;
  final AuthUser? user;
  final String? token;
  final String? errorMessage;
  final String? successMessage;

  bool get isAuthenticated => status == AuthenticationStatus.authenticated;
}

final authenticationServiceProvider = Provider<AuthenticationService>(
  (ref) => AuthenticationService(api: ApiClient.instance),
);

final authenticationRemoteDataSourceProvider =
    Provider<AuthenticationRemoteDataSource>(
      (ref) => AuthenticationRemoteDataSource(
        service: ref.watch(authenticationServiceProvider),
      ),
    );

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(storage: const FlutterSecureStorage()),
);

final authenticationRepositoryProvider = Provider<AuthenticationRepository>(
  (ref) => AuthenticationRepositoryImpl(
    remote: ref.watch(authenticationRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final authenticationProvider =
    NotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
    );

class AuthenticationController extends Notifier<AuthenticationState> {
  @override
  AuthenticationState build() => const AuthenticationState();

  AuthenticationRepository get _repository =>
      ref.read(authenticationRepositoryProvider);

  Future<bool> login({required String email, required String password}) async {
    state = const AuthenticationState(status: AuthenticationStatus.loading);
    try {
      final result = await _repository.login(email.trim(), password);
      state = AuthenticationState(
        status: AuthenticationStatus.authenticated,
        user: result.user,
        token: result.token,
      );
      return true;
    } catch (error) {
      state = AuthenticationState(
        status: AuthenticationStatus.error,
        errorMessage: _messageFor(error),
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    AvatarUpload? avatar,
  }) async {
    state = const AuthenticationState(status: AuthenticationStatus.loading);
    try {
      await _repository.register(
        firstName: firstName.trim(),
        middleName: middleName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        role: role,
        avatar: avatar,
      );
      state = const AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
        successMessage: 'Account created. You can now sign in.',
      );
      return true;
    } catch (error) {
      state = AuthenticationState(
        status: AuthenticationStatus.error,
        errorMessage: _messageFor(error),
      );
      return false;
    }
  }

  Future<void> restoreSession() async {
    if (state.status == AuthenticationStatus.loading) return;
    state = const AuthenticationState(status: AuthenticationStatus.loading);
    try {
      final session = await _repository.restoreSession();
      state = session == null
          ? const AuthenticationState(
              status: AuthenticationStatus.unauthenticated,
            )
          : AuthenticationState(
              status: AuthenticationStatus.authenticated,
              user: session.user,
              token: session.token,
            );
    } on ApiException catch (error) {
      state = error.statusCode == 401
          ? const AuthenticationState(
              status: AuthenticationStatus.unauthenticated,
            )
          : AuthenticationState(
              status: AuthenticationStatus.error,
              errorMessage: _messageFor(error),
            );
    } catch (error) {
      state = AuthenticationState(
        status: AuthenticationStatus.error,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> logout() async {
    state = const AuthenticationState(status: AuthenticationStatus.loading);
    try {
      await _repository.logout();
    } finally {
      state = const AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
      );
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return switch (error.statusCode) {
        400 => error.message,
        401 => 'That email and password combination was not recognized.',
        403 => 'This account does not have access to that area.',
        404 => 'The requested account could not be found.',
        409 => error.message,
        422 => error.message,
        429 => 'Too many attempts. Please wait a moment and try again.',
        >= 500 =>
          'FarmerLink is having trouble right now. Please try again shortly.',
        _ => 'We could not complete that request. Please try again.',
      };
    }
    if (error is TimeoutException) {
      return 'The request timed out. Check your connection and try again.';
    }
    if (error is FormatException) return error.message;
    if (error is ClientException) {
      return 'Could not connect to FarmerLink. Check your internet connection and try again.';
    }
    return 'Something unexpected happened. Please try again.';
  }
}
