import 'package:logging/logging.dart';
import 'package:nc_photos/type.dart';

abstract class AlbumUpgrader {
  JsonObj? call(JsonObj json);
}

/// Upgrade v1 Album to v2
class AlbumUpgraderV1 implements AlbumUpgrader {
  AlbumUpgraderV1({
    this.logFilePath,
  });

  @override
  call(JsonObj json) {
    // v1 album items are corrupted in one of the updates, drop it
    _log.fine("[call] Upgrade v1 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    result["items"] = [];
    return result;
  }

  /// File path for logging only
  final String? logFilePath;

  static final _log = Logger("entity.album.upgrader.AlbumUpgraderV1");
}

/// Upgrade v2 Album to v3
class AlbumUpgraderV2 implements AlbumUpgrader {
  AlbumUpgraderV2({
    this.logFilePath,
  });

  @override
  call(JsonObj json) {
    // move v2 items to v3 provider
    _log.fine("[call] Upgrade v2 Album for file: $logFilePath");
    final result = JsonObj.from(json);
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
  final String? logFilePath;

  static final _log = Logger("entity.album.upgrader.AlbumUpgraderV2");
}

/// Upgrade v3 Album to v4
class AlbumUpgraderV3 implements AlbumUpgrader {
  AlbumUpgraderV3({
    this.logFilePath,
  });

  @override
  call(JsonObj json) {
    // move v3 items to v4 provider
    _log.fine("[call] Upgrade v3 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    // add the descending time sort provider
    result["sortProvider"] = <String, dynamic>{
      "type": "time",
      "content": {
        "isAscending": false,
      },
    };
    return result;
  }

  /// File path for logging only
  final String? logFilePath;

  static final _log = Logger("entity.album.upgrader.AlbumUpgraderV3");
}
