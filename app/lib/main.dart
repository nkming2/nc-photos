import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/bloc_util.dart';
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
  Bloc.observer = const _BlocObserver();
  Bloc.transformer = sequential();
  runApp(const MyApp());
}

@npLog
class _BlocObserver extends BlocObserver {
  const _BlocObserver();

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    final tag = bloc is BlocTag ? (bloc as BlocTag).tag : bloc.runtimeType;
    _log.finer("$tag $change");
  }
}
