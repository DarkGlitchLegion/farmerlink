import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> configureCacheDatabaseFactory() async {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

DatabaseFactory get cacheDatabaseFactory => databaseFactory;

bool get cacheUsesWebStorage => false;
