import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/ci_string.dart';
import 'package:np_common/string_extension.dart';

part 'entity_converter.g.dart';

class ApiFaceConverter {
  static Face fromApi(api.Face face) {
    return Face(
      id: face.id,
      fileId: face.fileId,
    );
  }
}

class ApiFavoriteConverter {
  static Favorite fromApi(api.Favorite favorite) {
    return Favorite(
      fileId: favorite.fileId,
    );
  }
}

@npLog
class ApiFileConverter {
  static File fromApi(api.File file) {
    final metadata = file.customProperties?["com.nkming.nc_photos:metadata"]
        ?.run((obj) => Metadata.fromJson(
              jsonDecode(obj),
              upgraderV1: MetadataUpgraderV1(
                fileContentType: file.contentType,
                logFilePath: file.href,
              ),
              upgraderV2: MetadataUpgraderV2(
                fileContentType: file.contentType,
                logFilePath: file.href,
              ),
              upgraderV3: MetadataUpgraderV3(
                fileContentType: file.contentType,
                logFilePath: file.href,
              ),
            ));
    return File(
      path: _hrefToPath(file.href),
      contentLength: file.contentLength,
      contentType: file.contentType,
      etag: file.etag,
      lastModified: file.lastModified,
      isCollection: file.isCollection,
      hasPreview: file.hasPreview,
      fileId: file.fileId,
      isFavorite: file.favorite,
      ownerId: file.ownerId?.toCi(),
      ownerDisplayName: file.ownerDisplayName,
      trashbinFilename: file.trashbinFilename,
      trashbinOriginalLocation: file.trashbinOriginalLocation,
      trashbinDeletionTime: file.trashbinDeletionTime,
      metadata: metadata,
      isArchived: file.customProperties?["com.nkming.nc_photos:is-archived"]
          ?.run((obj) => obj == "true"),
      overrideDateTime: file
          .customProperties?["com.nkming.nc_photos:override-date-time"]
          ?.run((obj) => DateTime.parse(obj)),
      location: file.customProperties?["com.nkming.nc_photos:location"]
          ?.run((obj) => ImageLocation.fromJson(jsonDecode(obj))),
    );
  }

  static String _hrefToPath(String href) {
    final rawPath = href.trimLeftAny("/");
    final pos = rawPath.indexOf("remote.php");
    if (pos == -1) {
      // what?
      _log.warning("[_hrefToPath] Unknown href value: $rawPath");
      return rawPath;
    } else {
      return rawPath.substring(pos);
    }
  }

  static final _log = _$ApiFileConverterNpLog.log;
}

class ApiPersonConverter {
  static Person fromApi(api.Person person) {
    return Person(
      name: person.name,
      thumbFaceId: person.thumbFaceId,
      count: person.count,
    );
  }
}

class ApiShareConverter {
  static Share fromApi(api.Share share) {
    final shareType = ShareTypeExtension.fromValue(share.shareType);
    final itemType = ShareItemTypeExtension.fromValue(share.itemType);
    return Share(
      id: share.id,
      shareType: shareType,
      stime: DateTime.fromMillisecondsSinceEpoch(share.stime * 1000),
      uidOwner: share.uidOwner.toCi(),
      displaynameOwner: share.displaynameOwner,
      uidFileOwner: share.uidFileOwner.toCi(),
      path: share.path,
      itemType: itemType,
      mimeType: share.mimeType,
      itemSource: share.itemSource,
      // when shared with a password protected link, shareWith somehow contains
      // the password, which doesn't make sense. We set it to null instead
      shareWith:
          shareType == ShareType.publicLink ? null : share.shareWith?.toCi(),
      shareWithDisplayName: share.shareWithDisplayName,
      url: share.url,
    );
  }
}

class ApiShareeConverter {
  static Sharee fromApi(api.Sharee sharee) {
    return Sharee(
      type: _keyTypes[sharee.type]!,
      label: sharee.label,
      shareType: sharee.shareType,
      shareWith: sharee.shareWith.toCi(),
      shareWithDisplayNameUnique: sharee.shareWithDisplayNameUnique,
    );
  }

  static const _keyTypes = {
    "users": ShareeType.user,
    "groups": ShareeType.group,
    "remotes": ShareeType.remote,
    "remote_groups": ShareeType.remoteGroup,
    "emails": ShareeType.email,
    "circles": ShareeType.circle,
    "rooms": ShareeType.room,
    "deck": ShareeType.deck,
    "lookup": ShareeType.lookup,
  };
}

class ApiTagConverter {
  static Tag fromApi(api.Tag tag) {
    return Tag(
      id: tag.id,
      displayName: tag.displayName,
      userVisible: tag.userVisible,
      userAssignable: tag.userAssignable,
    );
  }
}

class ApiTaggedFileConverter {
  static TaggedFile fromApi(api.TaggedFile taggedFile) {
    return TaggedFile(
      fileId: taggedFile.fileId,
    );
  }
}
