import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_snapshot_store.dart';

final cacheSnapshotStoreProvider = Provider<CacheSnapshotStore>(
  (ref) => CacheSnapshotStore(),
);
