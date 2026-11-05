import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/services/api_client.dart';
import '../../../../../core/services/order_service.dart';
import '../../../../../core/services/profile_service.dart';
import '../../../../../core/services/product_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/storage/dashboard_cache_invalidation.dart';
import '../../../../../core/widgets/icon_only_navigation_bar.dart';
import '../../../../authentication/domain/entities/user.dart';
import '../../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../presentation/widgets/dashboard_stat_card.dart';
import '../../../shared/models/shopping_dashboard_models.dart';
import '../../../shared/providers/shopping_dashboard_provider.dart';
import '../../../shared/widgets/shopping_dashboard_widgets.dart';

class BusinessBuyerDashboardPage extends ConsumerStatefulWidget {
  const BusinessBuyerDashboardPage({super.key});

  @override
  ConsumerState<BusinessBuyerDashboardPage> createState() =>
      _BusinessBuyerDashboardPageState();
}

class _BusinessBuyerDashboardPageState
    extends ConsumerState<BusinessBuyerDashboardPage> {
  int _tab = 0;
  int? _categoryId;
  String _query = '';
  static const _role = 'business_buyer';

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
              final user = ref.read(authenticationProvider).user;
              if (user != null) await invalidateUserDashboardCache(ref, user);
              ref.invalidate(shoppingDashboardProvider(_role));
            },
          ),
        ),
      );

  Future<void> _placeBulkOrder(
    ShoppingDashboardData data,
    MarketProduct product,
  ) async {
    final batches = data.batches
        .where(
          (batch) =>
              batch.productId == product.id &&
              batch.farmerId == product.farmerId &&
              batch.status == 'available' &&
              batch.remainingQuantity > 0,
        )
        .toList();
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There is no available harvest batch for this listing.',
          ),
        ),
      );
      return;
    }
    final order = await showModalBottomSheet<ShoppingOrder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (context) => _BulkOrderSheet(
        product: product,
        batches: batches,
        onSubmit: (batchId, quantity, fulfillmentStatus) => ref
            .read(shoppingDashboardRepositoryProvider)
            .createBulkOrder(
              productId: product.id,
              batchId: batchId,
              quantity: quantity,
              fulfillmentStatus: fulfillmentStatus,
            ),
      ),
    );
    if (order == null || !mounted) return;
    final user = ref.read(authenticationProvider).user;
    if (user != null) {
      await invalidateShopperOrderMutation(
        ref,
        buyer: user,
        farmerId: product.farmerId,
      );
    }
    if (!mounted) return;
    ref.invalidate(shoppingDashboardProvider(_role));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.orderNumber} placed · ${order.status}'),
      ),
    );
  }

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
        bottomNavigationBar: IconOnlyNavigationBar(
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
          items: const [
            IconOnlyNavigationItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
            ),
            IconOnlyNavigationItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
            ),
            IconOnlyNavigationItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
            ),
            IconOnlyNavigationItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
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
    final suppliers = _farmers(data.productsInStock);
    return [
      ShoppingDashboardHeader(
        user: data.user,
        businessMode: true,
        businessProfile: data.businessProfile,
        unreadNotifications: data.unreadNotifications,
        onNotifications: () => _showNotifications(data),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShoppingSectionHeader(title: 'Procurement overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              childAspectRatio: 1.36,
              children: [
                DashboardStatCard(
                  title: 'Active orders',
                  value: '${data.activeOrders}',
                  caption: 'Open and in-progress orders',
                  icon: Icons.local_shipping_outlined,
                ),
                DashboardStatCard(
                  title: 'Total purchased',
                  value: formatShoppingPeso(data.paidPurchases),
                  caption: 'Orders marked paid',
                  icon: Icons.payments_outlined,
                ),
                DashboardStatCard(
                  title: 'Available suppliers',
                  value: '${data.availableSuppliers}',
                  caption: 'Farmer IDs with active listings',
                  icon: Icons.agriculture_outlined,
                ),
              ],
            ),
            const SizedBox(height: 19),
            ShoppingSectionHeader(
              title: 'Wholesale listings',
              actionLabel: 'Browse all',
              onAction: () => setState(() => _tab = 1),
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              const ShoppingEmptyState(
                title: 'No wholesale listings yet',
                message:
                    'Active products with available stock will be listed here.',
              )
            else
              ...products
                  .take(3)
                  .map(
                    (product) => MarketProductCard(
                      key: ValueKey(product.id),
                      product: product,
                      businessMode: true,
                      onTap: () => _showProductDetails(product),
                      onBulkOrder: _hasBatch(data, product)
                          ? () => _placeBulkOrder(data, product)
                          : null,
                    ),
                  ),
            const SizedBox(height: 11),
            ShoppingSectionHeader(
              title: 'Suppliers',
              actionLabel: 'See market',
              onAction: () => setState(() => _tab = 1),
            ),
            const SizedBox(height: 6),
            Text(
              'Only farmer IDs are exposed in product listings. Public farm names and locations are not available.',
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .57),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            if (suppliers.isEmpty)
              const ShoppingEmptyState(
                title: 'No suppliers with available listings',
                message:
                    'Supplier IDs appear when active products are available.',
              )
            else
              ...suppliers.entries
                  .take(3)
                  .map(
                    (entry) => SupplierSummaryCard(
                      farmerId: entry.key,
                      productCount: entry.value,
                    ),
                  ),
            const SizedBox(height: 11),
            ShoppingSectionHeader(
              title: 'Recent orders',
              actionLabel: 'All orders',
              onAction: () => setState(() => _tab = 2),
            ),
            const SizedBox(height: 9),
            if (data.recentOrders.isEmpty)
              const ShoppingEmptyState(
                title: 'No business orders yet',
                message:
                    'Orders placed by this business account will appear here.',
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
            'Source produce for your business',
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
          const SizedBox(height: 10),
          if (_filteredProducts(data).isEmpty)
            const ShoppingEmptyState(
              title: 'No matching listings',
              message: 'Try a different product search or category.',
              icon: Icons.search_off_rounded,
            )
          else
            ..._filteredProducts(data).map(
              (product) => MarketProductCard(
                key: ValueKey(product.id),
                product: product,
                businessMode: true,
                onTap: () => _showProductDetails(product),
                onBulkOrder: _hasBatch(data, product)
                    ? () => _placeBulkOrder(data, product)
                    : null,
              ),
            ),
          const SizedBox(height: 12),
          const ShoppingSectionHeader(title: 'Farmers with active listings'),
          const SizedBox(height: 9),
          ..._farmers(data.productsInStock).entries.map(
            (entry) => SupplierSummaryCard(
              farmerId: entry.key,
              productCount: entry.value,
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
          const ShoppingSectionHeader(title: 'Purchase overview'),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  title: 'Active orders',
                  value: '${data.activeOrders}',
                  caption: 'Open and in-progress',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: DashboardStatCard(
                  title: 'Completed',
                  value: '${data.completedOrders}',
                  caption: 'Delivered orders',
                  icon: Icons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ShoppingSectionHeader(title: 'Business order history'),
          const SizedBox(height: 10),
          if (data.recentOrders.isEmpty)
            const ShoppingEmptyState(
              title: 'No orders yet',
              message: 'Business orders will appear here.',
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShoppingSectionHeader(title: 'Business account'),
          const SizedBox(height: 11),
          _BusinessAccountCard(user: data.user, profile: data.businessProfile),
          OutlinedButton.icon(
            onPressed: () => context.push('/marketplace-info'),
            icon: const Icon(Icons.query_stats_outlined),
            label: const Text('Market prices and advisories'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _editBusinessProfile(data.businessProfile),
            icon: Icon(
              data.businessProfile == null
                  ? Icons.add_business
                  : Icons.edit_outlined,
            ),
            label: Text(
              data.businessProfile == null
                  ? 'Create business profile'
                  : 'Edit business profile',
            ),
          ),
          if (data.businessProfile != null)
            TextButton.icon(
              onPressed: _deleteBusinessProfile,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete business profile'),
            ),
          if (data.businessProfile == null) ...[
            const SizedBox(height: 12),
            const ShoppingEmptyState(
              title: 'Business profile not found',
              message: 'The authenticated account has no business profile response yet.',
              icon: Icons.business_outlined,
            ),
          ],
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

  Future<void> _editBusinessProfile(BusinessProfileData? profile) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BusinessProfileForm(profile: profile),
    );
    if (payload == null || !mounted) return;
    try {
      final service = ProfileService();
      if (profile == null) {
        await service.createBusinessBuyerProfile(payload);
      } else {
        final current = await service.getMyBusinessBuyerProfile();
        await service.updateBusinessBuyerProfile(current['id'] as int, payload);
      }
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _deleteBusinessProfile() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete business profile?'),
            content: const Text('This profile will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      final current = await ProfileService().getMyBusinessBuyerProfile();
      await ProfileService().deleteBusinessBuyerProfile(current['id'] as int);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _showOrderDetails(ShoppingOrder order) async {
    try {
      final results = await Future.wait([
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
                if (results[1] is List)
                  ...(results[1] as List).whereType<Map>().map(
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
                Text(
                  '₱${product.pricePerUnit} / ${product.unit} · minimum ${product.minimumOrderQuantity} ${product.unit}',
                ),
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
      final user = ref.read(authenticationProvider).user;
      if (user != null) {
        await invalidateShopperOrderMutation(
          ref,
          buyer: user,
          farmerId: order.farmerId,
        );
      }
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

  bool _hasBatch(ShoppingDashboardData data, MarketProduct product) =>
      data.batches.any(
        (batch) =>
            batch.productId == product.id &&
            batch.farmerId == product.farmerId &&
            batch.status == 'available' &&
            batch.remainingQuantity > 0,
      );

  Map<int, int> _farmers(List<MarketProduct> products) {
    final result = <int, int>{};
    for (final product in products) {
      result.update(product.farmerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return result;
  }
}

class _BusinessProfileForm extends StatefulWidget {
  const _BusinessProfileForm({this.profile});
  final BusinessProfileData? profile;

  @override
  State<_BusinessProfileForm> createState() => _BusinessProfileFormState();
}

class _BusinessProfileFormState extends State<_BusinessProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _registration;
  late final TextEditingController _contact;
  late final TextEditingController _province;
  late String _type;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile?.businessName ?? '');
    _address = TextEditingController(text: profile?.businessAddress ?? '');
    _registration = TextEditingController(
      text: profile?.registrationNumber ?? '',
    );
    _contact = TextEditingController(text: profile?.contactPerson ?? '');
    _province = TextEditingController(text: profile?.province ?? '');
    _type = profile?.businessType ?? 'restaurant';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _registration.dispose();
    _contact.dispose();
    _province.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.profile == null
                    ? 'Create business profile'
                    : 'Edit business profile',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _field(_name, 'Business name'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Business type'),
                items: const [
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text('Restaurant'),
                  ),
                  DropdownMenuItem(value: 'retailer', child: Text('Retailer')),
                  DropdownMenuItem(
                    value: 'distributor',
                    child: Text('Distributor'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? 'restaurant'),
              ),
              const SizedBox(height: 12),
              _field(_address, 'Business address'),
              _field(_registration, 'Registration number'),
              _field(_contact, 'Contact person'),
              _field(_province, 'Province'),
              if (widget.profile != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Verification: ${widget.profile!.verificationStatus} (read only)',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, {
                    'business_name': _name.text.trim(),
                    'business_type': _type,
                    'business_address': _address.text.trim(),
                    'business_registration_number': _registration.text.trim(),
                    'contact_person': _contact.text.trim(),
                    'province': _province.text.trim(),
                  });
                },
                child: const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value?.trim().isEmpty == true ? '$label is required' : null,
    ),
  );
}

class _BusinessAccountCard extends StatelessWidget {
  const _BusinessAccountCard({required this.user, this.profile});
  final AuthUser user;
  final BusinessProfileData? profile;

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
        _BusinessRow(
          label: 'Business',
          value: profile?.businessName ?? user.fullName,
        ),
        _BusinessRow(label: 'Account name', value: user.fullName),
        _BusinessRow(label: 'Email', value: user.email),
        _BusinessRow(
          label: 'Phone',
          value: user.phone?.isNotEmpty == true ? user.phone! : 'Not provided',
        ),
        if (profile != null) ...[
          _BusinessRow(label: 'Business type', value: profile!.businessType),
          _BusinessRow(label: 'Address', value: profile!.businessAddress),
          _BusinessRow(label: 'Province', value: profile!.province),
          _BusinessRow(label: 'Contact person', value: profile!.contactPerson),
          _BusinessRow(
            label: 'Verification',
            value: profile!.verificationStatus,
          ),
        ],
        _BusinessRow(label: 'Account status', value: user.status),
      ],
    ),
  );
}

class _BusinessRow extends StatelessWidget {
  const _BusinessRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .58),
              fontSize: 11.5,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BulkOrderSheet extends StatefulWidget {
  const _BulkOrderSheet({
    required this.product,
    required this.batches,
    required this.onSubmit,
  });
  final MarketProduct product;
  final List<AvailableHarvestBatch> batches;
  final Future<ShoppingOrder> Function(
    int batchId,
    int quantity,
    String fulfillmentStatus,
  )
  onSubmit;

  @override
  State<_BulkOrderSheet> createState() => _BulkOrderSheetState();
}

class _BulkOrderSheetState extends State<_BulkOrderSheet> {
  late int _batchId = widget.batches.first.id;
  late final TextEditingController _quantity = TextEditingController(
    text: '${widget.product.minimumOrderQuantity}',
  );
  String? _error;
  bool _submitting = false;
  String _fulfillmentStatus = 'pickup';

  AvailableHarvestBatch get _batch =>
      widget.batches.firstWhere((batch) => batch.id == _batchId);
  int get _maximum =>
      math.min(widget.product.availableQuantity, _batch.remainingQuantity);

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_quantity.text);
    if (amount == null || amount < widget.product.minimumOrderQuantity) {
      setState(
        () => _error =
            'Enter at least ${widget.product.minimumOrderQuantity} ${widget.product.unit}.',
      );
      return;
    }
    if (amount > _maximum) {
      setState(
        () => _error =
            'This batch has at most $_maximum ${widget.product.unit} available.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await widget.onSubmit(_batchId, amount, _fulfillmentStatus);
      if (mounted) Navigator.pop(context, order);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException && error.statusCode == 401
            ? 'Your session expired. Sign in again before placing an order.'
            : error is ApiException &&
                  (error.statusCode == 409 || error.statusCode == 422)
            ? error.message
            : 'The order could not be placed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + keyboardInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Place bulk order',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.product.name} · ${formatShoppingPeso(widget.product.pricePerUnit)} / ${widget.product.unit}',
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: _batchId,
                decoration: const InputDecoration(
                  labelText: 'Available harvest batch',
                  border: OutlineInputBorder(),
                ),
                items: widget.batches
                    .map(
                      (batch) => DropdownMenuItem(
                        value: batch.id,
                        child: Text(
                          '${batch.batchCode} · ${batch.remainingQuantity} ${widget.product.unit} left',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _batchId = value;
                          _error = null;
                        });
                      },
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _quantity,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.product.unit})',
                  helperText:
                      'Minimum ${widget.product.minimumOrderQuantity} · Maximum $_maximum',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                initialValue: _fulfillmentStatus,
                decoration: const InputDecoration(
                  labelText: 'Fulfillment method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                  DropdownMenuItem(
                    value: 'farmer_arranged',
                    child: Text('Farmer arranged'),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _fulfillmentStatus = value);
                        }
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFF9B1C1C),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _submitting ||
                          widget.product.minimumOrderQuantity > _maximum
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
