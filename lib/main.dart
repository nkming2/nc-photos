import 'package:equatable/equatable.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/mobile/self_signed_cert_manager.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/widget/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initLog();
  await _initPref();
  _initBloc();
  _initKiwi();
  _initEquatable();
  if (features.isSupportSelfSignedCert) {
    _initSelfSignedCertManager();
  }

  runApp(MyApp());
}

void _initLog() {
  if (kDebugMode) {
    debugPrintGestureArenaDiagnostics = true;
  }
  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
  Logger.root.onRecord.listen((record) {
    // dev.log(
    //   "${record.level.name} ${record.time}: ${record.message}",
    //   time: record.time,
    //   sequenceNumber: record.sequenceNumber,
    //   level: record.level.value,
    //   name: record.loggerName,
    // );
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

Future<void> _initPref() async {
  await Pref.init();
  if (Pref.inst().getLastVersion(null) == null) {
    if (Pref.inst().getSetupProgress(null) == null) {
      // new install
      await Pref.inst().setLastVersion(k.version);
    } else {
      // v6 is the last version without saving the version number in pref
      await Pref.inst().setLastVersion(6);
    }
  }
}

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

void _initSelfSignedCertManager() {
  SelfSignedCertManager().init();
}

class _BlocObserver extends BlocObserver {
  @override
  onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log.finer("${bloc.runtimeType} $change");
  }

  static final _log = Logger("_BlocObserver");
}
