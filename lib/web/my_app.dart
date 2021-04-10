import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:nc_photos/widget/my_app.dart' as itf;

class MyApp extends itf.MyApp {
  static IdbFactory getDbFactory() => getIdbFactory();
}
