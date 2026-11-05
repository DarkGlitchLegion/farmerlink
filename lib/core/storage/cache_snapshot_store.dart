import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'cache_database_factory.dart';

class CacheScope {
  const CacheScope._(this.value);

  static const public = CacheScope._('public');

  factory CacheScope.user({required String role, required int userId}) =>
      CacheScope._('user:$role:$userId');

  final String value;
}

class CacheSnapshotStore {
  CacheSnapshotStore();

  static const _databaseName = 'farmerlink_cache.db';
  static const _tableName = 'snapshots';
  Future<Database>? _databaseFuture;

  Future<Object?> readJson(CacheScope scope, String key) async {
    try {
      final rows = await (await _database()).query(
        _tableName,
        columns: const ['payload'],
        where: 'scope = ? AND cache_key = ?',
        whereArgs: [scope.value, key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.single['payload']! as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(CacheScope scope, String key, Object value) async {
    try {
      await (await _database()).insert(_tableName, {
        'scope': scope.value,
        'cache_key': key,
        'payload': jsonEncode(value),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Cache failures should never prevent a successful API response.
    }
  }

  Future<void> invalidate(CacheScope scope, String key) async {
    try {
      await (await _database()).delete(
        _tableName,
        where: 'scope = ? AND cache_key = ?',
        whereArgs: [scope.value, key],
      );
    } catch (_) {
      // The next successful fetch will replace stale data.
    }
  }

  Future<void> invalidateAcrossScopes(String key) async {
    try {
      await (await _database()).delete(
        _tableName,
        where: 'cache_key = ?',
        whereArgs: [key],
      );
    } catch (_) {
      // The next successful fetch will replace stale data.
    }
  }

  Future<void> clearScope(CacheScope scope) async {
    try {
      await (await _database()).delete(
        _tableName,
        where: 'scope = ?',
        whereArgs: [scope.value],
      );
    } catch (_) {
      // Cache cleanup is best-effort; user-scoped keys still prevent leakage.
    }
  }

  Future<Database> _database() => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    await configureCacheDatabaseFactory();
    final path = await _databasePath();
    return cacheDatabaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) => database.execute('''
          CREATE TABLE $_tableName (
            scope TEXT NOT NULL,
            cache_key TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (scope, cache_key)
          )
        '''),
      ),
    );
  }

  Future<String> _databasePath() async {
    if (cacheUsesWebStorage) {
      return _databaseName;
    }
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, _databaseName);
  }
}

Stream<T> cacheFirstRefresh<T>({
  required CacheSnapshotStore store,
  required CacheScope scope,
  required String key,
  required T Function(Object json) decode,
  required Object Function(T value) encode,
  required Future<T> Function() fetch,
}) async* {
  var emittedCached = false;
  Object? cachedJson;
  try {
    cachedJson = await store.readJson(scope, key);
    if (cachedJson != null) {
      yield decode(cachedJson);
      emittedCached = true;
    }
  } catch (_) {
    cachedJson = null;
  }

  try {
    final fresh = await fetch();
    await store.writeJson(scope, key, encode(fresh));
    if (!emittedCached || jsonEncode(cachedJson) != jsonEncode(encode(fresh))) {
      yield fresh;
    }
  } catch (error, stackTrace) {
    if (!emittedCached) Error.throwWithStackTrace(error, stackTrace);
  }
}
