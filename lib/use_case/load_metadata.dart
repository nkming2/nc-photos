import 'dart:typed_data';

import 'package:exifdart/exifdart.dart' as exifdart;
import 'package:exifdart/exifdart_memory.dart';
import 'package:flutter/foundation.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/image_size_getter_util.dart';

class LoadMetadata {
  /// Load metadata of [binary], which is the content of [file]
  Future<Map<String, dynamic>> call(
      Account account, File file, Uint8List binary) {
    return _loadMetadata(
      file: file,
      exifdartReaderBuilder: () => MemoryBlobReader(binary),
      imageSizeGetterInputBuilder: () => AsyncMemoryInput(binary),
    );
  }

  Future<Map<String, dynamic>> _loadMetadata({
    required File file,
    required exifdart.AbstractBlobReader Function() exifdartReaderBuilder,
    required AsyncImageInput Function() imageSizeGetterInputBuilder,
  }) async {
    var metadata = exifdart.Metadata();
    if (file_util.isMetadataSupportedFormat(file)) {
      try {
        metadata = await exifdart.readMetadata(exifdartReaderBuilder());
      } catch (e, stacktrace) {
        _log.shout(
            "[_loadMetadata] Failed while readMetadata for ${file.contentType} file" +
                (kDebugMode ? ": ${file.path}" : ""),
            e,
            stacktrace);
        // ignore exif
      }
    }

    int imageWidth = 0, imageHeight = 0;
    if (metadata.imageWidth == null || metadata.imageHeight == null) {
      try {
        final resolution =
            await AsyncImageSizeGetter.getSize(imageSizeGetterInputBuilder());
        // image size getter doesn't handle exif orientation
        if (metadata.exif?.containsKey("Orientation") == true &&
            metadata.exif!["Orientation"] >= 5 &&
            metadata.exif!["Orientation"] <= 8) {
          // 90 deg CW/CCW
          imageWidth = resolution.height;
          imageHeight = resolution.width;
        } else {
          imageWidth = resolution.width;
          imageHeight = resolution.height;
        }
      } catch (e, stacktrace) {
        // is this even an image file?
        _log.shout(
            "[_loadMetadata] Failed while getSize for ${file.contentType} file" +
                (kDebugMode ? ": ${file.path}" : ""),
            e,
            stacktrace);
      }
    } else {
      if (metadata.rotateAngleCcw != null &&
          metadata.rotateAngleCcw! % 180 != 0) {
        imageWidth = metadata.imageHeight!;
        imageHeight = metadata.imageWidth!;
      } else {
        imageWidth = metadata.imageWidth!;
        imageHeight = metadata.imageHeight!;
      }
    }

    return {
      if (metadata.exif != null) "exif": metadata.exif,
      if (imageWidth > 0 && imageHeight > 0)
        "resolution": {
          "width": imageWidth,
          "height": imageHeight,
        },
    };
  }

  static final _log = Logger("use_case.load_metadata.LoadMetadata");
}
