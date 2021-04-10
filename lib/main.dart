import 'package:equatable/equatable.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initLog();
  await _initPref();
  _initBloc();
  _initKiwi();
  _initEquatable();

  runApp(platform.MyApp());
}

void _initLog() {
  if (kDebugMode) {
    debugPrintGestureArenaDiagnostics = true;
  }
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // dev.log(
    //   "${record.level.name} ${record.time}: ${record.message}",
    //   time: record.time,
    //   sequenceNumber: record.sequenceNumber,
    //   level: record.level.value,
    //   name: record.loggerName,
    // );
    if (kReleaseMode && record.level <= Level.FINE) {
      return;
    }
    String msg =
        "[${record.loggerName}] ${record.level.name} ${record.time}: ${record.message}";
    if (record.error != null) {
      msg += " (throw: ${record.error.runtimeType} { ${record.error} })";
    }
    if (record.stackTrace != null) {
      msg += "\nStack Trace:\n${record.stackTrace}";
    }
    debugPrint(msg);
  });
}

Future<void> _initPref() => Pref.init();

void _initBloc() {
  Bloc.observer = _BlocObserver();
}

void _initKiwi() {
  final kiwi = KiwiContainer();
  kiwi.registerInstance<EventBus>(EventBus());
  kiwi.registerInstance<MetadataTaskManager>(MetadataTaskManager());
}

void _initEquatable() {
  EquatableConfig.stringify = false;
}

class _BlocObserver extends BlocObserver {
  @override
  onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log.finer("${bloc.runtimeType} $change");
  }

  static final _log = Logger("_BlocObserver");
}
