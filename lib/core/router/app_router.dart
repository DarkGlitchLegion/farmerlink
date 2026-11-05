import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/role_dashboard_page.dart';
import '../../features/authentication/presentation/pages/splash_gate_page.dart';
import '../../features/authentication/presentation/providers/authentication_provider.dart';

String roleDashboardLocation(String role) => switch (role) {
  'farmer' => '/dashboard/farmer',
  'buyer' => '/dashboard/buyer',
  'business_buyer' => '/dashboard/business-buyer',
  'admin' => '/dashboard/admin',
  _ => '/login',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, routeState) {
      final auth = ref.read(authenticationProvider);
      final location = routeState.matchedLocation;
      final isAuthPage = location == '/login' || location == '/register';
      final isDashboard = location.startsWith('/dashboard/');

      if (auth.isAuthenticated) {
        final destination = roleDashboardLocation(auth.user!.role);
        if (isAuthPage || (isDashboard && location != destination)) {
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
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashGatePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard/farmer',
        builder: (context, state) => const RoleDashboardPage(role: 'farmer'),
      ),
      GoRoute(
        path: '/dashboard/buyer',
        builder: (context, state) => const RoleDashboardPage(role: 'buyer'),
      ),
      GoRoute(
        path: '/dashboard/business-buyer',
        builder: (context, state) =>
            const RoleDashboardPage(role: 'business_buyer'),
      ),
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const RoleDashboardPage(role: 'admin'),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
