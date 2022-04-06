import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class NativeEventObject {
  NativeEventObject(this.event, this.data);

  final String event;
  final String? data;
}

class NativeEvent {
  static Future<void> fire(NativeEventObject ev) =>
      _methodChannel.invokeMethod("fire", <String, dynamic>{
        "event": ev.event,
        if (ev.data != null) "data": ev.data,
      });

  static Stream get stream => _eventStream;

  static const _eventChannel = EventChannel("${k.libId}/native_event");
  static const _methodChannel = MethodChannel("${k.libId}/native_event_method");

  static late final _eventStream = _eventChannel
      .receiveBroadcastStream()
      .map((event) {
        if (event is Map) {
          return NativeEventObject(event["event"], event["data"]);
        } else {
          return event;
        }
      });
}
