import 'package:sqflite/sqflite.dart';

Future<void> configureCacheDatabaseFactory() async {}

DatabaseFactory get cacheDatabaseFactory => databaseFactory;

bool get cacheUsesWebStorage => false;
