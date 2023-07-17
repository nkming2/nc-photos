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

  Future<void> setAlbumBrowserZoomLevel(int value) async {
    final backup = _albumBrowserZoomLevelController.value;
    _albumBrowserZoomLevelController.add(value);
    try {
      if (!await _c.pref.setAlbumBrowserZoomLevel(value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[setAlbumBrowserZoomLevel] Failed setting preference", e,
          stackTrace);
      _albumBrowserZoomLevelController
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  ValueStream<int> get homeAlbumsSort => _homeAlbumsSortController.stream;

  Future<void> setHomeAlbumsSort(int value) async {
    final backup = _homeAlbumsSortController.value;
    _homeAlbumsSortController.add(value);
    try {
      if (!await _c.pref.setHomeAlbumsSort(value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe(
          "[setHomeAlbumsSort] Failed setting preference", e, stackTrace);
      _homeAlbumsSortController
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
}
