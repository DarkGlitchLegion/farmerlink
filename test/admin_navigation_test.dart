import 'package:farmerlink/features/admin/presentation/admin_crud_pages.dart';
import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _admin = AuthUser(
  id: 1,
  firstName: 'Ada',
  lastName: 'Admin',
  email: 'ada@example.com',
  role: 'admin',
  status: 'active',
);

void main() {
  testWidgets('admin navigation is icon only and opens the account tab', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard/admin',
      routes: [
        GoRoute(
          path: '/dashboard/admin',
          builder: (context, state) => const AdminDashboardPage(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const AdminProfilePage(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authenticationProvider.overrideWith(_SignedInAdmin.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('')),
      findsNWidgets(5),
    );
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();

    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

class _SignedInAdmin extends AuthenticationController {
  @override
  AuthenticationState build() => const AuthenticationState(
    status: AuthenticationStatus.authenticated,
    user: _admin,
    token: 'test-token',
  );
}
