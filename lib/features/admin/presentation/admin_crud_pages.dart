import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/advisory_service.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/crop_report_service.dart';
import '../../../core/services/harvest_batches_service.dart';
import '../../../core/services/market_prices_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_only_navigation_bar.dart';
import '../../../core/widgets/image_file_picker_field.dart';
import '../../../core/services/api_client.dart';
import '../../authentication/presentation/providers/authentication_provider.dart';

class AdminModule {
  const AdminModule(this.key, this.title, this.icon, {this.create = true});
  final String key;
  final String title;
  final IconData icon;
  final bool create;
}

const adminModules = <AdminModule>[
  AdminModule('users', 'Users', Icons.people_outline),
  AdminModule('categories', 'Categories', Icons.category_outlined),
  AdminModule('products', 'Products', Icons.inventory_2_outlined),
  AdminModule('harvest-batches', 'Harvest batches', Icons.agriculture_outlined),
  AdminModule('farmer-profiles', 'Farmer profiles', Icons.agriculture_outlined),
  AdminModule(
    'business-buyer-profiles',
    'Business profiles',
    Icons.storefront_outlined,
  ),
  AdminModule('market-prices', 'Market prices', Icons.show_chart),
  AdminModule('advisories', 'Advisories', Icons.campaign_outlined),
  AdminModule(
    'crop-reports',
    'Crop reports',
    Icons.report_gmailerrorred_outlined,
  ),
  AdminModule('notifications', 'Notifications', Icons.notifications_none),
  AdminModule('orders', 'Orders', Icons.shopping_bag_outlined, create: false),
];

Widget _adminBottomNavigationBar(BuildContext context, int selectedIndex) =>
    IconOnlyNavigationBar(
      selectedIndex: selectedIndex,
      onSelected: (index) => context.go(
        const [
          '/dashboard/admin',
          '/dashboard/admin/users',
          '/dashboard/admin/products',
          '/dashboard/admin/crop-reports',
          '/dashboard/admin/profile',
        ][index],
      ),
      items: const [
        IconOnlyNavigationItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
        ),
        IconOnlyNavigationItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        IconOnlyNavigationItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
        ),
        IconOnlyNavigationItem(
          icon: Icons.assessment_outlined,
          activeIcon: Icons.assessment,
        ),
        IconOnlyNavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ],
    );

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _adminBottomNavigationBar(context, 0),
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authenticationProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Welcome, ${user?.firstName ?? 'Admin'}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Manage records supported by the FarmerLink API.'),
          const SizedBox(height: 18),
          for (final module in adminModules)
            Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentGreen.withValues(alpha: .14),
                  child: Icon(module.icon, color: AppColors.primaryGreen),
                ),
                title: Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  module.create
                      ? 'View and manage ${module.title.toLowerCase()}'
                      : 'View and update; order creation is restricted to buyers.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dashboard/admin/${module.key}'),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: AppColors.background,
      ),
      bottomNavigationBar: _adminBottomNavigationBar(context, 4),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(
              user?.firstName.isNotEmpty == true
                  ? user!.firstName[0].toUpperCase()
                  : 'A',
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (user?.email != null)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(user!.email),
            ),
          if (user?.role != null)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(user!.role),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authenticationProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class AdminResourcePage extends ConsumerStatefulWidget {
  const AdminResourcePage({super.key, required this.resource});
  final String resource;
  @override
  ConsumerState<AdminResourcePage> createState() => _AdminResourcePageState();
}

