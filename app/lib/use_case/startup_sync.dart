import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/type.dart';
import 'package:nc_photos/use_case/sync_favorite.dart';

/// Sync various properties with server during startup
class StartupSync {
  StartupSync(this._c)
      : assert(require(_c)),
        assert(SyncFavorite.require(_c));

  static bool require(DiContainer c) => true;

  /// Sync in a background isolate
  static Future<SyncResult> runInIsolate(Account account) async {
    if (platform_k.isWeb) {
      // not supported on web
      final c = KiwiContainer().resolve<DiContainer>();
      return await StartupSync(c)(account);
    } else {
      // we can't use regular isolate here because self-signed cert support
      // requires native plugins
      final resultJson =
          await flutterCompute(_isolateMain, _IsolateMessage(account).toJson());
      final result = SyncResult.fromJson(resultJson);
      // events fired in background isolate won't be noticed by the main isolate,
      // so we fire them again here
      _broadcastResult(account, result);
      return result;
    }
  }

  Future<SyncResult> call(Account account) async {
    _log.info("[_run] Begin sync");
    final stopwatch = Stopwatch()..start();
    late final int syncFavoriteCount;
    try {
      syncFavoriteCount = await SyncFavorite(_c)(account);
    } catch (e, stackTrace) {
      _log.shout("[_run] Failed while SyncFavorite", e, stackTrace);
      syncFavoriteCount = -1;
    }
    _log.info("[_run] Elapsed time: ${stopwatch.elapsedMilliseconds}ms");
    return SyncResult(syncFavoriteCount);
  }

  static void _broadcastResult(Account account, SyncResult result) {
    final eventBus = KiwiContainer().resolve<EventBus>();
    if (result.syncFavoriteCount > 0) {
      eventBus.fire(FavoriteResyncedEvent(account));
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.startup_sync.StartupSync");
}

class SyncResult {
  const SyncResult(this.syncFavoriteCount);

  factory SyncResult.fromJson(JsonObj json) => SyncResult(
        json["syncFavoriteCount"],
      );

  JsonObj toJson() => {
        "syncFavoriteCount": syncFavoriteCount,
      };

  final int syncFavoriteCount;
}

class _IsolateMessage {
  const _IsolateMessage(this.account);

  factory _IsolateMessage.fromJson(JsonObj json) => _IsolateMessage(
        Account.fromJson(
          json["account"].cast<String, dynamic>(),
          upgraderV1: const AccountUpgraderV1(),
        )!,
      );

  JsonObj toJson() => {
        "account": account.toJson(),
      };

  final Account account;
}

Future<JsonObj> _isolateMain(JsonObj messageJson) async {
  final message = _IsolateMessage.fromJson(messageJson);
  await app_init.init(app_init.InitIsolateType.flutterIsolate);

  final c = KiwiContainer().resolve<DiContainer>();
  final result = await StartupSync(c)(message.account);
  return result.toJson();
}
