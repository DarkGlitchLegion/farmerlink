import 'package:flutter/material.dart';

import '../../../core/storage/cache_snapshot_store.dart';
import '../../../core/services/advisory_service.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/harvest_batches_service.dart';
import '../../../core/services/market_prices_service.dart';
import '../../../core/theme/app_colors.dart';

class PublicMarketplaceInfoPage extends StatefulWidget {
  const PublicMarketplaceInfoPage({super.key});
  @override
  State<PublicMarketplaceInfoPage> createState() =>
      _PublicMarketplaceInfoPageState();
}

class _PublicMarketplaceInfoPageState extends State<PublicMarketplaceInfoPage> {
  static const _sections = [
    'Categories',
    'Market prices',
    'Batches',
    'Advisories',
  ];
  int _selected = 0;
  String _query = '';
  List<Map<String, dynamic>>? _cachedRows;
  final _cache = CacheSnapshotStore();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load({int? section}) async {
    final selected = section ?? _selected;
    final key = 'public_marketplace_$selected';
    final cached = await _cache.readJson(CacheScope.public, key);
    final cachedRows = cached is List
        ? cached.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : null;
    if (cachedRows != null && mounted && selected == _selected) {
      setState(() => _cachedRows = cachedRows);
    }
    try {
      final value = switch (selected) {
        0 => await CategoryService().list(limit: 100),
        1 => await MarketPricesService().list(limit: 100),
        2 => await HarvestBatchesService().list(limit: 100),
        _ => await AdvisoryService().list(limit: 100),
      };
      if (value is! List) {
        throw const FormatException('The API returned an invalid list.');
      }
      final rows = value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      await _cache.writeJson(CacheScope.public, key, rows);
      return rows;
    } catch (_) {
      if (cachedRows != null) return cachedRows;
      rethrow;
    }
  }

  void _select(int index) => setState(() {
    _selected = index;
    _query = '';
    _cachedRows = null;
    _future = _load(section: index);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Market information'),
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.darkGreen,
    ),
    body: Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var i = 0; i < _sections.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_sections[i]),
                    selected: _selected == i,
                    onSelected: (_) => _select(i),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search this list',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final availableRows = snapshot.data ?? _cachedRows;
              if (availableRows == null &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (availableRows == null && snapshot.hasError) {
                return _PublicInfoError(
                  message: _message(snapshot.error!),
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final records = (availableRows ?? const <Map<String, dynamic>>[])
                  .where(
                    (row) => row.values.any(
                      (value) =>
                          '$value'.toLowerCase().contains(_query.toLowerCase()),
                    ),
                  )
                  .toList();
              if (records.isEmpty) {
                return const Center(
                  child: Text('No matching public information.'),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (final row in records)
                      Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: Icon(
                            _selected == 0
                                ? Icons.category_outlined
                                : _selected == 1
                                ? Icons.show_chart
                                : _selected == 2
                                ? Icons.agriculture_outlined
                                : Icons.campaign_outlined,
                            color: AppColors.primaryGreen,
                          ),
                          title: Text(
                            _title(row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _subtitle(row),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showDetails(context, row),
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

  String _title(Map<String, dynamic> row) =>
      '${row['name'] ?? row['market_name'] ?? row['batch_code'] ?? row['title'] ?? 'Record ${row['id'] ?? ''}'}';
  String _subtitle(Map<String, dynamic> row) {
    if (_selected == 1) {
      return '${row['municipality'] ?? ''} · ₱${row['average_price'] ?? '—'} / ${row['unit'] ?? ''}';
    }
    if (_selected == 2) {
      return '${row['remaining_quantity'] ?? 0} remaining · ${row['status'] ?? ''}';
    }
    if (_selected == 3) {
      return '${row['municipality'] ?? ''} · ${row['severity'] ?? ''}';
    }
    return '${row['description'] ?? ''}';
  }

  Future<void> _showDetails(
    BuildContext context,
    Map<String, dynamic> row,
  ) async {
    try {
      final id = row['id'];
      final detail = switch (_selected) {
        0 => await CategoryService().get(id as int),
        1 => await MarketPricesService().get(id as int),
        2 => await HarvestBatchesService().get(id as int),
        _ => await AdvisoryService().get(id as int),
      };
      if (!context.mounted) return;
      final fields = detail is Map ? Map<String, dynamic>.from(detail) : row;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title(fields),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const Divider(height: 22),
                  for (final entry in fields.entries)
                    if (entry.key != 'id')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          '${entry.key.replaceAll('_', ' ')}: ${entry.value ?? '—'}',
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }
}

class _PublicInfoError extends StatelessWidget {
  const _PublicInfoError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
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

String _message(Object error) => error.toString().contains('ApiException')
    ? error.toString().replaceFirst(RegExp(r'^ApiException\(\d+\): '), '')
    : 'Could not load public market information.';
