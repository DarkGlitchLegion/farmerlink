import 'package:farmerlink/core/services/api_client.dart';
import 'package:farmerlink/core/router/app_router.dart';
import 'package:farmerlink/core/storage/token_storage.dart';
import 'package:farmerlink/core/utils/validators.dart';
import 'package:farmerlink/features/authentication/data/datasources/authentication_remote_datasource.dart';
import 'package:farmerlink/features/authentication/data/models/login_request_model.dart';
import 'package:farmerlink/features/authentication/data/models/register_request_model.dart';
import 'package:farmerlink/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/authentication/domain/entities/avatar_upload.dart';
import 'package:farmerlink/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:farmerlink/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('authenticated roles map to their guarded dashboard routes', () {
    expect(roleDashboardLocation('farmer'), '/dashboard/farmer');
    expect(roleDashboardLocation('buyer'), '/dashboard/buyer');
    expect(
      roleDashboardLocation('business_buyer'),
      '/dashboard/business-buyer',
    );
    expect(roleDashboardLocation('admin'), '/dashboard/admin');
  });

  test(
    'router guard protects dashboards and redirects authenticated roles',
    () {
      const unauthenticated = AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
      );
      const initial = AuthenticationState(status: AuthenticationStatus.initial);
      const farmer = AuthUser(
        id: 5,
        firstName: 'Farmer',
        lastName: 'One',
        email: 'farmer@example.com',
        role: 'farmer',
        status: 'active',
      );
      const authenticated = AuthenticationState(
        status: AuthenticationStatus.authenticated,
        user: farmer,
        token: 'token',
      );

      expect(appRouteRedirect(unauthenticated, '/dashboard/farmer'), '/login');
      expect(appRouteRedirect(initial, '/dashboard/farmer'), '/');
      expect(appRouteRedirect(authenticated, '/login'), '/dashboard/farmer');
      expect(
        appRouteRedirect(authenticated, '/dashboard/buyer'),
        '/dashboard/farmer',
      );
      expect(appRouteRedirect(authenticated, '/dashboard/farmer'), isNull);
    },
  );

  test('client turns FastAPI validation details into field messages', () async {
    final client = ApiClient(
      client: MockClient(
        (request) async => http.Response(
          '{"detail":[{"loc":["body","phone"],"msg":"invalid format"}]}',
          422,
        ),
      ),
      baseUrl: 'http://localhost/api/v1',
    );

    await expectLater(
      client.post('/auth/register', body: const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              'phone: invalid format',
            ),
      ),
    );
  });

  test('local validators enforce backend email, phone, and password rules', () {
    expect(AppValidators.email('not-an-email'), isNotNull);
    expect(AppValidators.email('person@example.com'), isNull);
    expect(AppValidators.phone('123'), isNotNull);
    expect(AppValidators.phone('+639123456789'), isNull);
    expect(AppValidators.password('short'), isNotNull);
    expect(AppValidators.password('password8'), isNull);
  });

  group('AuthenticationRepositoryImpl', () {
    test('persists login token and restores current user from API', () async {
      final remote = _FakeRemote();
      final storage = _MemoryTokenStorage();
      final repository = AuthenticationRepositoryImpl(
        remote: remote,
        tokenStorage: storage,
      );

      final result = await repository.login('farmer@example.com', 'password8');
      expect(result.user.role, 'farmer');
      expect(result.token, 'secure-token');
      expect(storage.value, 'secure-token');
      expect(remote.token, 'secure-token');

      final restored = await repository.restoreSession();
      expect(restored?.user.email, 'farmer@example.com');
      expect(restored?.token, 'secure-token');
      expect(remote.currentUserCalls, 1);

      await repository.logout();
      expect(storage.value, isNull);
      expect(remote.token, isNull);
    });

    test(
      'registration sends only supported fields and returns created user',
      () async {
        final remote = _FakeRemote();
        final repository = AuthenticationRepositoryImpl(
          remote: remote,
          tokenStorage: _MemoryTokenStorage(),
        );

        final user = await repository.register(
          firstName: 'Ana',
          middleName: 'Mae',
          lastName: 'Santos',
          email: 'ana@example.com',
          phone: '+639123456789',
          password: 'password8',
          role: 'business_buyer',
        );

        expect(user.role, 'farmer'); // Server response is authoritative.
        expect(remote.registeredFields, {
          'first_name': 'Ana',
          'middle_name': 'Mae',
          'last_name': 'Santos',
          'email': 'ana@example.com',
          'phone': '+639123456789',
          'password': 'password8',
          'role': 'business_buyer',
        });
        expect(remote.token, isNull); // Registration does not create a session.
      },
    );
  });

  group('AuthenticationController', () {
    test('login success updates authenticated state', () async {
      final repository = _FakeRepository();
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authenticationProvider.notifier)
          .login(email: 'farmer@example.com', password: 'password8');
      final state = container.read(authenticationProvider);
      expect(success, isTrue);
      expect(state.status, AuthenticationStatus.authenticated);
      expect(state.user?.role, 'farmer');
      expect(state.token, 'test-token');
    });

    test('invalid credentials show a safe message', () async {
      final repository = _FakeRepository()
        ..loginError = const ApiException(401, 'Invalid email or password');
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authenticationProvider.notifier)
          .login(email: 'farmer@example.com', password: 'wrong');
      expect(success, isFalse);
      expect(
        container.read(authenticationProvider).errorMessage,
        contains('not recognized'),
      );
    });

    test('registration validation errors are surfaced and success is unauthenticated', () async {
      final repository = _FakeRepository()
        ..registerError = const ApiException(422, 'phone: invalid format');
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authenticationProvider.notifier);

      var success = await controller.register(
        firstName: 'Ana',
        middleName: 'Mae',
        lastName: 'Santos',
        email: 'ana@example.com',
        phone: 'bad',
        password: 'password8',
        role: 'farmer',
      );
      expect(success, isFalse);
      expect(
        container.read(authenticationProvider).errorMessage,
        contains('phone'),
      );

      repository.registerError = null;
      success = await controller.register(
        firstName: 'Ana',
        middleName: 'Mae',
        lastName: 'Santos',
        email: 'ana@example.com',
        phone: '+639123456789',
        password: 'password8',
        role: 'farmer',
      );
      expect(success, isTrue);
      expect(
        container.read(authenticationProvider).status,
        AuthenticationStatus.unauthenticated,
      );
      expect(
        container.read(authenticationProvider).successMessage,
        contains('Account created'),
      );
    });

    test('logout clears the authenticated state', () async {
      final repository = _FakeRepository();
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authenticationProvider.notifier)
          .login(email: 'a@b.com', password: 'password8');
      await container.read(authenticationProvider.notifier).logout();

      expect(
        container.read(authenticationProvider).status,
        AuthenticationStatus.unauthenticated,
      );
      expect(repository.loggedOut, isTrue);
    });
  });
}

