import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:farmerlink/features/dashboard/data/models/dashboard_models.dart';
import 'package:farmerlink/features/dashboard/presentation/pages/farmer_workspace_pages.dart';
import 'package:farmerlink/features/dashboard/presentation/providers/farmer_dashboard_provider.dart';
import 'package:farmerlink/features/dashboard/presentation/providers/farmer_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _farmer = AuthUser(
  id: 12,
  firstName: 'Ana',
  lastName: 'Santos',
  email: 'ana@example.com',
  role: 'farmer',
  status: 'active',
);

void main() {
  testWidgets('farmer bottom navigation switches among all five sections', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard/farmer',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              FarmerNavigationShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/farmer',
                  builder: (context, state) =>
                      const FarmerWorkspacePage(section: FarmerSection.home),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/farmer/products',
                  builder: (context, state) => const FarmerWorkspacePage(
                    section: FarmerSection.products,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/farmer/batches',
                  builder: (context, state) =>
                      const FarmerWorkspacePage(section: FarmerSection.batches),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/farmer/orders',
                  builder: (context, state) =>
                      const FarmerWorkspacePage(section: FarmerSection.orders),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/farmer/profile',
                  builder: (context, state) =>
                      const FarmerWorkspacePage(section: FarmerSection.profile),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationProvider.overrideWith(_SignedInController.new),
          farmerWorkspaceProvider.overrideWith(
            (ref) async => const FarmerWorkspaceData(
              products: [],
              categories: [],
              batches: [],
              orders: [],
              notifications: [],
              profile: null,
            ),
          ),
          farmerDashboardProvider.overrideWith(
            (ref) async => FarmerDashboardData(
              user: _farmer,
              availableBatches: const [],
              productsById: const {},
              orders: const [],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Your farm at a glance'), findsOneWidget);
    for (final destination in [
      'My Products',
      'Harvest Batches',
      'Orders',
      'Profile',
      'Home',
    ]) {
      await tester.tap(find.text(destination).last);
      await tester.pumpAndSettle();
      if (destination != 'Home') expect(find.text(destination), findsWidgets);
    }
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

class _SignedInController extends AuthenticationController {
  @override
  AuthenticationState build() => const AuthenticationState(
    status: AuthenticationStatus.authenticated,
    user: _farmer,
    token: 'test-token',
  );
}
