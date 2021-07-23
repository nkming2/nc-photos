import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';

class AppEventListener<T> {
  AppEventListener(this._listener);

  void begin() {
    if (_subscription != null) {
      _log.warning("[beginListenEvent] Already listening");
      return;
    }
    _subscription = _stream.listen(_listener);
  }

  void end() {
    if (_subscription == null) {
      _log.warning("[endListenEvent] Already not listening");
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
}

class FileRemovedEvent {
  FileRemovedEvent(this.account, this.file);

  final Account account;
  final File file;
}

class ThemeChangedEvent {}

class LanguageChangedEvent {}

extension FilePropertyUpdatedEventExtension on FilePropertyUpdatedEvent {
  bool hasAnyProperties(List<int> properties) =>
      properties.any((p) => this.properties & p != 0);
}
