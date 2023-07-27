import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/lazy.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:rxdart/rxdart.dart';

part 'pref_controller.g.dart';

@npLog
class PrefController {
  PrefController(this._c);

  ValueStream<language_util.AppLanguage> get language => _languageStream();

  Future<void> setAppLanguage(language_util.AppLanguage value) async {
    final backup = _languageController.value;
    _languageController.add(value.langId);
    try {
      if (!await _c.pref.setLanguage(value.langId)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[setAppLanguage] Failed setting preference", e, stackTrace);
      _languageController
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  ValueStream<int> get albumBrowserZoomLevel =>
      _albumBrowserZoomLevelController.stream;

  Future<void> setAlbumBrowserZoomLevel(int value) => _set<int>(
        controller: _albumBrowserZoomLevelController,
        setter: (pref, value) => pref.setAlbumBrowserZoomLevel(value),
        value: value,
      );

  ValueStream<int> get homeAlbumsSort => _homeAlbumsSortController.stream;

  Future<void> setHomeAlbumsSort(int value) => _set<int>(
        controller: _homeAlbumsSortController,
        setter: (pref, value) => pref.setHomeAlbumsSort(value),
        value: value,
      );

  ValueStream<bool> get isEnableExif => _isEnableExifController.stream;

  Future<void> setEnableExif(bool value) => _set<bool>(
        controller: _isEnableExifController,
        setter: (pref, value) => pref.setEnableExif(value),
        value: value,
      );

  ValueStream<bool> get shouldProcessExifWifiOnly =>
      _shouldProcessExifWifiOnlyController.stream;

  Future<void> setProcessExifWifiOnly(bool value) => _set<bool>(
        controller: _shouldProcessExifWifiOnlyController,
        setter: (pref, value) => pref.setProcessExifWifiOnly(value),
        value: value,
      );

  Future<void> _set<T>({
    required BehaviorSubject<T> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required T value,
  }) async {
    final backup = controller.value;
    controller.add(value);
    try {
      if (!await setter(_c.pref, value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[_set] Failed setting preference", e, stackTrace);
      controller
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  language_util.AppLanguage _langIdToAppLanguage(int langId) {
    try {
      return language_util.supportedLanguages[langId]!;
    } catch (_) {
      return language_util.supportedLanguages[0]!;
    }
  }

  final DiContainer _c;
  late final _languageController =
      BehaviorSubject.seeded(_c.pref.getLanguageOr(0));
  late final _languageStream = Lazy(
    () => _languageController
        .map(_langIdToAppLanguage)
        .publishValueSeeded(_langIdToAppLanguage(_languageController.value))
      ..connect(),
  );
  late final _albumBrowserZoomLevelController =
      BehaviorSubject.seeded(_c.pref.getAlbumBrowserZoomLevelOr(0));
  late final _homeAlbumsSortController =
      BehaviorSubject.seeded(_c.pref.getHomeAlbumsSortOr(0));
  late final _isEnableExifController =
      BehaviorSubject.seeded(_c.pref.isEnableExifOr(true));
  late final _shouldProcessExifWifiOnlyController =
      BehaviorSubject.seeded(_c.pref.shouldProcessExifWifiOnlyOr(true));
}
