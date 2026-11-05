import 'package:farmerlink/features/authentication/domain/entities/user.dart';
import 'package:farmerlink/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:farmerlink/features/dashboard/shared/domain/shopping_dashboard_repository.dart';
import 'package:farmerlink/features/dashboard/shared/models/shopping_dashboard_models.dart';
import 'package:farmerlink/features/dashboard/shared/providers/shopping_dashboard_provider.dart';
import 'package:farmerlink/features/dashboard/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:farmerlink/features/dashboard/business_buyer/presentation/pages/business_buyer_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _buyer = AuthUser(
  id: 12,
  firstName: 'Lia',
  lastName: 'Buyer',
  email: 'lia@example.com',
  role: 'buyer',
  status: 'active',
);
const _businessBuyer = AuthUser(
  id: 13,
  firstName: 'Ben',
  lastName: 'Business',
  email: 'ben@example.com',
  role: 'business_buyer',
  status: 'active',
);

void main() {
  testWidgets('buyer gets buyer navigation, market search, and refresh', (
    tester,
  ) async {
    final repository = _FakeShoppingRepository(_data(_buyer));
    await tester.pumpWidget(
      _app(
        user: _buyer,
        page: const BuyerDashboardPage(),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lia Buyer'), findsOneWidget);
    expect(find.text('Available produce'), findsOneWidget);
    expect(find.text('Cart'), findsNothing);
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('')),
      findsNWidgets(4),
    );

    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Find your fresh picks'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Order history'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, 280));
    await tester.pumpAndSettle();
    expect(repository.loadCount, greaterThanOrEqualTo(2));
  });

  testWidgets(
    'business buyer has distinct wholesale navigation and can place a bulk order',
    (tester) async {
      final repository = _FakeShoppingRepository(
        _data(_businessBuyer, business: true),
      );
      await tester.pumpWidget(
        _app(
          user: _businessBuyer,
          page: const BusinessBuyerDashboardPage(),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ben’s Restaurant Supply'), findsOneWidget);
      expect(find.text('Procurement overview'), findsOneWidget);
      expect(find.text('Available suppliers'), findsOneWidget);
      expect(find.text('Cart'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(''),
        ),
        findsNWidgets(5),
      );

      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Source produce for your business'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Place bulk order'));
      await tester.tap(find.byTooltip('Place bulk order'));
      await tester.pumpAndSettle();
      expect(find.text('Place bulk order'), findsOneWidget);
      expect(find.text('Min. order 5 kg'), findsOneWidget);

      await tester.tap(find.text('Confirm order'));
      await tester.pumpAndSettle();
      expect(repository.bulkOrders, 1);
      expect(repository.lastQuantity, 5);
      expect(find.textContaining('placed'), findsOneWidget);
    },
  );
}

Widget _app({
  required AuthUser user,
  required Widget page,
  required _FakeShoppingRepository repository,
}) => ProviderScope(
  overrides: [
    authenticationProvider.overrideWith(() => _SignedInController(user)),
    shoppingDashboardRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(home: page),
);

ShoppingDashboardData _data(AuthUser user, {bool business = false}) =>
    ShoppingDashboardData(
      user: user,
      products: const [
        MarketProduct(
          id: 5,
          farmerId: 44,
          categoryId: 3,
          name: 'Tomato',
          unit: 'kg',
          pricePerUnit: 85,
          availableQuantity: 90,
          minimumOrderQuantity: 5,
          status: 'active',
          qualityGrade: 'A',
        ),
      ],
      categories: const [MarketCategory(id: 3, name: 'Vegetables')],
      orders: const [],
      notifications: const [],
      batches: business
          ? const [
              AvailableHarvestBatch(
                id: 8,
                farmerId: 44,
                productId: 5,
                batchCode: 'B-8',
                remainingQuantity: 40,
                status: 'available',
              ),
            ]
          : const [],
      businessProfile: business
          ? const BusinessProfileData(
              businessName: 'Ben’s Restaurant Supply',
              businessType: 'restaurant',
              businessAddress: 'Main Street',
              registrationNumber: 'REG-13',
              contactPerson: 'Ben Business',
              province: 'Davao del Norte',
              verificationStatus: 'approved',
            )
          : null,
    );

class _SignedInController extends AuthenticationController {
  _SignedInController(this.user);
  final AuthUser user;

  @override
  AuthenticationState build() => AuthenticationState(
    status: AuthenticationStatus.authenticated,
    user: user,
    token: 'test-token',
  );
}

class _FakeShoppingRepository implements ShoppingDashboardRepository {
  _FakeShoppingRepository(this.data);
  final ShoppingDashboardData data;
  int loadCount = 0;
  int bulkOrders = 0;
  int? lastQuantity;

  @override
  Future<ShoppingDashboardData> load(AuthUser user) async {
    loadCount++;
    return data;
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {}

  @override
  Future<ShoppingOrder> createBulkOrder({
    required int productId,
    required int batchId,
    required int quantity,
    String fulfillmentStatus = 'pickup',
  }) async {
    bulkOrders++;
    lastQuantity = quantity;
    return ShoppingOrder(
      id: 31,
      orderNumber: 'FL-31',
      buyerId: data.user.id,
      farmerId: 44,
      totalAmount: quantity * 85,
      status: 'pending',
      paymentStatus: 'unpaid',
      fulfillmentStatus: fulfillmentStatus,
      createdAt: DateTime.now(),
    );
  }
}
