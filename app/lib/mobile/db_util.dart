import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:sqflite/sqflite.dart';

IdbFactory getDbFactory() => getIdbFactorySqflite(databaseFactory);
