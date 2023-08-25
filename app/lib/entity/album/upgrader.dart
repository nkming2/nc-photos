import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/object_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';
import 'package:np_string/np_string.dart';
import 'package:tuple/tuple.dart';

part 'upgrader.g.dart';

abstract class AlbumUpgrader {
  JsonObj? doJson(JsonObj json);
  sql.Album? doDb(sql.Album dbObj);
}

/// Upgrade v1 Album to v2
@npLog
class AlbumUpgraderV1 implements AlbumUpgrader {
  AlbumUpgraderV1({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    // v1 album items are corrupted in one of the updates, drop it
    _log.fine("[doJson] Upgrade v1 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    result["items"] = [];
    return result;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v2 Album to v3
@npLog
class AlbumUpgraderV2 implements AlbumUpgrader {
  AlbumUpgraderV2({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    // move v2 items to v3 provider
    _log.fine("[doJson] Upgrade v2 Album for file: $logFilePath");
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

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v3 Album to v4
@npLog
class AlbumUpgraderV3 implements AlbumUpgrader {
  AlbumUpgraderV3({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    // move v3 items to v4 provider
    _log.fine("[doJson] Upgrade v3 Album for file: $logFilePath");
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

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v4 Album to v5
@npLog
class AlbumUpgraderV4 implements AlbumUpgrader {
  AlbumUpgraderV4({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    _log.fine("[doJson] Upgrade v4 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    try {
      if (result["provider"]["type"] != "static") {
        return result;
      }
      final latestItem = (result["provider"]["content"]["items"] as List)
          .map((e) => e.cast<String, dynamic>())
          .where((e) => e["type"] == "file")
          .map((e) => e["content"]["file"] as JsonObj)
          .map((e) {
            final overrideDateTime = e["overrideDateTime"] == null
                ? null
                : DateTime.parse(e["overrideDateTime"]);
            final String? dateTimeOriginalStr =
                e["metadata"]?["exif"]?["DateTimeOriginal"];
            final dateTimeOriginal =
                dateTimeOriginalStr == null || dateTimeOriginalStr.isEmpty
                    ? null
                    : Exif.dateTimeFormat.parse(dateTimeOriginalStr).toUtc();
            final lastModified = e["lastModified"] == null
                ? null
                : DateTime.parse(e["lastModified"]);
            final latestItemTime =
                overrideDateTime ?? dateTimeOriginal ?? lastModified;

            // remove metadata
            e.remove("metadata");
            if (latestItemTime != null) {
              return Tuple2(latestItemTime, e);
            } else {
              return null;
            }
          })
          .whereType<Tuple2<DateTime, JsonObj>>()
          .sorted((a, b) => a.item1.compareTo(b.item1))
          .lastOrNull;
      if (latestItem != null) {
        // save the latest item time
        result["provider"]["content"]["latestItemTime"] =
            latestItem.item1.toIso8601String();
        if (result["coverProvider"]["type"] == "auto") {
          // save the cover
          result["coverProvider"]["content"]["coverFile"] =
              Map.of(latestItem.item2);
        }
      }
    } catch (e, stackTrace) {
      // this upgrade is not a must, if it failed then just leave it and it'll
      // be upgraded the next time the album is saved
      _log.shout("[doJson] Failed while upgrade", e, stackTrace);
    }
    return result;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v5 Album to v6
@npLog
class AlbumUpgraderV5 implements AlbumUpgrader {
  const AlbumUpgraderV5(
    this.account, {
    this.albumFile,
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    _log.fine("[doJson] Upgrade v5 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    try {
      if (result["provider"]["type"] != "static") {
        return result;
      }
      for (final item in (result["provider"]["content"]["items"] as List)) {
        final CiString addedBy;
        if (result.containsKey("albumFile")) {
          addedBy = result["albumFile"]["ownerId"] == null
              ? account.userId
              : CiString(result["albumFile"]["ownerId"]);
        } else {
          addedBy = albumFile?.ownerId ?? account.userId;
        }
        item["addedBy"] = addedBy.toString();
        item["addedAt"] = result["lastUpdated"];
      }
    } catch (e, stackTrace) {
      // this upgrade is not a must, if it failed then just leave it and it'll
      // be upgraded the next time the album is saved
      _log.shout("[doJson] Failed while upgrade", e, stackTrace);
    }
    return result;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  final Account account;
  final File? albumFile;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v6 Album to v7
@npLog
class AlbumUpgraderV6 implements AlbumUpgrader {
  const AlbumUpgraderV6({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    _log.fine("[doJson] Upgrade v6 Album for file: $logFilePath");
    return json;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v7 Album to v8
@npLog
class AlbumUpgraderV7 implements AlbumUpgrader {
  const AlbumUpgraderV7({
    this.logFilePath,
  });

  @override
  doJson(JsonObj json) {
    _log.fine("[doJson] Upgrade v7 Album for file: $logFilePath");
    return json;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) => null;

  /// File path for logging only
  final String? logFilePath;
}

/// Upgrade v8 Album to v9
@npLog
class AlbumUpgraderV8 implements AlbumUpgrader {
  const AlbumUpgraderV8({
    this.logFilePath,
  });

  @override
  JsonObj? doJson(JsonObj json) {
    _log.fine("[doJson] Upgrade v8 Album for file: $logFilePath");
    final result = JsonObj.from(json);
    if (result["coverProvider"]["type"] == "manual") {
      final content = (result["coverProvider"]["content"]["coverFile"] as Map)
          .cast<String, dynamic>();
      final fd = _fileJsonToFileDescriptorJson(content);
      // some very old album file may contain files w/o id
      if (fd["fdId"] != null) {
        result["coverProvider"]["content"]["coverFile"] = fd;
      } else {
        result["coverProvider"]["content"] = {};
      }
    } else if (result["coverProvider"]["type"] == "auto") {
      final content = (result["coverProvider"]["content"]["coverFile"] as Map?)
          ?.cast<String, dynamic>();
      if (content != null) {
        final fd = _fileJsonToFileDescriptorJson(content);
        if (fd["fdId"] != null) {
          result["coverProvider"]["content"]["coverFile"] = fd;
        } else {
          result["coverProvider"]["content"] = {};
        }
      }
    }
    return result;
  }

  @override
  sql.Album? doDb(sql.Album dbObj) {
    _log.fine("[doDb] Upgrade v8 Album for file: $logFilePath");
    if (dbObj.coverProviderType == "manual") {
      final content = (jsonDecode(dbObj.coverProviderContent) as Map)
          .cast<String, dynamic>();
      final converted = _fileJsonToFileDescriptorJson(
          (content["coverFile"] as Map).cast<String, dynamic>());
      if (converted["fdId"] != null) {
        return dbObj.copyWith(
          coverProviderContent: jsonEncode({"coverFile": converted}),
        );
      } else {
        return dbObj.copyWith(coverProviderContent: "{}");
      }
    } else if (dbObj.coverProviderType == "auto") {
      final content = (jsonDecode(dbObj.coverProviderContent) as Map)
          .cast<String, dynamic>();
      if (content["coverFile"] != null) {
        final converted = _fileJsonToFileDescriptorJson(
            (content["coverFile"] as Map).cast<String, dynamic>());
        if (converted["fdId"] != null) {
          return dbObj.copyWith(
            coverProviderContent: jsonEncode({"coverFile": converted}),
          );
        } else {
          return dbObj.copyWith(coverProviderContent: "{}");
        }
      }
    }
    return dbObj;
  }

  static JsonObj _fileJsonToFileDescriptorJson(JsonObj json) {
    return {
      "fdPath": json["path"],
      "fdId": json["fileId"],
      "fdMime": json["contentType"],
      "fdIsArchived": json["isArchived"] ?? false,
      // File.isFavorite is serialized as int
      "fdIsFavorite": json["isFavorite"] == 1,
      "fdDateTime": json["overrideDateTime"] ??
          (json["metadata"]?["exif"]?["DateTimeOriginal"] as String?)?.run(
              (d) => Exif.dateTimeFormat.parse(d).toUtc().toIso8601String()) ??
          json["lastModified"] ??
          clock.now().toUtc().toIso8601String(),
    };
  }

  /// File path for logging only
  final String? logFilePath;
}

abstract class AlbumUpgraderFactory {
  const AlbumUpgraderFactory();

  AlbumUpgraderV1? buildV1();
  AlbumUpgraderV2? buildV2();
  AlbumUpgraderV3? buildV3();
  AlbumUpgraderV4? buildV4();
  AlbumUpgraderV5? buildV5();
  AlbumUpgraderV6? buildV6();
  AlbumUpgraderV7? buildV7();
  AlbumUpgraderV8? buildV8();
}

class DefaultAlbumUpgraderFactory extends AlbumUpgraderFactory {
  const DefaultAlbumUpgraderFactory({
    required this.account,
    this.albumFile,
    this.logFilePath,
  });

  @override
  buildV1() => AlbumUpgraderV1(logFilePath: logFilePath);

  @override
  buildV2() => AlbumUpgraderV2(logFilePath: logFilePath);

  @override
  buildV3() => AlbumUpgraderV3(logFilePath: logFilePath);

  @override
  buildV4() => AlbumUpgraderV4(logFilePath: logFilePath);

  @override
  buildV5() => AlbumUpgraderV5(
        account,
        albumFile: albumFile,
        logFilePath: logFilePath,
      );

  @override
  buildV6() => AlbumUpgraderV6(logFilePath: logFilePath);

  @override
  buildV7() => AlbumUpgraderV7(logFilePath: logFilePath);

  @override
  AlbumUpgraderV8? buildV8() => AlbumUpgraderV8(logFilePath: logFilePath);

  final Account account;
  final File? albumFile;

  /// File path for logging only
  final String? logFilePath;
}
