import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/widget/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app_init.initAppLaunch();

  if (platform_k.isMobile) {
    // reset orientation override just in case, see #59
    SystemChrome.setPreferredOrientations([]);
  }
  runApp(const MyApp());
}
