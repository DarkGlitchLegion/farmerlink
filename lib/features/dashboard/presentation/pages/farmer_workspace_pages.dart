import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/crop_report_service.dart';
import '../../../../core/services/harvest_batches_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/product_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/icon_only_navigation_bar.dart';
import '../../../../core/widgets/image_file_picker_field.dart';
import '../../../../core/widgets/base64_image_preview.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../providers/farmer_dashboard_provider.dart';
import '../providers/farmer_workspace_provider.dart';

enum FarmerSection { home, products, batches, orders, profile }

class FarmerNavigationShell extends StatelessWidget {
  const FarmerNavigationShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    IconOnlyNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    IconOnlyNavigationItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
    ),
    IconOnlyNavigationItem(
      icon: Icons.agriculture_outlined,
      activeIcon: Icons.agriculture,
    ),
    IconOnlyNavigationItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
    ),
    IconOnlyNavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: IconOnlyNavigationBar(
      items: _destinations,
      selectedIndex: navigationShell.currentIndex,
      onSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}

class FarmerWorkspacePage extends ConsumerStatefulWidget {
  const FarmerWorkspacePage({super.key, required this.section});
  final FarmerSection section;

  @override
  ConsumerState<FarmerWorkspacePage> createState() =>
      _FarmerWorkspacePageState();
}