class _AdminResourcePageState extends ConsumerState<AdminResourcePage> {
  static const _limit = 25;
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  int _offset = 0;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await _adminList(widget.resource, _offset, _limit);
    if (result is! List) {
      throw const FormatException('The server returned an invalid list.');
    }
    return result
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  void _reload({int? offset}) {
    setState(() {
      if (offset != null) _offset = offset;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final module = _module(widget.resource);
    if (module == null) {
      return const Scaffold(body: Center(child: Text('Unknown admin module.')));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _adminBottomNavigationBar(
        context,
        switch (widget.resource) {
          'users' => 1,
          'products' => 2,
          'crop-reports' => 3,
          _ => 0,
        },
      ),
      appBar: AppBar(
        title: Text(module.title),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
      ),
      floatingActionButton: module.create
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/dashboard/admin/${widget.resource}/new');
                if (mounted) _reload();
              },
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text('Create ${_singular(module.title)}'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search loaded ${module.title.toLowerCase()}',
                suffixIcon: IconButton(
                  onPressed: () => _reload(),
                  icon: const Icon(Icons.refresh),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _AdminError(error: snapshot.error!, onRetry: _reload);
                }
                _records = snapshot.data ?? const [];
                final query = _searchController.text.trim().toLowerCase();
                final visible = query.isEmpty
                    ? _records
                    : _records
                          .where(
                            (row) => row.values.any(
                              (value) => '$value'.toLowerCase().contains(query),
                            ),
                          )
                          .toList();
                if (_records.isEmpty) {
                  return _AdminEmpty(
                    label: module.title,
                    onCreate: module.create
                        ? () async {
                            await context.push(
                              '/dashboard/admin/${widget.resource}/new',
                            );
                            if (mounted) _reload();
                          }
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    children: [
                      for (final row in visible)
                        Card(
                          color: Colors.white,
                          child: ListTile(
                            onTap: () async {
                              await context.push(
                                '/dashboard/admin/${widget.resource}/${row['id']}',
                              );
                              if (mounted) _reload();
                            },
                            leading: Icon(
                              module.icon,
                              color: AppColors.primaryGreen,
                            ),
                            title: Text(
                              _recordTitle(widget.resource, row),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _recordSubtitle(row),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'No results match your search.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _offset == 0
                                ? null
                                : () => _reload(
                                    offset: (_offset - _limit).clamp(
                                      0,
                                      1 << 31,
                                    ),
                                  ),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Page ${_offset ~/ _limit + 1}'),
                          IconButton(
                            onPressed: _records.length < _limit
                                ? null
                                : () => _reload(offset: _offset + _limit),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      if (const {
                        'products',
                        'harvest-batches',
                        'advisories',
                      }.contains(widget.resource))
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'The API applies public catalog filters to these list endpoints, so some records may not appear in this list.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminRecordDetailPage extends ConsumerStatefulWidget {
  const AdminRecordDetailPage({
    super.key,
    required this.resource,
    required this.id,
  });
  final String resource;
  final int id;
  @override
  ConsumerState<AdminRecordDetailPage> createState() =>
      _AdminRecordDetailPageState();
}

class _AdminRecordDetailPageState extends ConsumerState<AdminRecordDetailPage> {
  late Future<dynamic> _future;
  @override
  void initState() {
    super.initState();
    _future = _adminGet(widget.resource, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final module = _module(widget.resource);
    if (module == null) {
      return const Scaffold(body: Center(child: Text('Unknown admin module.')));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _adminBottomNavigationBar(
        context,
        switch (widget.resource) {
          'users' => 1,
          'products' => 2,
          'crop-reports' => 3,
          _ => 0,
        },
      ),
      appBar: AppBar(
        title: Text('${_singular(module.title)} details'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
      ),
      body: FutureBuilder<dynamic>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AdminError(
              error: snapshot.error!,
              onRetry: () => setState(
                () => _future = _adminGet(widget.resource, widget.id),
              ),
            );
          }
          if (snapshot.data is! Map) {
            return const Center(child: Text('Invalid record response.'));
          }
          final record = Map<String, dynamic>.from(snapshot.data as Map);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recordTitle(widget.resource, record),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const Divider(height: 24),
                      for (final entry in record.entries)
                        if (!{'avatar'}.contains(entry.key))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              '${_humanize(entry.key)}: ${entry.value ?? '—'}',
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (widget.resource == 'orders') ..._orderItems(context),
              const SizedBox(height: 12),
              if (widget.resource != 'orders')
                FilledButton.icon(
                  onPressed: () => _edit(record),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit record'),
                ),
              if (widget.resource != 'orders')
                OutlinedButton.icon(
                  onPressed: () => _delete(context, record),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete record'),
                ),
              if (widget.resource == 'orders')
                FilledButton.icon(
                  onPressed: () => _edit(record),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update order'),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _orderItems(BuildContext context) => [
    const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        'Order items',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
    ),
    FutureBuilder<dynamic>(
      future: OrderService().listItems(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) return Text(_friendlyError(snapshot.error!));
        final items = snapshot.data is List ? snapshot.data as List : const [];
        return Column(
          children: [
            for (final item in items)
              if (item is Map)
                ListTile(
                  title: Text(
                    'Product ${item['product_id']} · Batch ${item['harvest_batch_id']}',
                  ),
                  subtitle: Text(
                    '${item['quantity']} × ₱${item['unit_price']}',
                  ),
                ),
          ],
        );
      },
    ),
  ];

  Future<void> _edit(Map<String, dynamic> record) async {
    await context.push(
      '/dashboard/admin/${widget.resource}/${widget.id}/edit',
      extra: record,
    );
    if (mounted) {
      setState(() => _future = _adminGet(widget.resource, widget.id));
    }
  }

  Future<void> _delete(
    BuildContext context,
    Map<String, dynamic> record,
  ) async {
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete record?'),
            content: Text(
              'Permanently delete ${_recordTitle(widget.resource, record)}?',
            ),
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
    if (!yes) return;
    try {
      await _adminDelete(widget.resource, widget.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Record deleted.')));
        context.pop();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }
}

class AdminRecordFormPage extends ConsumerStatefulWidget {
  const AdminRecordFormPage({
    super.key,
    required this.resource,
    this.id,
    this.initial,
  });
  final String resource;
  final int? id;
  final Map<String, dynamic>? initial;
  @override
  ConsumerState<AdminRecordFormPage> createState() =>
      _AdminRecordFormPageState();
}

class _AdminRecordFormPageState extends ConsumerState<AdminRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _selected = {};
  bool _saving = false;
  bool _imageChanged = false;
  late Future<Map<String, List<Map<String, dynamic>>>> _lookups;
  Map<String, dynamic>? _loadedRecord;

  bool get _editing => widget.id != null;
  List<_FieldSpec> get _fields => _resourceFields(widget.resource, _editing);

  @override
  void initState() {
    super.initState();
    _loadedRecord = widget.initial;
    for (final field in _fields) {
      _controllers[field.key] = TextEditingController(
        text: field.key == 'image'
            ? ''
            : widget.initial?[field.key]?.toString() ?? '',
      );
      if (field.choices != null && widget.initial?[field.key] != null) {
        _selected[field.key] = widget.initial![field.key];
      }
    }
    _lookups = _loadLookups();
    if (_editing && _loadedRecord == null) _loadRecord();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecord() async {
    try {
      final value = await _adminGet(widget.resource, widget.id!);
      if (value is Map && mounted) {
        setState(() {
          _loadedRecord = Map<String, dynamic>.from(value);
          for (final field in _fields) {
            _controllers[field.key]?.text = field.key == 'image'
                ? ''
                : value[field.key]?.toString() ?? '';
            if (field.choices != null) _selected[field.key] = value[field.key];
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => _recordError = error);
    }
  }

  Object? _recordError;

  Future<Map<String, List<Map<String, dynamic>>>> _loadLookups() async {
    final results = await Future.wait<dynamic>([
      ProfileService().listUsers(limit: 500),
      CategoryService().list(limit: 500),
      ProductService().list(limit: 500),
    ]);
    List<Map<String, dynamic>> map(dynamic value) => value is List
        ? value
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
        : <Map<String, dynamic>>[];
    return {
      'users': map(results[0]),
      'categories': map(results[1]),
      'products': map(results[2]),
    };
  }

  @override
  Widget build(BuildContext context) {
    final module = _module(widget.resource);
    if (module == null || (widget.resource == 'orders' && !_editing)) {
      return const Scaffold(
        body: Center(child: Text('This admin operation is not available.')),
      );
    }
    if (_recordError != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit ${_singular(module.title)}')),
        body: _AdminError(error: _recordError!, onRetry: _loadRecord),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _adminBottomNavigationBar(
        context,
        switch (widget.resource) {
          'users' => 1,
          'products' => 2,
          'crop-reports' => 3,
          _ => 0,
        },
      ),
      appBar: AppBar(
        title: Text(
          '${_editing ? 'Edit' : 'Create'} ${_singular(module.title)}',
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _lookups,
        builder: (context, lookupsSnapshot) {
          if (lookupsSnapshot.hasError) {
            return _AdminError(
              error: lookupsSnapshot.error!,
              onRetry: () => setState(() => _lookups = _loadLookups()),
            );
          }
          if (!lookupsSnapshot.hasData || (_editing && _loadedRecord == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          final lookups = lookupsSnapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final field in _fields) _fieldWidget(field, lookups),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
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

  Widget _fieldWidget(
    _FieldSpec field,
    Map<String, List<Map<String, dynamic>>> lookups,
  ) {
    if (field.key == 'image') {
      final savedImage = (_loadedRecord?['image'] ?? widget.initial?['image'])
          ?.toString();
      final savedImageIsDataUrl = savedImage?.startsWith('data:image/') == true;
      return ImageFilePickerField(
        label: '${field.label}${field.required ? ' *' : ''}',
        imageData: _imageChanged
            ? _controllers['image']!.text
            : savedImageIsDataUrl
            ? savedImage
            : null,
        existingImage: _imageChanged || savedImageIsDataUrl ? null : savedImage,
        onChanged: (value) => setState(() {
          _imageChanged = true;
          _controllers['image']!.text = value ?? '';
        }),
      );
    }
    if (field.choices != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: DropdownButtonFormField<String>(
          initialValue: _selected[field.key] as String?,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final choice in field.choices!)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: (value) => setState(() => _selected[field.key] = value),
          validator: field.required
              ? (value) => value == null ? '${field.label} is required' : null
              : null,
        ),
      );
    }
    if (field.lookup != null) {
      final all = lookups[field.lookup!] ?? [];
      final options = field.userRole == null
          ? all
          : all.where((row) => row['role'] == field.userRole).toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: DropdownButtonFormField<int>(
          initialValue: _asIntOrNull(
            _selected[field.key] ?? widget.initial?[field.key],
          ),
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final row in options)
              DropdownMenuItem(
                value: _asInt(row['id']),
                child: Text(
                  '${row[field.lookup == 'users' ? 'email' : 'name'] ?? row['id']}',
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selected[field.key] = value),
          validator: field.required
              ? (value) =>
                    value == null ? 'Select ${field.label.toLowerCase()}' : null
              : null,
        ),
      );
    }
    final controller = _controllers[field.key]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        readOnly: field.date,
        maxLines: field.multiline ? 4 : 1,
        keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: '${field.label}${field.required ? ' *' : ''}',
          filled: true,
          fillColor: Colors.white,
          suffixIcon: field.date
              ? const Icon(Icons.calendar_month_outlined)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        ),
        onTap: field.date
            ? () async {
                final current =
                    DateTime.tryParse(controller.text) ?? DateTime.now();
                final selected = await showDatePicker(
                  context: context,
                  initialDate: current,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) {
                  controller.text = selected.toIso8601String();
                }
              }
            : null,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (field.required && text.isEmpty) {
            return '${field.label} is required';
          }
          if (text.isNotEmpty && field.numeric && int.tryParse(text) == null) {
            return 'Enter a whole number';
          }
          if (text.isNotEmpty &&
              field.date &&
              DateTime.tryParse(text) == null) {
            return 'Enter a valid ISO date and time';
          }
          if (field.key == 'password' && text.length < 8) {
            return 'Password must be at least 8 characters';
          }
          if (field.key == 'email' &&
              text.isNotEmpty &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
            return 'Enter a valid email address';
          }
          if (field.key == 'phone' &&
              text.isNotEmpty &&
              !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text)) {
            return 'Use 7 to 15 digits, optionally starting with +';
          }
          if (field.numeric && text.isNotEmpty) {
            final number = int.tryParse(text);
            if ((field.key == 'minimum_order_quantity' ||
                    field.key == 'quantity' ||
                    field.key == 'farm_size') &&
                (number == null || number <= 0)) {
              return 'Enter a value greater than zero';
            }
            if (number != null && number < 0) {
              return 'Enter a non-negative value';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      for (final field in _fields) {
        if (field.key == 'image') {
          if (_imageChanged) {
            payload['image'] = _controllers['image']!.text.isEmpty
                ? null
                : _controllers['image']!.text;
          }
          continue;
        }
        if (field.choices != null || field.lookup != null) {
          if (_selected[field.key] != null) {
            payload[field.key] = _selected[field.key];
          }
        } else {
          final value = _controllers[field.key]!.text.trim();
          if (value.isNotEmpty) {
            payload[field.key] = field.numeric ? int.parse(value) : value;
          }
        }
      }
      if (widget.resource == 'market-prices') payload.remove('verified_by');
      if (_editing) {
        await _adminUpdate(widget.resource, widget.id!, payload);
      } else {
        await _adminCreate(widget.resource, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_singular(_module(widget.resource)!.title)} saved.',
            ),
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FieldSpec {
  const _FieldSpec(
    this.key,
    this.label, {
    this.required = false,
    this.numeric = false,
    this.multiline = false,
    this.date = false,
    this.choices,
    this.lookup,
    this.userRole,
  });
  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final bool multiline;
  final bool date;
  final List<String>? choices;
  final String? lookup;
  final String? userRole;
}

List<_FieldSpec> _resourceFields(
  String resource,
  bool editing,
) => switch (resource) {
  'users' => [
    const _FieldSpec('first_name', 'First name', required: true),
    const _FieldSpec('middle_name', 'Middle name'),
    const _FieldSpec('last_name', 'Last name', required: true),
    const _FieldSpec('email', 'Email', required: true),
    const _FieldSpec('phone', 'Phone', required: true),
    if (!editing) const _FieldSpec('password', 'Password', required: true),
    const _FieldSpec(
      'role',
      'Role',
      required: true,
      choices: ['admin', 'farmer', 'buyer', 'business_buyer'],
    ),
    const _FieldSpec(
      'status',
      'Status',
      required: true,
      choices: ['active', 'suspended', 'pending'],
    ),
  ],
  'categories' => [
    const _FieldSpec('name', 'Name', required: true),
    const _FieldSpec('description', 'Description', multiline: true),
    const _FieldSpec('image', 'Image'),
  ],
  'products' => [
    const _FieldSpec(
      'farmer_id',
      'Farmer',
      required: true,
      lookup: 'users',
      userRole: 'farmer',
    ),
    const _FieldSpec(
      'category_id',
      'Category',
      required: true,
      lookup: 'categories',
    ),
    const _FieldSpec('name', 'Name', required: true),
    const _FieldSpec('description', 'Description', multiline: true),
    const _FieldSpec('variety', 'Variety'),
    const _FieldSpec('unit', 'Unit', required: true),
    const _FieldSpec(
      'price_per_unit',
      'Price per unit',
      required: true,
      numeric: true,
    ),
    const _FieldSpec(
      'available_quantity',
      'Available quantity',
      required: true,
      numeric: true,
    ),
    const _FieldSpec(
      'minimum_order_quantity',
      'Minimum order quantity',
      required: true,
      numeric: true,
    ),
    const _FieldSpec('quality_grade', 'Quality grade'),
    const _FieldSpec(
      'status',
      'Status',
      required: true,
      choices: ['draft', 'active', 'sold_out', 'archived'],
    ),
  ],
  'harvest-batches' => [
    const _FieldSpec(
      'farmer_id',
      'Farmer',
      required: true,
      lookup: 'users',
      userRole: 'farmer',
    ),
    const _FieldSpec(
      'product_id',
      'Product',
      required: true,
      lookup: 'products',
    ),
    const _FieldSpec('batch_code', 'Batch code', required: true),
    const _FieldSpec(
      'harvest_date',
      'Harvest date (ISO)',
      required: true,
      date: true,
    ),
    const _FieldSpec(
      'available_date',
      'Available date (ISO)',
      required: true,
      date: true,
    ),
    const _FieldSpec('quantity', 'Quantity', required: true, numeric: true),
    const _FieldSpec(
      'remaining_quantity',
      'Remaining quantity',
      required: true,
      numeric: true,
    ),
    const _FieldSpec(
      'expected_expiration_date',
      'Expected expiry (ISO)',
      required: true,
      date: true,
    ),
    const _FieldSpec('harvest_location', 'Harvest location', required: true),
    const _FieldSpec(
      'status',
      'Status',
      required: true,
      choices: ['upcoming', 'available', 'reserved', 'completed', 'expired'],
    ),
  ],
  'farmer-profiles' => [
    const _FieldSpec(
      'user_id',
      'Farmer account',
      required: true,
      lookup: 'users',
      userRole: 'farmer',
    ),
    const _FieldSpec('farm_name', 'Farm name', required: true),
    const _FieldSpec('farm_address', 'Farm address', required: true),
    const _FieldSpec('municipality', 'Municipality', required: true),
    const _FieldSpec('province', 'Province', required: true),
    const _FieldSpec('farm_size', 'Farm size', required: true, numeric: true),
    const _FieldSpec(
      'farming_type',
      'Farming type',
      required: true,
      choices: ['organic', 'conventional', 'mixed'],
    ),
    const _FieldSpec(
      'verification_status',
      'Verification',
      required: true,
      choices: ['pending', 'approved', 'rejected'],
    ),
    const _FieldSpec('latitude', 'Latitude'),
    const _FieldSpec('longitude', 'Longitude'),
  ],
  'business-buyer-profiles' => [
    const _FieldSpec(
      'user_id',
      'Business buyer account',
      required: true,
      lookup: 'users',
      userRole: 'business_buyer',
    ),
    const _FieldSpec('business_name', 'Business name', required: true),
    const _FieldSpec(
      'business_type',
      'Business type',
      required: true,
      choices: ['restaurant', 'retailer', 'distributor'],
    ),
    const _FieldSpec('business_address', 'Business address', required: true),
    const _FieldSpec(
      'business_registration_number',
      'Registration number',
      required: true,
    ),
    const _FieldSpec('contact_person', 'Contact person', required: true),
    const _FieldSpec('province', 'Province', required: true),
    const _FieldSpec(
      'verification_status',
      'Verification',
      required: true,
      choices: ['pending', 'approved', 'rejected'],
    ),
  ],
  'market-prices' => [
    const _FieldSpec(
      'product_id',
      'Product',
      required: true,
      lookup: 'products',
    ),
    const _FieldSpec('market_name', 'Market name', required: true),
    const _FieldSpec('municipality', 'Municipality', required: true),
    const _FieldSpec(
      'price_min',
      'Minimum price',
      required: true,
      numeric: true,
    ),
    const _FieldSpec(
      'price_max',
      'Maximum price',
      required: true,
      numeric: true,
    ),
    const _FieldSpec(
      'average_price',
      'Average price',
      required: true,
      numeric: true,
    ),
    const _FieldSpec('unit', 'Unit', required: true),
    const _FieldSpec(
      'recorded_date',
      'Recorded date (ISO)',
      required: true,
      date: true,
    ),
  ],
  'advisories' => [
    const _FieldSpec('title', 'Title', required: true),
    const _FieldSpec('content', 'Content', required: true, multiline: true),
    const _FieldSpec(
      'category',
      'Category',
      required: true,
      choices: [
        'crop',
        'livestock',
        'pest_control',
        'weather',
        'pest',
        'disease',
        'planting',
        'government_assistance',
      ],
    ),
    const _FieldSpec('municipality', 'Municipality', required: true),
    const _FieldSpec(
      'severity',
      'Severity',
      required: true,
      choices: ['low', 'medium', 'high'],
    ),
    const _FieldSpec(
      'published_at',
      'Published at (ISO)',
      required: true,
      date: true,
    ),
    const _FieldSpec('expired_at', 'Expires at (ISO)', date: true),
    const _FieldSpec(
      'status',
      'Status',
      required: true,
      choices: ['draft', 'published', 'archived'],
    ),
  ],
  'crop-reports' => [
    const _FieldSpec(
      'farmer_id',
      'Farmer',
      required: true,
      lookup: 'users',
      userRole: 'farmer',
    ),
    const _FieldSpec(
      'product_id',
      'Product',
      required: true,
      lookup: 'products',
    ),
    const _FieldSpec(
      'report_type',
      'Report type',
      required: true,
      choices: ['disease', 'pest', 'crop_damage', 'flooding'],
    ),
    const _FieldSpec(
      'description',
      'Description',
      required: true,
      multiline: true,
    ),
    const _FieldSpec('image', 'Image'),
    const _FieldSpec('latitude', 'Latitude'),
    const _FieldSpec('longitude', 'Longitude'),
    const _FieldSpec(
      'severity',
      'Severity',
      required: true,
      choices: ['low', 'medium', 'high', 'critical'],
    ),
    const _FieldSpec(
      'status',
      'Status',
      required: true,
      choices: ['submitted', 'reviewing', 'resolved'],
    ),
  ],
  'notifications' => [
    const _FieldSpec('user_id', 'Recipient', required: true, lookup: 'users'),
    const _FieldSpec('title', 'Title', required: true),
    const _FieldSpec('message', 'Message', required: true, multiline: true),
    const _FieldSpec(
      'is_read',
      'Read status',
      required: true,
      choices: ['unread', 'read'],
    ),
  ],
  'orders' => [
    const _FieldSpec(
      'status',
      'Status',
      choices: [
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
      ],
    ),
    const _FieldSpec(
      'payment_status',
      'Payment status',
      choices: ['unpaid', 'paid', 'refund'],
    ),
    const _FieldSpec(
      'fulfillment_status',
      'Fulfillment',
      choices: ['pickup', 'farmer_arranged'],
    ),
    const _FieldSpec('delivery_address', 'Delivery address', multiline: true),
    const _FieldSpec('notes', 'Notes', multiline: true),
  ],
  _ => const [],
};

AdminModule? _module(String key) {
  for (final module in adminModules) {
    if (module.key == key) return module;
  }
  return null;
}

String _singular(String value) => value.endsWith('ies')
    ? '${value.substring(0, value.length - 3)}y'
    : value.endsWith('s')
    ? value.substring(0, value.length - 1)
    : value;
String _humanize(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
String _recordTitle(String resource, Map<String, dynamic> row) =>
    '${row['name'] ?? row['title'] ?? row['farm_name'] ?? row['business_name'] ?? row['order_number'] ?? row['first_name'] ?? row['batch_code'] ?? row['market_name'] ?? _humanize(_singular(resource))} #${row['id'] ?? ''}';
String _recordSubtitle(Map<String, dynamic> row) => [
  row['email'],
  row['status'],
  row['role'],
  row['municipality'],
  row['province'],
  row['verification_status'],
].where((value) => value != null && '$value'.isNotEmpty).join(' · ');
int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _asIntOrNull(dynamic value) => value == null ? null : _asInt(value);

Future<dynamic> _adminList(
  String resource,
  int offset,
  int limit,
) => switch (resource) {
  'users' => ProfileService().listUsers(offset: offset, limit: limit),
  'categories' => CategoryService().list(offset: offset, limit: limit),
  'products' => ProductService().list(offset: offset, limit: limit),
  'harvest-batches' => HarvestBatchesService().list(
    offset: offset,
    limit: limit,
  ),
  'farmer-profiles' => ProfileService().listFarmerProfiles(
    offset: offset,
    limit: limit,
  ),
  'business-buyer-profiles' => ProfileService().listBusinessBuyerProfiles(
    offset: offset,
    limit: limit,
  ),
  'market-prices' => MarketPricesService().list(offset: offset, limit: limit),
  'advisories' => AdvisoryService().list(offset: offset, limit: limit),
  'crop-reports' => CropReportsService().list(offset: offset, limit: limit),
  'notifications' => NotificationService().list(offset: offset, limit: limit),
  'orders' => OrderService().list(offset: offset, limit: limit),
  _ => Future.error(StateError('Unsupported admin resource')),
};

Future<dynamic> _adminGet(String resource, int id) => switch (resource) {
  'users' => ProfileService().getUser(id),
  'categories' => CategoryService().get(id),
  'products' => ProductService().get(id),
  'harvest-batches' => HarvestBatchesService().get(id),
  'farmer-profiles' => ProfileService().getFarmerProfile(id),
  'business-buyer-profiles' => ProfileService().getBusinessBuyerProfile(id),
  'market-prices' => MarketPricesService().get(id),
  'advisories' => AdvisoryService().get(id),
  'crop-reports' => CropReportsService().get(id),
  'notifications' => NotificationService().get(id),
  'orders' => OrderService().get(id),
  _ => Future.error(StateError('Unsupported admin resource')),
};

Future<dynamic> _adminCreate(String resource, Map<String, dynamic> body) =>
    switch (resource) {
      'users' => ProfileService().createUser(body),
      'categories' => CategoryService().create(body),
      'products' => ProductService().create(body),
      'harvest-batches' => HarvestBatchesService().create(body),
      'farmer-profiles' => ProfileService().createFarmerProfile(body),
      'business-buyer-profiles' => ProfileService().createBusinessBuyerProfile(
        body,
      ),
      'market-prices' => MarketPricesService().create(body),
      'advisories' => AdvisoryService().create(body),
      'crop-reports' => CropReportsService().create(body),
      'notifications' => NotificationService().create(body),
      _ => Future.error(StateError('This resource cannot be created here')),
    };

Future<dynamic> _adminUpdate(
  String resource,
  int id,
  Map<String, dynamic> body,
) => switch (resource) {
  'users' => ProfileService().updateUser(id, body),
  'categories' => CategoryService().update(id, body),
  'products' => ProductService().update(id, body),
  'harvest-batches' => HarvestBatchesService().update(id, body),
  'farmer-profiles' => ProfileService().updateFarmerProfile(id, body),
  'business-buyer-profiles' => ProfileService().updateBusinessBuyerProfile(
    id,
    body,
  ),
  'market-prices' => MarketPricesService().update(id, body),
  'advisories' => AdvisoryService().update(id, body),
  'crop-reports' => CropReportsService().update(id, body),
  'notifications' => NotificationService().update(id, body),
  'orders' => OrderService().update(id, body),
  _ => Future.error(StateError('Unsupported admin resource')),
};

Future<dynamic> _adminDelete(String resource, int id) => switch (resource) {
  'users' => ProfileService().deleteUser(id),
  'categories' => CategoryService().delete(id),
  'products' => ProductService().delete(id),
  'harvest-batches' => HarvestBatchesService().delete(id),
  'farmer-profiles' => ProfileService().deleteFarmerProfile(id),
  'business-buyer-profiles' => ProfileService().deleteBusinessBuyerProfile(id),
  'market-prices' => MarketPricesService().delete(id),
  'advisories' => AdvisoryService().delete(id),
  'crop-reports' => CropReportsService().delete(id),
  'notifications' => NotificationService().delete(id),
  _ => Future.error(
    StateError('Orders cannot be deleted through this interface'),
  ),
};

class _AdminEmpty extends StatelessWidget {
  const _AdminEmpty({required this.label, this.onCreate});
  final String label;
  final VoidCallback? onCreate;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 46,
            color: AppColors.leafGreen,
          ),
          const SizedBox(height: 10),
          Text('No $label found.'),
          if (onCreate != null)
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('Create ${_singular(label)}'),
            ),
        ],
      ),
    ),
  );
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.leafGreen,
          ),
          const SizedBox(height: 12),
          Text(_friendlyError(error), textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _friendlyError(Object error) {
  if (error is ApiException) {
    return switch (error.statusCode) {
      401 => 'Sign in again to continue.',
      403 => 'Your account cannot access this record.',
      404 => 'This record was not found.',
      422 => error.message,
      >= 500 => 'The service is temporarily unavailable.',
      _ => error.message,
    };
  }
  return 'Could not connect. Check your connection and retry.';
}
