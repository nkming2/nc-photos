import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;

class LogCapturer {
  factory LogCapturer() {
    _inst ??= LogCapturer._();
    return _inst!;
  }

  LogCapturer._();

  /// Start capturing logs
  void start() {
    _isEnable = true;
  }

  /// Stop capturing and save the captured logs
  Future<dynamic> stop() {
    _isEnable = false;
    final saver = platform.FileSaver();
    final content = const Utf8Encoder().convert(_logs.join("\n"));
    _logs.clear();
    return saver.saveFile("nc-photos.log", content);
  }

  void onLog(String log) {
    if (_isEnable) {
      _logs.add(log);
    }
  }

  bool get isEnable => _isEnable;

  final _logs = <String>[];
  bool _isEnable = false;

  static LogCapturer? _inst;
}

String logFilename(String? filename) =>
    shouldLogFileName || filename == null ? "$filename" : "***";

const bool shouldLogFileName = kDebugMode;