class _FarmerWorkspacePageState extends ConsumerState<FarmerWorkspacePage> {
  String _search = '';
  int? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    if (widget.section == FarmerSection.home) return const _FarmerHome();
    final data = ref.watch(farmerWorkspaceProvider);
    final title = switch (widget.section) {
      FarmerSection.home => 'Home',
      FarmerSection.products => 'My Products',
      FarmerSection.batches => 'Harvest Batches',
      FarmerSection.orders => 'Orders',
      FarmerSection.profile => 'Profile',
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/dashboard/farmer/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      floatingActionButton:
          widget.section == FarmerSection.products ||
              widget.section == FarmerSection.batches
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              onPressed: () => context.push(
                widget.section == FarmerSection.products
                    ? '/dashboard/farmer/products/new'
                    : '/dashboard/farmer/batches/new',
              ),
              icon: const Icon(Icons.add),
              label: Text(
                widget.section == FarmerSection.products
                    ? 'Add Product'
                    : 'Add Batch',
              ),
            )
          : null,
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _loadError(error, () => ref.invalidate(farmerWorkspaceProvider)),
        data: (value) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(farmerWorkspaceProvider),
          child: _sectionList(context, value),
        ),
      ),
    );
  }

  Widget _sectionList(BuildContext context, FarmerWorkspaceData data) {
    final rows = switch (widget.section) {
      FarmerSection.products => data.products,
      FarmerSection.batches => data.batches,
      FarmerSection.orders => data.orders,
      _ => <Map<String, dynamic>>[],
    };
    if (widget.section == FarmerSection.profile) {
      return _FarmerProfileView(data: data);
    }
    if (widget.section == FarmerSection.orders) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (final order in rows)
            _RecordCard(
              icon: Icons.receipt_long_outlined,
              title: '${order['order_number'] ?? 'Order #${order['id']}'}',
              subtitle:
                  '₱${order['total_amount'] ?? 0} · ${order['payment_status'] ?? ''}',
              status: '${order['status'] ?? 'pending'}',
              onTap: () => _orderDetails(context, ref, order),
            ),
          if (rows.isEmpty)
            const _EmptyList(
              icon: Icons.shopping_bag_outlined,
              title: 'No farm orders yet',
            ),
        ],
      );
    }
    if (widget.section == FarmerSection.batches) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const _ApiLimitNote(
            'The current public batch list contains available batches only.',
          ),
          for (final batch in rows)
            _RecordCard(
              icon: Icons.agriculture_outlined,
              title: '${batch['batch_code'] ?? 'Batch #${batch['id']}'}',
              subtitle:
                  '${batch['remaining_quantity'] ?? 0} remaining of ${batch['quantity'] ?? 0} · harvested ${_dateLabel(batch['harvest_date'])} · expires ${_dateLabel(batch['expected_expiration_date'])}',
              status: '${batch['status'] ?? ''}',
              onTap: () => _batchActions(context, ref, batch),
            ),
          if (rows.isEmpty)
            const _EmptyList(
              icon: Icons.agriculture_outlined,
              title: 'No available harvest batches',
            ),
        ],
      );
    }
    final visibleProducts = rows.where((product) {
      final haystack = '${product['name'] ?? ''} ${product['variety'] ?? ''}'
          .toLowerCase();
      return haystack.contains(_search.toLowerCase()) &&
          (_categoryFilter == null ||
              _asInt(product['category_id']) == _categoryFilter);
    }).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const _ApiLimitNote(
          'The current public product list contains active products with stock.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search your products',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: _categoryFilter,
          decoration: const InputDecoration(
            labelText: 'Category filter',
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('All categories'),
            ),
            for (final category in data.categories)
              DropdownMenuItem(
                value: _asInt(category['id']),
                child: Text('${category['name']}'),
              ),
          ],
          onChanged: (value) => setState(() => _categoryFilter = value),
        ),
        const SizedBox(height: 12),
        for (final product in visibleProducts)
          _RecordCard(
            icon: Icons.inventory_2_outlined,
            title: '${product['name'] ?? 'Product'}',
            subtitle:
                '₱${product['price_per_unit'] ?? 0} / ${product['unit'] ?? 'unit'} · ${product['available_quantity'] ?? 0} available',
            status: '${product['status'] ?? ''}',
            onTap: () => _productActions(context, ref, product),
          ),
        if (visibleProducts.isEmpty)
          const _EmptyList(
            icon: Icons.inventory_2_outlined,
            title: 'No active products available',
          ),
      ],
    );
  }

  Future<void> _productActions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> product,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _ActionSheet(
        title: '${product['name']}',
        onEdit: () => Navigator.pop(context, 'edit'),
        onDelete: () => Navigator.pop(context, 'delete'),
      ),
    );
    if (action == 'edit' && context.mounted) {
      await context.push(
        '/dashboard/farmer/products/${product['id']}/edit',
        extra: product,
      );
    }
    if (action == 'delete' && context.mounted) {
      final accepted = await _confirmDelete(context, '${product['name']}');
      if (accepted) {
        try {
          await ProductService().delete(_asInt(product['id']));
          ref.invalidate(farmerWorkspaceProvider);
          ref.invalidate(farmerDashboardProvider);
          if (context.mounted) _toast(context, 'Product deleted.');
        } catch (error) {
          if (context.mounted) _toast(context, _errorMessage(error));
        }
      }
    }
  }

  Future<void> _batchActions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> batch,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _ActionSheet(
        title: '${batch['batch_code']}',
        onEdit: () => Navigator.pop(context, 'edit'),
        onDelete: () => Navigator.pop(context, 'delete'),
      ),
    );
    if (action == 'edit' && context.mounted) {
      await context.push(
        '/dashboard/farmer/batches/${batch['id']}/edit',
        extra: batch,
      );
    }
    if (action == 'delete' && context.mounted) {
      final accepted = await _confirmDelete(context, '${batch['batch_code']}');
      if (accepted) {
        try {
          await HarvestBatchesService().delete(_asInt(batch['id']));
          ref.invalidate(farmerWorkspaceProvider);
          ref.invalidate(farmerDashboardProvider);
          if (context.mounted) _toast(context, 'Harvest batch deleted.');
        } catch (error) {
          if (context.mounted) _toast(context, _errorMessage(error));
        }
      }
    }
  }

  Future<void> _orderDetails(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> order,
  ) async {
    final service = OrderService();
    final id = _asInt(order['id']);
    late final List<dynamic> results;
    try {
      results = await Future.wait([service.get(id), service.listItems(id)]);
    } catch (error) {
      if (context.mounted) _toast(context, _errorMessage(error));
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ${results[0] is Map ? results[0]['order_number'] : id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Status: ${order['status']} · Total: ₱${order['total_amount']}',
              ),
              const SizedBox(height: 12),
              if (results[1] is List)
                ...(results[1] as List).map(
                  (item) => Text(
                    'Product ${item['product_id']} · ${item['quantity']} units × ₱${item['unit_price']}',
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final status in const [
                    'confirmed',
                    'processing',
                    'shipped',
                    'delivered',
                  ])
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await service.update(id, {'status': status});
                          ref.invalidate(farmerWorkspaceProvider);
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            _toast(context, 'Order marked $status.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            _toast(context, _errorMessage(error));
                          }
                        }
                      },
                      child: Text(status),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerHome extends ConsumerWidget {
  const _FarmerHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authenticationProvider);
    final user = auth.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hello, ${user?.firstName ?? 'Farmer'}'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
        actions: [
          IconButton(
            onPressed: () => context.push('/dashboard/farmer/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authenticationProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmerDashboardProvider);
          ref.invalidate(farmerWorkspaceProvider);
        },
        child: ref
            .watch(farmerDashboardProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _loadError(error, () {
                ref.invalidate(farmerDashboardProvider);
                ref.invalidate(farmerWorkspaceProvider);
              }),
              data: (data) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    data.profile?.farmName.isNotEmpty == true
                        ? data.profile!.farmName
                        : 'Your farm at a glance',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.profile?.verificationStatus == null
                        ? 'Complete your farm profile to get started.'
                        : 'Profile verification: ${data.profile!.verificationStatus}',
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Metric(
                        label: 'Paid revenue this month',
                        value: '₱${data.monthlyPaidRevenue()}',
                      ),
                      _Metric(
                        label: 'Available batches',
                        value: '${data.availableBatches.length}',
                      ),
                      _Metric(
                        label: 'Pending orders',
                        value: '${data.pendingOrders}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Quick actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickAction(
                        label: 'Add Product',
                        icon: Icons.add_box_outlined,
                        onTap: () =>
                            context.push('/dashboard/farmer/products/new'),
                      ),
                      _QuickAction(
                        label: 'Add Harvest Batch',
                        icon: Icons.agriculture,
                        onTap: () =>
                            context.push('/dashboard/farmer/batches/new'),
                      ),
                      _QuickAction(
                        label: 'View Orders',
                        icon: Icons.shopping_bag_outlined,
                        onTap: () => context.go('/dashboard/farmer/orders'),
                      ),
                      _QuickAction(
                        label: 'My Products',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => context.go('/dashboard/farmer/products'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Recent harvest batches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  for (final batch in data.availableBatches.take(4))
                    ListTile(
                      leading: const Icon(
                        Icons.agriculture,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(batch.batchCode),
                      subtitle: Text(
                        '${batch.remainingQuantity} remaining · ${batch.status}',
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class FarmerRecordFormPage extends ConsumerStatefulWidget {
  const FarmerRecordFormPage({
    super.key,
    required this.kind,
    this.initial,
    this.recordId,
  });
  final String kind;
  final Map<String, dynamic>? initial;
  final int? recordId;
  @override
  ConsumerState<FarmerRecordFormPage> createState() =>
      _FarmerRecordFormPageState();
}

class _FarmerRecordFormPageState extends ConsumerState<FarmerRecordFormPage> {
  final _form = GlobalKey<FormState>();
  final _values = <String, TextEditingController>{};
  bool _saving = false;
  bool _cropReportImageChanged = false;
  int? _categoryId;
  int? _productId;
  String _status = 'active';
  DateTime? _harvestDate, _availableDate, _expiryDate;

  bool get _editing => widget.initial != null || widget.recordId != null;
  bool get _product => widget.kind == 'product';
  bool get _batch => widget.kind == 'batch';
  bool get _cropReport => widget.kind == 'crop_report';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const <String, dynamic>{};
    final fields = _product
        ? [
            'name',
            'description',
            'variety',
            'unit',
            'price_per_unit',
            'available_quantity',
            'minimum_order_quantity',
            'quality_grade',
          ]
        : _batch
        ? ['quantity', 'remaining_quantity', 'harvest_location']
        : _cropReport
        ? ['description', 'image', 'latitude', 'longitude']
        : [
            'farm_name',
            'farm_address',
            'municipality',
            'province',
            'farm_size',
            'latitude',
            'longitude',
          ];
    for (final field in fields) {
      _values[field] = TextEditingController(
        text: initial[field]?.toString() ?? '',
      );
    }
    _categoryId = _asIntOrNull(initial['category_id']);
    _productId = _asIntOrNull(initial['product_id']);
    if (_cropReport) _status = 'submitted';
    _status = _product
        ? initial['status']?.toString() ?? 'active'
        : _batch
        ? initial['status']?.toString() ?? 'available'
        : initial['farming_type']?.toString() ?? 'conventional';
    _harvestDate = _tryDate(initial['harvest_date']);
    _availableDate = _tryDate(initial['available_date']);
    _expiryDate = _tryDate(initial['expected_expiration_date']);
  }

  @override
  void dispose() {
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(farmerWorkspaceProvider);
    final title = _product
        ? (_editing ? 'Edit Product' : 'Add Product')
        : _batch
        ? (_editing ? 'Edit Harvest Batch' : 'Add Harvest Batch')
        : _cropReport
        ? 'Submit Crop Report'
        : (_editing ? 'Edit Farm Profile' : 'Set Up Farm Profile');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _loadError(error, () => ref.invalidate(farmerWorkspaceProvider)),
        data: (workspace) {
          if (_editing && widget.initial == null && !_loadedRecord) {
            final rows = _product
                ? workspace.products
                : _batch
                ? workspace.batches
                : workspace.profile == null
                ? <Map<String, dynamic>>[]
                : [workspace.profile!];
            Map<String, dynamic>? found;
            for (final row in rows) {
              if (_asInt(row['id']) == widget.recordId) {
                found = row;
                break;
              }
            }
            if (found != null) _populateFromRecord(found);
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_product) ..._productFields(workspace),
                if (_batch) ..._batchFields(workspace),
                if (_cropReport) ..._cropReportFields(workspace),
                if (!_product && !_batch && !_cropReport) ..._profileFields(),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _submit(workspace),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _loadedRecord = false;

  void _populateFromRecord(Map<String, dynamic> record) {
    _loadedRecord = true;
    for (final entry in _values.entries) {
      entry.value.text = record[entry.key]?.toString() ?? '';
    }
    _categoryId = _asIntOrNull(record['category_id']);
    _productId = _asIntOrNull(record['product_id']);
    _status = record['status']?.toString() ?? _status;
    if (!_product && !_batch) {
      _status = record['farming_type']?.toString() ?? 'conventional';
    }
    _harvestDate = _tryDate(record['harvest_date']);
    _availableDate = _tryDate(record['available_date']);
    _expiryDate = _tryDate(record['expected_expiration_date']);
  }

  List<Widget> _productFields(FarmerWorkspaceData data) => [
    _text('name', 'Product name', required: true),
    DropdownButtonFormField<int>(
      initialValue: _categoryId,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        for (final item in data.categories)
          DropdownMenuItem(
            value: _asInt(item['id']),
            child: Text('${item['name']}'),
          ),
      ],
      onChanged: (value) => setState(() => _categoryId = value),
      validator: (value) => value == null ? 'Choose a category' : null,
    ),
    _text('description', 'Description', lines: 3),
    _text('variety', 'Variety'),
    _text('unit', 'Unit (kg, bundle, piece…)', required: true),
    _text(
      'price_per_unit',
      'Price per unit (₱)',
      required: true,
      numeric: true,
      decimal: false,
    ),
    _text(
      'available_quantity',
      'Available quantity',
      required: true,
      numeric: true,
      decimal: false,
    ),
    _text(
      'minimum_order_quantity',
      'Minimum order quantity',
      required: true,
      numeric: true,
      decimal: false,
    ),
    _text('quality_grade', 'Quality grade'),
    const _ApiLimitNote(
      'New products are listed as active so they remain available in the farmer product list. Product images are not part of the current API schema.',
    ),
  ];

  List<Widget> _batchFields(FarmerWorkspaceData data) => [
    DropdownButtonFormField<int>(
      initialValue: _productId,
      decoration: const InputDecoration(labelText: 'Your active product'),
      items: [
        for (final item in data.products)
          DropdownMenuItem(
            value: _asInt(item['id']),
            child: Text('${item['name']}'),
          ),
      ],
      onChanged: (value) => setState(() => _productId = value),
      validator: (value) =>
          value == null ? 'Select one of your products' : null,
    ),
    _text(
      'quantity',
      'Harvest quantity',
      required: true,
      numeric: true,
      decimal: false,
    ),
    _text(
      'remaining_quantity',
      'Available quantity',
      required: true,
      numeric: true,
      decimal: false,
    ),
    _text('harvest_location', 'Harvest location', required: true),
    _dateButton('Harvest date', _harvestDate, (value) => _harvestDate = value),
    _dateButton(
      'Available date',
      _availableDate,
      (value) => _availableDate = value,
    ),
    _dateButton(
      'Expected expiry date',
      _expiryDate,
      (value) => _expiryDate = value,
    ),
    const _ApiLimitNote(
      'New batches are listed as available. The public batch endpoint does not return other batch statuses.',
    ),
  ];

  List<Widget> _profileFields() => [
    _text('farm_name', 'Farm name', required: true),
    _text('farm_address', 'Farm address', required: true),
    _text('municipality', 'Municipality', required: true),
    _text('province', 'Province', required: true),
    _text(
      'farm_size',
      'Farm size (hectares)',
      required: true,
      numeric: true,
      decimal: false,
    ),
    DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'Farming type'),
      items: const [
        DropdownMenuItem(value: 'conventional', child: Text('Conventional')),
        DropdownMenuItem(value: 'organic', child: Text('Organic')),
        DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
      ],
      onChanged: (value) => _status = value ?? 'conventional',
    ),
    _text('latitude', 'Latitude'),
    _text('longitude', 'Longitude'),
    if (_editing)
      _ReadOnlyStatus(
        status: '${widget.initial?['verification_status'] ?? 'pending'}',
      ),
  ];

  List<Widget> _cropReportFields(FarmerWorkspaceData data) => [
    DropdownButtonFormField<int>(
      initialValue: _productId,
      decoration: const InputDecoration(labelText: 'Affected product'),
      items: [
        for (final product in data.products)
          DropdownMenuItem(
            value: _asInt(product['id']),
            child: Text('${product['name']}'),
          ),
      ],
      onChanged: (value) => setState(() => _productId = value),
      validator: (value) => value == null ? 'Select an affected product' : null,
    ),
    DropdownButtonFormField<String>(
      initialValue: 'disease',
      decoration: const InputDecoration(labelText: 'Report type'),
      items: const [
        DropdownMenuItem(value: 'disease', child: Text('Disease')),
        DropdownMenuItem(value: 'pest', child: Text('Pest')),
        DropdownMenuItem(value: 'crop_damage', child: Text('Crop damage')),
        DropdownMenuItem(value: 'flooding', child: Text('Flooding')),
      ],
      onChanged: (value) => _selectedReportType = value ?? 'disease',
    ),
    _text('description', 'Describe the crop issue', required: true, lines: 4),
    DropdownButtonFormField<String>(
      initialValue: 'medium',
      decoration: const InputDecoration(labelText: 'Severity'),
      items: const [
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'critical', child: Text('Critical')),
      ],
      onChanged: (value) => _selectedSeverity = value ?? 'medium',
    ),
    ImageFilePickerField(
      label: 'Image (optional)',
      imageData: _value('image').startsWith('data:image/')
          ? _value('image')
          : null,
      existingImage: _value('image').startsWith('data:image/')
          ? null
          : _value('image'),
      onChanged: (value) => setState(() {
        _cropReportImageChanged = true;
        _values['image']!.text = value ?? '';
      }),
    ),
    _text('latitude', 'Latitude (optional)'),
    _text('longitude', 'Longitude (optional)'),
  ];

  String _selectedReportType = 'disease';
  String _selectedSeverity = 'medium';

  Widget _text(
    String key,
    String label, {
    bool required = false,
    bool numeric = false,
    bool decimal = true,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _values[key],
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required';
        if (numeric && text.isNotEmpty) {
          final parsed = decimal ? num.tryParse(text) : int.tryParse(text);
          if (parsed == null) return 'Enter a valid number';
          if (parsed < 0 ||
              (key == 'minimum_order_quantity' && parsed == 0) ||
              (key == 'quantity' && parsed == 0) ||
              (key == 'farm_size' && parsed == 0) ||
              (key == 'available_quantity' && parsed == 0) ||
              (key == 'remaining_quantity' && parsed == 0)) {
            return 'Enter a value greater than zero where required';
          }
        }
        return null;
      },
    ),
  );

  Widget _dateButton(
    String label,
    DateTime? date,
    ValueChanged<DateTime> onSelect,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: () async {
        final value = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (value != null) setState(() => onSelect(value));
      },
      icon: const Icon(Icons.calendar_month_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label: ${date == null ? 'Choose date' : _dateLabel(date.toIso8601String())}',
        ),
      ),
    ),
  );

  Future<void> _submit(FarmerWorkspaceData data) async {
    if (!_form.currentState!.validate()) return;
    if (_batch &&
        (_harvestDate == null ||
            _availableDate == null ||
            _expiryDate == null)) {
      _toast(context, 'Choose all three batch dates.');
      return;
    }
    setState(() => _saving = true);
    try {
      final user = ref.read(authenticationProvider).user!;
      if (_product) {
        final payload = <String, dynamic>{
          'farmer_id': user.id,
          'category_id': _categoryId,
          'name': _value('name'),
          'description': _nullable('description'),
          'variety': _nullable('variety'),
          'unit': _value('unit'),
          'price_per_unit': int.parse(_value('price_per_unit')),
          'available_quantity': int.parse(_value('available_quantity')),
          'minimum_order_quantity': int.parse(_value('minimum_order_quantity')),
          'quality_grade': _nullable('quality_grade'),
          if (!_editing) 'status': 'active',
        };
        if (_editing) {
          payload.remove('farmer_id');
          await ProductService().update(_recordId, payload);
        } else {
          await ProductService().create(payload);
        }
      } else if (_batch) {
        final payload = <String, dynamic>{
          'farmer_id': user.id,
          'product_id': _productId,
          'harvest_date': _harvestDate!.toIso8601String(),
          'available_date': _availableDate!.toIso8601String(),
          'quantity': int.parse(_value('quantity')),
          'remaining_quantity': int.parse(_value('remaining_quantity')),
          'expected_expiration_date': _expiryDate!.toIso8601String(),
          'harvest_location': _value('harvest_location'),
          if (!_editing) 'status': 'available',
        };
        if (int.parse(_value('remaining_quantity')) >
            int.parse(_value('quantity'))) {
          _toast(context, 'Available quantity cannot exceed harvest quantity.');
          return;
        }
        if (_editing) {
          payload.remove('farmer_id');
          payload.remove('product_id');
          await HarvestBatchesService().update(_recordId, payload);
        } else {
          await HarvestBatchesService().create(payload);
        }
      } else if (_cropReport) {
        await CropReportsService().create({
          'farmer_id': user.id,
          'product_id': _productId,
          'report_type': _selectedReportType,
          'description': _value('description'),
          if (_cropReportImageChanged)
            'image': _value('image').isEmpty ? null : _value('image'),
          if (_value('latitude').isNotEmpty) 'latitude': _value('latitude'),
          if (_value('longitude').isNotEmpty) 'longitude': _value('longitude'),
          'severity': _selectedSeverity,
          'status': 'submitted',
        });
      } else {
        final payload = <String, dynamic>{
          'farm_name': _value('farm_name'),
          'farm_address': _value('farm_address'),
          'municipality': _value('municipality'),
          'province': _value('province'),
          'farm_size': int.parse(_value('farm_size')),
          'farming_type': _status,
          if (_value('latitude').isNotEmpty) 'latitude': _value('latitude'),
          if (_value('longitude').isNotEmpty) 'longitude': _value('longitude'),
        };
        final profiles = ProfileService();
        if (_editing) {
          await profiles.updateFarmerProfile(_recordId, payload);
        } else {
          await profiles.createFarmerProfile(payload);
        }
      }
      ref.invalidate(farmerWorkspaceProvider);
      ref.invalidate(farmerDashboardProvider);
      if (mounted) {
        _toast(context, _editing ? 'Changes saved.' : 'Created successfully.');
        context.pop();
      }
    } catch (error) {
      if (mounted) _toast(context, _errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String key) => _values[key]!.text.trim();
  String? _nullable(String key) => _value(key).isEmpty ? null : _value(key);
  int get _recordId => _asInt(widget.initial?['id'] ?? widget.recordId);
}

class FarmerNotificationsPage extends ConsumerWidget {
  const FarmerNotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(farmerWorkspaceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      backgroundColor: AppColors.background,
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _loadError(error, () => ref.invalidate(farmerWorkspaceProvider)),
        data: (workspace) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(farmerWorkspaceProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final notification in workspace.notifications)
                ListTile(
                  leading: Icon(
                    notification['is_read'] == 'read'
                        ? Icons.drafts_outlined
                        : Icons.mark_email_unread_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  title: Text('${notification['title'] ?? 'Notification'}'),
                  subtitle: Text('${notification['message'] ?? ''}'),
                  onTap: () async {
                    try {
                      final id = _asInt(notification['id']);
                      await NotificationService().get(id);
                      if (notification['is_read'] != 'read') {
                        await NotificationService().update(id, {
                          'is_read': 'read',
                        });
                      }
                      ref.invalidate(farmerWorkspaceProvider);
                    } catch (error) {
                      if (context.mounted) {
                        _toast(context, _errorMessage(error));
                      }
                    }
                  },
                ),
              if (workspace.notifications.isEmpty)
                const _EmptyList(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmerCropReportsPage extends ConsumerStatefulWidget {
  const FarmerCropReportsPage({super.key});
  @override
  ConsumerState<FarmerCropReportsPage> createState() =>
      _FarmerCropReportsPageState();
}

class _FarmerCropReportsPageState extends ConsumerState<FarmerCropReportsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await CropReportsService().list(limit: 500);
    if (result is! List) {
      throw const FormatException(
        'The server returned an invalid report list.',
      );
    }
    final userId = ref.read(authenticationProvider).user!.id;
    return result
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => _asInt(row['farmer_id']) == userId)
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('My Crop Reports'),
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.darkGreen,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        await context.push('/dashboard/farmer/crop-reports/new');
        if (mounted) setState(() => _future = _load());
      },
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Submit report'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _loadError(
            snapshot.error!,
            () => setState(() => _future = _load()),
          );
        }
        final reports = snapshot.data ?? const [];
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
            children: [
              for (final report in reports)
                _RecordCard(
                  icon: Icons.report_outlined,
                  title: '${report['report_type'] ?? 'Crop report'}',
                  subtitle: '${report['description'] ?? ''}',
                  status: '${report['status'] ?? ''}',
                  onTap: () async {
                    try {
                      final detail = await CropReportsService().get(
                        _asInt(report['id']),
                      );
                      if (!context.mounted) return;
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => SafeArea(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: detail is Map
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${detail['description'] ?? ''}'),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Severity: ${detail['severity'] ?? ''}',
                                        ),
                                        Text(
                                          'Status: ${detail['status'] ?? ''}',
                                        ),
                                        if (detail['image'] != null &&
                                            '${detail['image']}'.isNotEmpty)
                                          Base64ImagePreview(
                                            label: 'Attached image',
                                            data: '${detail['image']}',
                                          ),
                                      ],
                                    )
                                  : const Text('Report details unavailable.'),
                            ),
                          ),
                        ),
                      );
                    } catch (error) {
                      if (context.mounted) {
                        _toast(context, _errorMessage(error));
                      }
                    }
                  },
                ),
              if (reports.isEmpty)
                const _EmptyList(
                  icon: Icons.report_outlined,
                  title: 'No crop reports submitted',
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _FarmerProfileView extends ConsumerWidget {
  const _FarmerProfileView({required this.data});
  final FarmerWorkspaceData data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user!;
    final profile = data.profile;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(user.email),
                if (user.phone?.isNotEmpty == true) Text(user.phone!),
                const Divider(height: 24),
                if (profile == null)
                  const Text('Your farm profile has not been set up yet.')
                else ...[
                  Text('${profile['farm_name']}'),
                  Text('${profile['farm_address']}'),
                  Text('${profile['municipality']}, ${profile['province']}'),
                  Text('Farm size: ${profile['farm_size']} ha'),
                  Text('Farming type: ${profile['farming_type']}'),
                  _ReadOnlyStatus(
                    status: '${profile['verification_status'] ?? 'pending'}',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push(
            profile == null
                ? '/dashboard/farmer/profile/new'
                : '/dashboard/farmer/profile/${profile['id']}/edit',
            extra: profile,
          ),
          icon: Icon(profile == null ? Icons.add : Icons.edit_outlined),
          label: Text(
            profile == null ? 'Create farm profile' : 'Edit farm profile',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/dashboard/farmer/notifications'),
          icon: const Icon(Icons.notifications_none),
          label: const Text('Notifications'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/dashboard/farmer/crop-reports'),
          icon: const Icon(Icons.report_outlined),
          label: const Text('My Crop Reports'),
        ),
        if (profile != null)
          TextButton.icon(
            onPressed: () async {
              final confirmed = await _confirmDelete(
                context,
                'your farm profile',
              );
              if (!confirmed) return;
              try {
                await ProfileService().deleteFarmerProfile(
                  _asInt(profile['id']),
                );
                ref.invalidate(farmerWorkspaceProvider);
                ref.invalidate(farmerDashboardProvider);
                if (context.mounted) _toast(context, 'Farm profile deleted.');
              } catch (error) {
                if (context.mounted) _toast(context, _errorMessage(error));
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete farm profile'),
          ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.accentGreen.withValues(alpha: .14),
        child: Icon(icon, color: AppColors.primaryGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status,
            style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.onEdit,
    required this.onDelete,
  });
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Wrap(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit'),
          onTap: onEdit,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete'),
          onTap: onDelete,
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width / 2 - 24,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width / 2 - 24,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 54),
    child: Column(
      children: [
        Icon(icon, size: 42, color: AppColors.leafGreen),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      ],
    ),
  );
}

class _ApiLimitNote extends StatelessWidget {
  const _ApiLimitNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.darkGreen.withValues(alpha: .63),
      ),
    ),
  );
}

class _ReadOnlyStatus extends StatelessWidget {
  const _ReadOnlyStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        const Text('Verification: '),
        Chip(label: Text(status)),
      ],
    ),
  );
}

Widget _loadError(Object error, VoidCallback retry) => ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: const EdgeInsets.all(24),
  children: [
    const SizedBox(height: 110),
    const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.leafGreen),
    const SizedBox(height: 12),
    Text(_errorMessage(error), textAlign: TextAlign.center),
    const SizedBox(height: 12),
    Center(
      child: OutlinedButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    ),
  ],
);

Future<bool> _confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Delete $name? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
String _errorMessage(Object error) {
  if (error is ApiException) {
    return switch (error.statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'Your account is not allowed to perform this action.',
      404 => 'This record is no longer available.',
      422 => error.message,
      >= 500 =>
        'FarmerLink is having trouble right now. Please try again shortly.',
      _ => error.message,
    };
  }
  return 'Could not complete that action. Check your connection and try again.';
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _asIntOrNull(dynamic value) => value == null ? null : _asInt(value);
DateTime? _tryDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
String _dateLabel(dynamic value) {
  final date = _tryDate(value);
  return date == null
      ? '—'
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
