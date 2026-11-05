import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/role_dashboard_page.dart';
import '../../features/authentication/presentation/pages/splash_gate_page.dart';
import '../../features/authentication/presentation/providers/authentication_provider.dart';
import '../../features/dashboard/buyer/presentation/pages/buyer_dashboard_page.dart';
import '../../features/dashboard/business_buyer/presentation/pages/business_buyer_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/farmer_workspace_pages.dart';

String roleDashboardLocation(String role) => switch (role) {
  'farmer' => '/dashboard/farmer',
  'buyer' => '/dashboard/buyer',
  'business_buyer' => '/dashboard/business-buyer',
  'admin' => '/dashboard/admin',
  _ => '/login',
};

String? appRouteRedirect(AuthenticationState auth, String location) {
  final isAuthPage = location == '/login' || location == '/register';
  final isDashboard = location.startsWith('/dashboard/');
  if (auth.isAuthenticated) {
    final destination = roleDashboardLocation(auth.user!.role);
    if (destination != '/login' &&
        (isAuthPage ||
            (isDashboard &&
                location != destination &&
                !location.startsWith('$destination/')))) {
      return destination;
    }
  } else if (isDashboard) {
    if (auth.status == AuthenticationStatus.initial ||
        auth.status == AuthenticationStatus.loading) {
      return '/';
    }
    return '/login';
  }
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, routeState) {
      return appRouteRedirect(
        ref.read(authenticationProvider),
        routeState.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashGatePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
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
                routes: [
                  GoRoute(
                    path: 'products/new',
                    builder: (context, state) =>
                        const FarmerRecordFormPage(kind: 'product'),
                  ),
                  GoRoute(
                    path: 'products/:id/edit',
                    builder: (context, state) => FarmerRecordFormPage(
                      kind: 'product',
                      recordId: int.tryParse(state.pathParameters['id'] ?? ''),
                      initial: state.extra as Map<String, dynamic>?,
                    ),
                  ),
                  GoRoute(
                    path: 'batches/new',
                    builder: (context, state) =>
                        const FarmerRecordFormPage(kind: 'batch'),
                  ),
                  GoRoute(
                    path: 'batches/:id/edit',
                    builder: (context, state) => FarmerRecordFormPage(
                      kind: 'batch',
                      recordId: int.tryParse(state.pathParameters['id'] ?? ''),
                      initial: state.extra as Map<String, dynamic>?,
                    ),
                  ),
                  GoRoute(
                    path: 'profile/new',
                    builder: (context, state) =>
                        const FarmerRecordFormPage(kind: 'profile'),
                  ),
                  GoRoute(
                    path: 'profile/:id/edit',
                    builder: (context, state) => FarmerRecordFormPage(
                      kind: 'profile',
                      recordId: int.tryParse(state.pathParameters['id'] ?? ''),
                      initial: state.extra as Map<String, dynamic>?,
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const FarmerNotificationsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/farmer/products',
                builder: (context, state) =>
                    const FarmerWorkspacePage(section: FarmerSection.products),
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
      GoRoute(
        path: '/dashboard/buyer',
        builder: (context, state) => const BuyerDashboardPage(),
      ),
      GoRoute(
        path: '/dashboard/business-buyer',
        builder: (context, state) => const BusinessBuyerDashboardPage(),
      ),
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const RoleDashboardPage(role: 'admin'),
      ),
    ],
  );
  ref.listen(authenticationProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
