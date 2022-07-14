import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/event/native_event.dart';
import 'package:nc_photos/future_extension.dart';
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/update_missing_metadata.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

/// Start the background service
Future<void> startService() async {
  _log.info("[startService] Starting service");
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: serviceMain,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationTitle:
          L10n.global().metadataTaskProcessingNotification,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: () => throw UnimplementedError(),
      onBackground: () => throw UnimplementedError(),
    ),
  );
  // sync settings
  await ServiceConfig.setProcessExifWifiOnly(
      Pref().shouldProcessExifWifiOnlyOr());
  await service.start();
}

/// Ask the background service to stop ASAP
void stopService() {
  _log.info("[stopService] Stopping service");
  FlutterBackgroundService().sendData({
    _dataKeyEvent: _eventStop,
  });
}

@visibleForTesting
void serviceMain() async {
  _Service._shouldRun.value = true;
  WidgetsFlutterBinding.ensureInitialized();

  await _Service()();
}

class ServiceConfig {
  static Future<void> setProcessExifWifiOnly(bool flag) async {
    await Preference.setBool(_servicePref, _servicePrefProcessWifiOnly, flag);
  }
}

class _Service {
  Future<void> call() async {
    final service = FlutterBackgroundService();
    service.setForegroundMode(true);

    await app_init.initAppLaunch();
    await _L10n().init();

    _log.info("[call] Service started");
    final onCancelSubscription = service.onCancel.listen((_) {
      _log.info("[call] User canceled");
      _stopSelf();
    });
    final onDataSubscription =
        service.onDataReceived.listen((event) => _onReceiveData(event ?? {}));

    try {
      await _doWork();
    } catch (e, stackTrace) {
      _log.shout("[call] Uncaught exception", e, stackTrace);
    }
    onCancelSubscription.cancel();
    onDataSubscription.cancel();
    service.stopBackgroundService();
    _log.info("[call] Service stopped");
  }

  Future<void> _doWork() async {
    final account = Pref().getCurrentAccount();
    if (account == null) {
      _log.shout("[_doWork] account == null");
      return;
    }
    final accountPref = AccountPref.of(account);

    final service = FlutterBackgroundService();
    final metadataTask = _MetadataTask(service, account, accountPref);
    _metadataTaskStateChangedListener.begin();
    try {
      await metadataTask();
    } finally {
      _metadataTaskStateChangedListener.end();
    }
  }

  void _onReceiveData(Map<String, dynamic> data) {
    try {
      final event = data[_dataKeyEvent];
      switch (event) {
        case _eventStop:
          _stopSelf();
          break;

        default:
          _log.severe("[_onReceiveData] Unknown event: $event");
          break;
      }
    } catch (e, stackTrace) {
      _log.shout("[_onReceiveData] Uncaught exception", e, stackTrace);
    }
  }

  void _onMetadataTaskStateChanged(MetadataTaskStateChangedEvent ev) {
    if (ev.state == _metadataTaskState) {
      return;
    }
    _metadataTaskState = ev.state;
    if (_isPaused != true) {
      if (ev.state == MetadataTaskState.waitingForWifi) {
        FlutterBackgroundService()
          ..setNotificationInfo(
            title: _L10n.global().metadataTaskPauseNoWiFiNotification,
          )
          ..pauseWakeLock();
        _isPaused = true;
      } else if (ev.state == MetadataTaskState.lowBattery) {
        FlutterBackgroundService()
          ..setNotificationInfo(
            title: _L10n.global().metadataTaskPauseLowBatteryNotification,
          )
          ..pauseWakeLock();
        _isPaused = true;
      }
    } else {
      if (ev.state == MetadataTaskState.prcoessing) {
        FlutterBackgroundService().resumeWakeLock();
        _isPaused = false;
      }
    }
  }

  void _stopSelf() {
    _log.info("[_stopSelf] Stopping service");
    FlutterBackgroundService().setNotificationInfo(
      title: _L10n.global().backgroundServiceStopping,
    );
    _shouldRun.value = false;
  }

  var _metadataTaskState = MetadataTaskState.idle;
  late final _metadataTaskStateChangedListener =
      AppEventListener<MetadataTaskStateChangedEvent>(
          _onMetadataTaskStateChanged);

  bool? _isPaused;

  static final _shouldRun = ValueNotifier<bool>(true);
  static final _log = Logger("service._Service");
}

/// Access localized string out of the main isolate
class _L10n {
  factory _L10n() => _inst;

