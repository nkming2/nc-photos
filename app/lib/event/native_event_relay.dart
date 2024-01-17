import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/controller/files_controller.dart';
import 'package:nc_photos/event/native_event.dart';
import 'package:nc_photos/stream_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_platform_message_relay/np_platform_message_relay.dart';

part 'native_event_relay.g.dart';

@npLog
class NativeEventRelay {
  NativeEventRelay({
    required this.filesController,
  }) {
    _subscription = MessageRelay.stream.whereType<Message>().listen((event) {
      switch (event.event) {
        case FileExifUpdatedEvent.id:
          _onFileExifUpdatedEvent(FileExifUpdatedEvent.fromEvent(event));
          break;

        default:
          _log.severe('Unknown event: ${event.event}');
          break;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _onFileExifUpdatedEvent(FileExifUpdatedEvent ev) {
    filesController.applySyncResult(fileExifs: ev.fileIds);
  }

  final FilesController filesController;
  StreamSubscription? _subscription;
}
