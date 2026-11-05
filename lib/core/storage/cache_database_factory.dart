import 'package:sqflite/sqflite.dart';

import 'cache_database_factory_stub.dart'
    if (dart.library.io) 'cache_database_factory_io.dart'
    if (dart.library.js_interop) 'cache_database_factory_web.dart'
    as platform_factory;

Future<void> configureCacheDatabaseFactory() =>
    platform_factory.configureCacheDatabaseFactory();

DatabaseFactory get cacheDatabaseFactory =>
    platform_factory.cacheDatabaseFactory;

bool get cacheUsesWebStorage => platform_factory.cacheUsesWebStorage;
