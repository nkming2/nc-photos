import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:nc_photos/widget/my_app.dart' as itf;
import 'package:sqflite/sqflite.dart';

class MyApp extends itf.MyApp {
  static IdbFactory getDbFactory() => getIdbFactorySqflite(databaseFactory);
}
