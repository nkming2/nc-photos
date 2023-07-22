import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/startup_sync.dart';

class SyncController {
  SyncController({
    required this.account,
    this.onPeopleUpdated,
  });

  void dispose() {
    _isDisposed = true;
  }

  Future<void> requestSync(
      Account account, PersonProvider personProvider) async {
    if (_isDisposed) {
      return;
    }
    if (_syncCompleter == null) {
      _syncCompleter = Completer();
      final result = await StartupSync.runInIsolate(account, personProvider);
      if (!_isDisposed && result.isSyncPersonUpdated) {
        onPeopleUpdated?.call();
      }
      _syncCompleter!.complete();
    } else {
      return _syncCompleter!.future;
    }
  }

  Future<void> requestResync(
      Account account, PersonProvider personProvider) async {
    if (_syncCompleter?.isCompleted == true) {
      _syncCompleter = null;
      return requestSync(account, personProvider);
    } else {
      // already syncing
      return requestSync(account, personProvider);
    }
  }

  final Account account;
  final VoidCallback? onPeopleUpdated;

  Completer<void>? _syncCompleter;
  var _isDisposed = false;
}
