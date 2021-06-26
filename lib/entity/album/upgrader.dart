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

/// Upgrade v2 Album to v3
class AlbumUpgraderV2 implements AlbumUpgrader {
  AlbumUpgraderV2({
    this.logFilePath,
  });

  Map<String, dynamic> call(Map<String, dynamic> json) {
    // move v2 items to v3 provider
    _log.fine("[call] Upgrade v2 Album for file: $logFilePath");
    final result = Map<String, dynamic>.from(json);
    result["provider"] = <String, dynamic>{
      "type": "static",
      "content": <String, dynamic>{
        "items": result["items"],
      }
    };
    result.remove("items");

    // add the auto cover provider
    result["coverProvider"] = <String, dynamic>{
      "type": "auto",
      "content": {},
    };
    return result;
  }

  /// File path for logging only
  final String logFilePath;

  static final _log = Logger("entity.album.upgrader.AlbumUpgraderV2");
}
