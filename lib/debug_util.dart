import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/string_extension.dart';
import 'package:path/path.dart' as path;

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

String logFilename(String? filename) {
  if (shouldLogFileName || filename == null) {
    return "$filename";
  }
  try {
    final basename = path.basenameWithoutExtension(filename);
    final displayName = basename.length <= 6
        ? basename
        : "${basename.slice(0, 3)}***${basename.slice(-3)}";
    return "${path.dirname(filename) != "." ? "***/" : ""}"
        "$displayName"
        "${path.extension(filename)}";
  } catch (_) {
    return "***";
  }
}

@visibleForTesting
bool shouldLogFileName = kDebugMode;