  _L10n._();

  Future<void> init() async {
    try {
      final locale = language_util.getSelectedLocale();
      if (locale == null) {
        _l10n = await _queryL10n();
      } else {
        _l10n = lookupAppLocalizations(locale);
      }
    } catch (e, stackTrace) {
      _log.shout("[init] Uncaught exception", e, stackTrace);
      _l10n = AppLocalizationsEn();
    }
  }

  static AppLocalizations global() => _L10n()._l10n;

  Future<AppLocalizations> _queryL10n() async {
    try {
      final locale = await Devicelocale.currentAsLocale;
      return lookupAppLocalizations(locale!);
    } on FlutterError catch (_) {
      // unsupported locale, use default (en)
      return AppLocalizationsEn();
    } catch (e, stackTrace) {
      _log.shout(
          "[_queryL10n] Failed while lookupAppLocalizations", e, stackTrace);
      return AppLocalizationsEn();
    }
  }

  static final _inst = _L10n._();
  late AppLocalizations _l10n;

  static final _log = Logger("service._L10n");
}

class _MetadataTask {
  _MetadataTask(this.service, this.account, this.accountPref);

  Future<void> call() async {
    try {
      await _updateMetadata();
    } catch (e, stackTrace) {
      _log.shout("[call] Uncaught exception", e, stackTrace);
    }
    if (_processedIds.isNotEmpty) {
      NativeEvent.fire(FileExifUpdatedEvent(_processedIds).toEvent());
      _processedIds = [];
    }
  }

  Future<void> _updateMetadata() async {
    final shareFolder = File(
        path: file_util.unstripPath(account, accountPref.getShareFolderOr()));
    bool hasScanShareFolder = false;
    final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
    for (final r in account.roots) {
      final dir = File(path: file_util.unstripPath(account, r));
      hasScanShareFolder |= file_util.isOrUnderDir(shareFolder, dir);
      final updater = UpdateMissingMetadata(
          fileRepo, const _UpdateMissingMetadataConfigProvider());
      void onServiceStop() {
        _log.info("[_updateMetadata] Stopping task: user canceled");
        updater.stop();
        _shouldRun = false;
      }

      _Service._shouldRun.addListener(onServiceStop);
      try {
        await for (final ev in updater(account, dir)) {
          if (ev is File) {
            _onFileProcessed(ev);
          }
        }
      } finally {
        _Service._shouldRun.removeListener(onServiceStop);
      }
      if (!_shouldRun) {
        return;
      }
    }
    if (!hasScanShareFolder) {
      final shareUpdater = UpdateMissingMetadata(
          fileRepo, const _UpdateMissingMetadataConfigProvider());
      void onServiceStop() {
        _log.info("[_updateMetadata] Stopping task: user canceled");
        shareUpdater.stop();
        _shouldRun = false;
      }

      _Service._shouldRun.addListener(onServiceStop);
      try {
        await for (final ev in shareUpdater(
          account,
          shareFolder,
          isRecursive: false,
          filter: (f) => f.ownerId != account.username,
        )) {
          if (ev is File) {
            _onFileProcessed(ev);
          }
        }
      } finally {
        _Service._shouldRun.removeListener(onServiceStop);
      }
      if (!_shouldRun) {
        return;
      }
    }
  }

  void _onFileProcessed(File file) {
    ++_count;
    service.setNotificationInfo(
      title: _L10n.global().metadataTaskProcessingNotification,
      content: file.strippedPath,
    );

    _processedIds.add(file.fileId!);
    if (_processedIds.length >= 10) {
      NativeEvent.fire(FileExifUpdatedEvent(_processedIds).toEvent());
      _processedIds = [];
    }
  }

  final FlutterBackgroundService service;
  final Account account;
  final AccountPref accountPref;

  var _shouldRun = true;
  var _count = 0;
  var _processedIds = <int>[];

  static final _log = Logger("service._MetadataTask");
}

class _UpdateMissingMetadataConfigProvider
    implements UpdateMissingMetadataConfigProvider {
  const _UpdateMissingMetadataConfigProvider();

  @override
  isWifiOnly() =>
      Preference.getBool(_servicePref, _servicePrefProcessWifiOnly, true)
          .notNull();
}

const _dataKeyEvent = "event";
const _eventStop = "stop";

const _servicePref = "service";
const _servicePrefProcessWifiOnly = "shouldProcessWifiOnly";

final _log = Logger("service");
