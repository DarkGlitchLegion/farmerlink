import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/order_service.dart';
import '../../../../../core/services/product_service.dart';
import '../../../../authentication/domain/entities/user.dart';
import '../../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../presentation/widgets/dashboard_stat_card.dart';
import '../../../shared/models/shopping_dashboard_models.dart';
import '../../../shared/providers/shopping_dashboard_provider.dart';
import '../../../shared/widgets/shopping_dashboard_widgets.dart';

class BuyerDashboardPage extends ConsumerStatefulWidget {
  const BuyerDashboardPage({super.key});

  @override
  ConsumerState<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends ConsumerState<BuyerDashboardPage> {
  int _tab = 0;
  int? _categoryId;
  String _query = '';
  static const _role = 'buyer';

  Future<void> _refresh() async {
    try {
      ref.invalidate(shoppingDashboardProvider(_role));
      await ref.read(shoppingDashboardProvider(_role).future);
    } catch (_) {}
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authenticationProvider.notifier).logout();
    } catch (_) {}
    if (mounted) context.go('/login');
  }

  Future<void> _showNotifications(ShoppingDashboardData data) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .68,
          maxChildSize: .9,
          builder: (context, scrollController) => NotificationListSheet(
            notifications: data.notifications,
            onMarkRead: (id) async {
              await ref
                  .read(shoppingDashboardRepositoryProvider)
                  .markNotificationRead(id);
              ref.invalidate(shoppingDashboardProvider(_role));
            },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(shoppingDashboardProvider(_role));
    return dashboard.when(
      loading: () =>
          Scaffold(body: ShoppingDashboardLoading(onRefresh: _refresh)),
      error: (error, stackTrace) => Scaffold(
        body: ShoppingDashboardFailure(
          error: error,
          onRetry: _refresh,
          onSignIn: _signOut,
        ),
      ),
      data: (data) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _tab == 0
            ? null
            : AppBar(
                backgroundColor: AppColors.background,
                title: Text(
                  _tabTitle,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(data),
                    icon: Badge(
                      isLabelVisible: data.unreadNotifications > 0,
                      label: Text('${data.unreadNotifications}'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
        body: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: _tabContent(data),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String get _tabTitle => const ['Home', 'Market', 'Orders', 'Profile'][_tab];

  List<Widget> _tabContent(ShoppingDashboardData data) => switch (_tab) {
    0 => _homeContent(data),
    1 => _marketContent(data),
    2 => _ordersContent(data),
    _ => _profileContent(data),
  };

  List<Widget> _homeContent(ShoppingDashboardData data) {
    final products = _filteredProducts(data);
    final farmers = _farmers(data.productsInStock);
    return [
      ShoppingDashboardHeader(
        user: data.user,
        businessMode: false,
        unreadNotifications: data.unreadNotifications,
        onNotifications: () => _showNotifications(data),
        onSignOut: _signOut,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShoppingSectionHeader(title: 'Browse by category'),
            const SizedBox(height: 10),
            if (data.categories.isEmpty)
              const ShoppingEmptyState(
                title: 'Categories unavailable',
                message: 'The marketplace has not published categories yet.',
              )
            else
              CategoryFilters(
                categories: data.categories,
                selectedId: _categoryId,
                onSelected: (value) => setState(() => _categoryId = value),
              ),
            const SizedBox(height: 20),
            ShoppingSectionHeader(
              title: 'Available produce',
              actionLabel: 'See market',
              onAction: () => setState(() => _tab = 1),
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              const ShoppingEmptyState(
                title: 'No produce listed yet',
                message:
                    'Active products will appear here when farmers have stock.',
              )
            else
              ...products
                  .take(4)
                  .map(
                    (product) => MarketProductCard(
                      key: ValueKey(product.id),
                      product: product,
                      businessMode: false,
                    ),
                  ),
            const SizedBox(height: 10),
            ShoppingSectionHeader(
              title: 'Product sources',
              actionLabel: 'See all',
              onAction: () => setState(() => _tab = 1),
            ),
            const SizedBox(height: 6),
            Text(
              'The public product response includes farmer IDs, but not farm names or locations.',
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .57),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            if (farmers.isEmpty)
              const ShoppingEmptyState(
                title: 'No active farmer listings',
                message:
                    'Farmer sources appear when active products are available.',
              )
            else
              ...farmers.entries
                  .take(3)
                  .map(
                    (entry) => SupplierSummaryCard(
                      farmerId: entry.key,
                      productCount: entry.value,
                    ),
                  ),
            const SizedBox(height: 12),
            ShoppingSectionHeader(
              title: 'Recent orders',
              actionLabel: 'All orders',
              onAction: () => setState(() => _tab = 2),
            ),
            const SizedBox(height: 9),
            if (data.recentOrders.isEmpty)
              const ShoppingEmptyState(
                title: 'No orders yet',
                message: 'Orders placed with this account will appear here.',
                icon: Icons.receipt_long_outlined,
              )
            else
              ...data.recentOrders
                  .take(3)
                  .map(
                    (order) => ShoppingOrderCard(
                      key: ValueKey(order.id),
                      order: order,
                    ),
                  ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    ];
  }

  List<Widget> _marketContent(ShoppingDashboardData data) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your fresh picks',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          MarketSearchField(
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          CategoryFilters(
            categories: data.categories,
            selectedId: _categoryId,
            onSelected: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 18),
          ShoppingSectionHeader(
            title: '${_filteredProducts(data).length} available listings',
          ),
          const SizedBox(height: 11),
          if (_filteredProducts(data).isEmpty)
            const ShoppingEmptyState(
              title: 'No matching produce',
              message: 'Try a different search or category.',
              icon: Icons.search_off_rounded,
            )
          else
            ..._filteredProducts(data).map(
              (product) => MarketProductCard(
                key: ValueKey(product.id),
                product: product,
                businessMode: false,
                onTap: () => _showProductDetails(product),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  ];

  List<Widget> _ordersContent(ShoppingDashboardData data) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShoppingSectionHeader(title: 'Your shopping activity'),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  title: 'Active orders',
                  value: '${data.activeOrders}',
                  caption: 'Pending, confirmed, processing, or shipped',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: DashboardStatCard(
                  title: 'Completed',
                  value: '${data.completedOrders}',
                  caption: 'Orders marked delivered',
                  icon: Icons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          const ShoppingSectionHeader(title: 'Order history'),
          const SizedBox(height: 10),
          if (data.recentOrders.isEmpty)
            const ShoppingEmptyState(
              title: 'No orders yet',
              message: 'Your order history will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...data.recentOrders.map(
              (order) => ShoppingOrderCard(
                key: ValueKey(order.id),
                order: order,
                onTap: () => _showOrderDetails(order),
                onCancel:
                    const {
                      'pending',
                      'confirmed',
                      'processing',
                    }.contains(order.status)
                    ? () => _cancelOrder(order)
                    : null,
              ),
            ),
        ],
      ),
    ),
  ];

  List<Widget> _profileContent(ShoppingDashboardData data) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShoppingSectionHeader(title: 'Your account'),
          const SizedBox(height: 12),
          _AccountDetails(user: data.user),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/marketplace-info'),
            icon: const Icon(Icons.query_stats_outlined),
            label: const Text('Categories, market prices and advisories'),
          ),
          const SizedBox(height: 12),
          const ShoppingEmptyState(
            title: 'Location not provided',
            message: 'Buyer accounts do not include a location in the available API profile.',
            icon: Icons.location_off_outlined,
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    ),
  ];

  Future<void> _showOrderDetails(ShoppingOrder order) async {
    try {
      final values = await Future.wait([
        OrderService().get(order.id),
        OrderService().listItems(order.id),
      ]);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Status: ${order.status} · ${order.fulfillmentStatus}'),
                Text('Total: ₱${order.totalAmount} · ${order.paymentStatus}'),
                const Divider(height: 20),
                if (values[1] is List)
                  ...(values[1] as List).whereType<Map>().map(
                    (item) => Text(
                      'Product ${item['product_id']} · ${item['quantity']} × ₱${item['unit_price']}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _showProductDetails(MarketProduct product) async {
    try {
      final value = await ProductService().get(product.id);
      if (!mounted) return;
      final details = value is Map
          ? Map<String, dynamic>.from(value)
          : const <String, dynamic>{};
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Farmer #${product.farmerId}'),
                Text('₱${product.pricePerUnit} / ${product.unit}'),
                if (details['description'] != null)
                  Text('${details['description']}'),
                if (product.qualityGrade != null)
                  Text('Grade ${product.qualityGrade}'),
                Text('${product.availableQuantity} ${product.unit} available'),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _cancelOrder(ShoppingOrder order) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel order?'),
            content: Text('Cancel ${order.orderNumber}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep order'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel order'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await OrderService().update(order.id, {'status': 'cancelled'});
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order cancelled.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  List<MarketProduct> _filteredProducts(
    ShoppingDashboardData data,
  ) => data.productsInStock.where((product) {
    final matchesCategory =
        _categoryId == null || product.categoryId == _categoryId;
    final searchable = '${product.name} ${product.variety ?? ''}'.toLowerCase();
    return matchesCategory && searchable.contains(_query.trim().toLowerCase());
  }).toList();

  Map<int, int> _farmers(List<MarketProduct> products) {
    final result = <int, int>{};
    for (final product in products) {
      result.update(product.farmerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return result;
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE6EBDD)),
    ),
    child: Column(
      children: [
        _AccountRow(label: 'Name', value: user.fullName),
        _AccountRow(label: 'Email', value: user.email),
        _AccountRow(
          label: 'Phone',
          value: user.phone?.isNotEmpty == true ? user.phone! : 'Not provided',
        ),
        _AccountRow(label: 'Role', value: user.role),
        _AccountRow(label: 'Account status', value: user.status),
      ],
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .58),
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
