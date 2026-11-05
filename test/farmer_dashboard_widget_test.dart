import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:farmerlink/features/dashboard/data/models/dashboard_models.dart';
import 'package:farmerlink/features/dashboard/domain/repositories/farmer_dashboard_repository.dart';
import 'package:farmerlink/features/dashboard/presentation/pages/farmer_dashboard_page.dart';
import 'package:farmerlink/features/dashboard/presentation/providers/farmer_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _farmer = AuthUser(
  id: 12,
  firstName: 'Ana',
  lastName: 'Santos',
  email: 'ana@example.com',
  role: 'farmer',
  status: 'active',
);

void main() {
  testWidgets('shows real profile fields and a truthful empty batch state', (
    tester,
  ) async {
    final repository = _FakeDashboardRepository(_emptyDashboard());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Ana Santos'), findsOneWidget);
    expect(find.text('Tagum City, Davao del Norte'), findsOneWidget);
    expect(find.text('Verified producer'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No available harvest batches'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No available harvest batches'), findsOneWidget);
    expect(find.text('Not measured by the current API'), findsOneWidget);
    expect(find.text('₱0'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('pull to refresh reloads the dashboard repository', (
    tester,
  ) async {
    final repository = _FakeDashboardRepository(_emptyDashboard());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(repository.loadCount, 1);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(repository.loadCount, 2);
  });
}

Widget _app(_FakeDashboardRepository repository) => ProviderScope(
  overrides: [
    authenticationProvider.overrideWith(_SignedInController.new),
    farmerDashboardRepositoryProvider.overrideWithValue(repository),
  ],
  child: const MaterialApp(home: FarmerDashboardPage()),
);

FarmerDashboardData _emptyDashboard() => FarmerDashboardData(
  user: _farmer,
  profile: const FarmerProfileData(
    farmName: '',
    farmAddress: 'North Road',
    municipality: 'Tagum City',
    province: 'Davao del Norte',
    verificationStatus: 'approved',
  ),
  availableBatches: const [],
  productsById: const {},
  orders: const [],
);

class _SignedInController extends AuthenticationController {
  @override
  AuthenticationState build() => const AuthenticationState(
    status: AuthenticationStatus.authenticated,
    user: _farmer,
    token: 'test-token',
  );
}

class _FakeDashboardRepository implements FarmerDashboardRepository {
  _FakeDashboardRepository(this.data);
  final FarmerDashboardData data;
  int loadCount = 0;

  @override
  Future<FarmerDashboardData> load(AuthUser user) async {
    loadCount++;
    return data;
  }
}
