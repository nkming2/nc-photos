import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/data_source.dart';
import 'package:nc_photos/entity/album/data_source2.dart';
import 'package:nc_photos/entity/album/repo2.dart';
import 'package:nc_photos/entity/face_recognition_person/data_source.dart';
import 'package:nc_photos/entity/face_recognition_person/repo.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/favorite/data_source.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/local_file/data_source.dart';
import 'package:nc_photos/entity/nc_album/data_source.dart';
import 'package:nc_photos/entity/nc_album/repo.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/entity/pref/provider/shared_preferences.dart';
import 'package:nc_photos/entity/pref_util.dart' as pref_util;
import 'package:nc_photos/entity/recognize_face/data_source.dart';
import 'package:nc_photos/entity/recognize_face/repo.dart';
import 'package:nc_photos/entity/search.dart';
import 'package:nc_photos/entity/search/data_source.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sharee/data_source.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/isolate_util.dart' as sql_isolate;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tag/data_source.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/entity/tagged_file/data_source.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/activity.dart';
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/mobile/self_signed_cert_manager.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/touch_manager.dart';
import 'package:np_log/np_log.dart' as np_log;
import 'package:visibility_detector/visibility_detector.dart';

enum InitIsolateType {
  main,

  /// Isolates with Flutter engine, e.g., those spawned by flutter_isolate or
  /// flutter_background_service
  flutterIsolate,
}

bool isNewGMapsRenderer() => _isNewGMapsRenderer;

Future<void> init(InitIsolateType isolateType) async {
  if (_hasInitedInThisIsolate) {
    _log.warning("[init] Already initialized in this isolate");
    return;
  }

  initLog();
  await _initDeviceInfo();
  initDrift();
  if (isolateType == InitIsolateType.main) {
    await _initDriftWorkaround();
  }
  _initKiwi();
  await _initPref();
  await _initAccountPrefs();
  _initEquatable();
  if (features.isSupportSelfSignedCert) {
    _initSelfSignedCertManager();
  }
  await _initDiContainer(isolateType);
  _initVisibilityDetector();

  if (platform_k.isAndroid) {
    if (isolateType == InitIsolateType.main) {
      try {
        _isNewGMapsRenderer = await Activity.isNewGMapsRenderer();
      } catch (e, stackTrace) {
        _log.severe("[init] Failed while isNewGMapsRenderer", e, stackTrace);
      }
    }
  }

  _hasInitedInThisIsolate = true;
}

void initLog() {
  if (_hasInitedInThisIsolate) {
    return;
  }

  np_log.initLog(
    isDebugMode: kDebugMode,
    print: (log) => debugPrint(log, wrapWidth: 1024),
  );
}

void initDrift() {
  driftRuntimeOptions.debugPrint = (log) => debugPrint(log, wrapWidth: 1024);
}

Future<void> _initDriftWorkaround() async {
  if (platform_k.isAndroid && AndroidInfo().sdkInt < 24) {
    _log.info("[_initDriftWorkaround] Workaround Android 6- bug");
    // see: https://github.com/flutter/flutter/issues/73318 and
    // https://github.com/simolus3/drift/issues/895
    await platform.applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
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

Future<void> _initDiContainer(InitIsolateType isolateType) async {
  final c = DiContainer.late();
  c.pref = Pref();
  c.sqliteDb = await _createDb(isolateType);

  c.albumRepo = AlbumRepo(AlbumCachedDataSource(c));
  c.albumRepoRemote = AlbumRepo(AlbumRemoteDataSource());
  c.albumRepoLocal = AlbumRepo(AlbumSqliteDbDataSource(c));
  c.albumRepo2 = CachedAlbumRepo2(
      const AlbumRemoteDataSource2(), AlbumSqliteDbDataSource2(c.sqliteDb));
  c.albumRepo2Remote = const BasicAlbumRepo2(AlbumRemoteDataSource2());
  c.albumRepo2Local = BasicAlbumRepo2(AlbumSqliteDbDataSource2(c.sqliteDb));
  c.fileRepo = FileRepo(FileCachedDataSource(c));
  c.fileRepoRemote = const FileRepo(FileWebdavDataSource());
  c.fileRepoLocal = FileRepo(FileSqliteDbDataSource(c));
  c.shareRepo = ShareRepo(ShareRemoteDataSource());
  c.shareeRepo = ShareeRepo(ShareeRemoteDataSource());
  c.favoriteRepo = const FavoriteRepo(FavoriteRemoteDataSource());
  c.tagRepo = const TagRepo(TagRemoteDataSource());
  c.tagRepoRemote = const TagRepo(TagRemoteDataSource());
  c.tagRepoLocal = TagRepo(TagSqliteDbDataSource(c.sqliteDb));
  c.taggedFileRepo = const TaggedFileRepo(TaggedFileRemoteDataSource());
  c.searchRepo = SearchRepo(SearchSqliteDbDataSource(c));
  c.ncAlbumRepo = CachedNcAlbumRepo(
      const NcAlbumRemoteDataSource(), NcAlbumSqliteDbDataSource(c.sqliteDb));
  c.ncAlbumRepoRemote = const BasicNcAlbumRepo(NcAlbumRemoteDataSource());
  c.ncAlbumRepoLocal = BasicNcAlbumRepo(NcAlbumSqliteDbDataSource(c.sqliteDb));
  c.faceRecognitionPersonRepo = const BasicFaceRecognitionPersonRepo(
      FaceRecognitionPersonRemoteDataSource());
  c.faceRecognitionPersonRepoRemote = const BasicFaceRecognitionPersonRepo(
      FaceRecognitionPersonRemoteDataSource());
  c.faceRecognitionPersonRepoLocal = BasicFaceRecognitionPersonRepo(
      FaceRecognitionPersonSqliteDbDataSource(c.sqliteDb));
  c.recognizeFaceRepo =
      const BasicRecognizeFaceRepo(RecognizeFaceRemoteDataSource());
  c.recognizeFaceRepoRemote =
      const BasicRecognizeFaceRepo(RecognizeFaceRemoteDataSource());
  c.recognizeFaceRepoLocal =
      BasicRecognizeFaceRepo(RecognizeFaceSqliteDbDataSource(c.sqliteDb));

  c.touchManager = TouchManager(c);

  if (platform_k.isAndroid) {
    // local file currently only supported on Android
    c.localFileRepo = const LocalFileRepo(LocalFileMediaStoreDataSource());
  }

  KiwiContainer().registerInstance<DiContainer>(c);
}

void _initVisibilityDetector() {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
}

Future<sql.SqliteDb> _createDb(InitIsolateType isolateType) async {
  switch (isolateType) {
    case InitIsolateType.main:
      // use driftIsolate to prevent DB blocking the UI thread
      if (platform_k.isWeb) {
        // no isolate support on web
        return sql.SqliteDb();
      } else {
        return sql_isolate.createDb();
      }

    case InitIsolateType.flutterIsolate:
      // service already runs in an isolate
      return sql.SqliteDb();
  }
}

final _log = Logger("app_init");
var _hasInitedInThisIsolate = false;
var _isNewGMapsRenderer = false;
