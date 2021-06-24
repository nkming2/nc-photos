import 'package:logging/logging.dart';

abstract class AlbumUpgrader {
  Map<String, dynamic> call(Map<String, dynamic> json);
}

/// Upgrade v1 Album to v2
class AlbumUpgraderV1 implements AlbumUpgrader {
  AlbumUpgraderV1({
    this.logFilePath,
  });

  Map<String, dynamic> call(Map<String, dynamic> json) {
    // v1 album items are corrupted in one of the updates, drop it
    _log.fine("[call] Upgrade v1 Album for file: $logFilePath");
    final result = Map<String, dynamic>.from(json);
    result["items"] = [];
    return result;
  }

  /// File path for logging only
  final String logFilePath;

  static final _log = Logger("entity.album.upgrader.AlbumUpgraderV1");
}
