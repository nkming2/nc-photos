import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/widget/my_app.dart';
import 'package:np_codegen/np_codegen.dart';

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app_init.init(app_init.InitIsolateType.main);

  if (platform_k.isMobile) {
    // reset orientation override just in case, see #59
    unawaited(SystemChrome.setPreferredOrientations([]));
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
  BlocOverrides.runZoned(
    () => runApp(const MyApp()),
    blocObserver: _BlocObserver(),
    eventTransformer: sequential(),
  );
}

@npLog
class _BlocObserver extends BlocObserver {
  @override
  onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log.finer("${bloc.runtimeType} $change");
  }
}
