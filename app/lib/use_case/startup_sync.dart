import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/entity/pref/provider/memory.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/use_case/person/sync_person.dart';
import 'package:nc_photos/use_case/sync_favorite.dart';
import 'package:nc_photos/use_case/sync_tag.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';

part 'startup_sync.g.dart';

/// Sync various properties with server during startup
@npLog
class StartupSync {
  StartupSync(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      SyncFavorite.require(c) && SyncTag.require(c);

  /// Sync in a background isolate
  static Future<SyncResult> runInIsolate(
      Account account, AccountPref accountPref) async {
    if (platform_k.isWeb) {
      // not supported on web
      final c = KiwiContainer().resolve<DiContainer>();
      return await StartupSync(c)(account, accountPref);
    } else {
      // we can't use regular isolate here because self-signed cert support
      // requires native plugins
      final resultJson = await flutterCompute(
          _isolateMain, await _IsolateMessage(account, accountPref).toJson());
      final result = SyncResult.fromJson(resultJson);
      // events fired in background isolate won't be noticed by the main isolate,
      // so we fire them again here
      _broadcastResult(account, result);
      return result;
    }
  }

  Future<SyncResult> call(Account account, AccountPref accountPref) async {
    _log.info("[_run] Begin sync");
    final stopwatch = Stopwatch()..start();
    late final int syncFavoriteCount;
    late final bool isSyncPersonUpdated;
    try {
      syncFavoriteCount = await SyncFavorite(_c)(account);
    } catch (e, stackTrace) {
      _log.shout("[_run] Failed while SyncFavorite", e, stackTrace);
      syncFavoriteCount = -1;
    }
    try {
      await SyncTag(_c)(account);
    } catch (e, stackTrace) {
      _log.shout("[_run] Failed while SyncTag", e, stackTrace);
    }
    try {
      isSyncPersonUpdated = await SyncPerson(_c)(account, accountPref);
    } catch (e, stackTrace) {
      _log.shout("[_run] Failed while SyncPerson", e, stackTrace);
    }
    _log.info("[_run] Elapsed time: ${stopwatch.elapsedMilliseconds}ms");
    return SyncResult(
      syncFavoriteCount: syncFavoriteCount,
      isSyncPersonUpdated: isSyncPersonUpdated,
    );
  }

  static void _broadcastResult(Account account, SyncResult result) {
    final eventBus = KiwiContainer().resolve<EventBus>();
    if (result.syncFavoriteCount > 0) {
      eventBus.fire(FavoriteResyncedEvent(account));
    }
  }

  final DiContainer _c;
}

class SyncResult {
  const SyncResult({
    required this.syncFavoriteCount,
    required this.isSyncPersonUpdated,
  });

  factory SyncResult.fromJson(JsonObj json) => SyncResult(
        syncFavoriteCount: json["syncFavoriteCount"],
        isSyncPersonUpdated: json["isSyncPersonUpdated"],
      );

  JsonObj toJson() => {
        "syncFavoriteCount": syncFavoriteCount,
        "isSyncPersonUpdated": isSyncPersonUpdated,
      };

  final int syncFavoriteCount;
  final bool isSyncPersonUpdated;
}

class _IsolateMessage {
  const _IsolateMessage(this.account, this.accountPref);

  factory _IsolateMessage.fromJson(JsonObj json) => _IsolateMessage(
        Account.fromJson(
          json["account"].cast<String, dynamic>(),
          upgraderV1: const AccountUpgraderV1(),
        )!,
        AccountPref.scoped(PrefMemoryProvider.fromJson(json["accountPref"])),
      );

  Future<JsonObj> toJson() async => {
        "account": account.toJson(),
        "accountPref": await accountPref.toJson(),
      };

  final Account account;
  final AccountPref accountPref;
}

@pragma("vm:entry-point")
Future<JsonObj> _isolateMain(JsonObj messageJson) async {
  final message = _IsolateMessage.fromJson(messageJson);
  await app_init.init(app_init.InitIsolateType.flutterIsolate);

  final c = KiwiContainer().resolve<DiContainer>();
  final result = await StartupSync(c)(message.account, message.accountPref);
  return result.toJson();
}
