import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/pref.dart';

class AppEventListener<T> {
  AppEventListener(this._listener);

  void begin() {
    if (_subscription != null) {
      _log.warning("[begin] Already listening");
      return;
    }
    _subscription = _stream.listen(_listener);
  }

  void end() {
    if (_subscription == null) {
      _log.warning("[end] Already not listening");
      return;
    }
    _subscription?.cancel();
    _subscription = null;
  }

  final void Function(T) _listener;
  final _stream = KiwiContainer().resolve<EventBus>().on<T>();
  StreamSubscription<T>? _subscription;

  final _log = Logger("event.event.AppEventListener<${T.runtimeType}>");
}

class AccountPrefUpdatedEvent {
  const AccountPrefUpdatedEvent(this.pref, this.key, this.value);

  final AccountPref pref;
  final PrefKey key;
  final dynamic value;
}

class AlbumCreatedEvent {
  AlbumCreatedEvent(this.account, this.album);

  final Account account;
  final Album album;
}

class AlbumUpdatedEvent {
  AlbumUpdatedEvent(this.account, this.album);

  final Account account;
  final Album album;
}

class FilePropertyUpdatedEvent {
  FilePropertyUpdatedEvent(this.account, this.file, this.properties);

  final Account account;
  final File file;
  final int properties;

  // Bit masks for properties field
  static const propMetadata = 0x01;
  static const propIsArchived = 0x02;
  static const propOverrideDateTime = 0x04;
  static const propFavorite = 0x08;
}

class FileRemovedEvent {
  FileRemovedEvent(this.account, this.file);

  final Account account;
  final File file;
}

class FileTrashbinRestoredEvent {
  FileTrashbinRestoredEvent(this.account, this.file);

  final Account account;
  final File file;
}

class FileMovedEvent {
  FileMovedEvent(this.account, this.file, this.destination);

  final Account account;
  final File file;
  final String destination;
}

class ShareCreatedEvent {
  const ShareCreatedEvent(this.account, this.share);

  final Account account;
  final Share share;
}

class ShareRemovedEvent {
  const ShareRemovedEvent(this.account, this.share);

  final Account account;
  final Share share;
}

class FavoriteResyncedEvent {
  const FavoriteResyncedEvent(
      this.account, this.newFavorites, this.removedFavorites);

  final Account account;
  final List<File> newFavorites;
  final List<File> removedFavorites;
}

class ThemeChangedEvent {}

class LanguageChangedEvent {}

enum MetadataTaskState {
  /// No work is being done
  idle,

  /// Processing images
  prcoessing,

  /// Paused on data network
  waitingForWifi,

  /// Paused on low battery
  lowBattery,
}

class MetadataTaskStateChangedEvent {
  const MetadataTaskStateChangedEvent(this.state);

  final MetadataTaskState state;
}

class PrefUpdatedEvent {
  PrefUpdatedEvent(this.key, this.value);

  final PrefKey key;
  final dynamic value;
}

extension FilePropertyUpdatedEventExtension on FilePropertyUpdatedEvent {
  bool hasAnyProperties(List<int> properties) =>
      properties.any((p) => this.properties & p != 0);
}
