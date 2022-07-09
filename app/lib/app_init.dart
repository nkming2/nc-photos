import 'package:equatable/equatable.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/face/data_source.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/favorite/data_source.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/local_file/data_source.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/person/data_source.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sharee/data_source.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tag/data_source.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/entity/tagged_file/data_source.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/self_signed_cert_manager.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/pref_util.dart' as pref_util;
import 'package:visibility_detector/visibility_detector.dart';

Future<void> initAppLaunch() async {
  if (_hasInitedInThisIsolate) {
    _log.warning("[initAppLaunch] Already initialized in this isolate");
    return;
  }

  initLog();
  _initKiwi();
  await _initPref();
  await _initAccountPrefs();
  await _initDeviceInfo();
  _initEquatable();
  if (features.isSupportSelfSignedCert) {
    _initSelfSignedCertManager();
  }
  _initDiContainer();
  _initVisibilityDetector();

  _hasInitedInThisIsolate = true;
}

void initLog() {
  if (_hasInitedInThisIsolate) {
    return;
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

    if (kDebugMode) {
      // show me colors!
      int color;
      if (record.level >= Level.SEVERE) {
        color = 91;
      } else if (record.level >= Level.WARNING) {
        color = 33;
      } else if (record.level >= Level.INFO) {
        color = 34;
      } else if (record.level >= Level.FINER) {
        color = 32;
      } else {
        color = 90;
      }
      msg = "\x1B[${color}m$msg\x1B[0m";
    }
    debugPrint(msg);
    LogCapturer().onLog(msg);
  });
}

Future<void> _initPref() async {
  final provider = PrefSharedPreferencesProvider();
  await provider.init();
  final pref = Pref.scoped(provider);
  Pref.setGlobalInstance(pref);

  if (Pref().getLastVersion() == null) {
    if (Pref().getSetupProgress() == null) {
      // new install
      await Pref().setLastVersion(k.version);
    } else {
      // v6 is the last version without saving the version number in pref
      await Pref().setLastVersion(6);
    }
  }
}

Future<void> _initAccountPrefs() async {
  for (final a in Pref().getAccounts3Or([])) {
    try {
      AccountPref.setGlobalInstance(a, await pref_util.loadAccountPref(a));
    } catch (e, stackTrace) {
      _log.shout("[_initAccountPrefs] Failed reading pref for account: $a", e,
          stackTrace);
    }
  }
}

Future<void> _initDeviceInfo() async {
  if (platform_k.isAndroid) {
    await AndroidInfo.init();
  }
}

void _initKiwi() {
  final kiwi = KiwiContainer();
  kiwi.registerInstance<EventBus>(EventBus());
}

void _initEquatable() {
  EquatableConfig.stringify = false;
}

void _initSelfSignedCertManager() {
  SelfSignedCertManager().init();
}

void _initDiContainer() {
  LocalFileRepo? localFileRepo;
  if (platform_k.isAndroid) {
    // local file currently only supported on Android
    localFileRepo = const LocalFileRepo(LocalFileMediaStoreDataSource());
  }
  KiwiContainer().registerInstance<DiContainer>(DiContainer(
    albumRepo: AlbumRepo(AlbumCachedDataSource(AppDb())),
    faceRepo: const FaceRepo(FaceRemoteDataSource()),
    fileRepo: FileRepo(FileCachedDataSource(AppDb())),
    personRepo: const PersonRepo(PersonRemoteDataSource()),
    shareRepo: ShareRepo(ShareRemoteDataSource()),
    shareeRepo: ShareeRepo(ShareeRemoteDataSource()),
    favoriteRepo: const FavoriteRepo(FavoriteRemoteDataSource()),
    tagRepo: const TagRepo(TagRemoteDataSource()),
    taggedFileRepo: const TaggedFileRepo(TaggedFileRemoteDataSource()),
    localFileRepo: localFileRepo,
    appDb: AppDb(),
    pref: Pref(),
  ));
}

void _initVisibilityDetector() {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
}

final _log = Logger("app_init");
var _hasInitedInThisIsolate = false;
