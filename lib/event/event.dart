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
    _subscription.cancel();
    _subscription = null;
  }

  final void Function(T) _listener;
  final _stream = KiwiContainer().resolve<EventBus>().on<T>();
  StreamSubscription<T> _subscription;

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

class FileMetadataUpdatedEvent {
  FileMetadataUpdatedEvent(this.account, this.file);

  final Account account;
  final File file;
}

class FileRemovedEvent {
  FileRemovedEvent(this.account, this.file);

  final Account account;
  final File file;
}