class _FakeRemote implements AuthenticationRemoteDataSource {
  String? token;
  int currentUserCalls = 0;
  Map<String, String>? registeredFields;

  Map<String, dynamic> get user => {
    'id': 12,
    'first_name': 'Ana',
    'middle_name': 'Mae',
    'last_name': 'Santos',
    'email': 'farmer@example.com',
    'role': 'farmer',
    'status': 'active',
  };

  @override
  Future<dynamic> login(LoginRequestModel request) async => {
    'access_token': 'secure-token',
    'expires_in': 1800,
    'token_type': 'bearer',
    'user': user,
  };

  @override
  Future<dynamic> register(
    RegisterRequestModel request, {
    AvatarUpload? avatar,
  }) async {
    registeredFields = request.toFields();
    return user;
  }

  @override
  Future<dynamic> currentUser() async {
    currentUserCalls++;
    return user;
  }

  @override
  void setToken(String? token) => this.token = token;
}

class _MemoryTokenStorage implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> delete() async => value = null;
}

class _FakeRepository implements AuthenticationRepository {
  Object? loginError;
  Object? registerError;
  bool loggedOut = false;
  final AuthUser user = const AuthUser(
    id: 12,
    firstName: 'Ana',
    lastName: 'Santos',
    email: 'ana@example.com',
    role: 'farmer',
    status: 'active',
  );

  @override
  Future<({AuthUser user, String token})> login(
    String email,
    String password,
  ) async {
    if (loginError != null) throw loginError!;
    return (user: user, token: 'test-token');
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
    if (registerError != null) throw registerError!;
    return user;
  }

  @override
  Future<({AuthUser user, String token})?> restoreSession() async => null;

  @override
  Future<void> logout() async => loggedOut = true;
}
