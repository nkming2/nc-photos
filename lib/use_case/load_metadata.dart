import 'dart:typed_data';

import 'package:exifdart/exifdart.dart' as exifdart;
import 'package:exifdart/exifdart_memory.dart';
import 'package:flutter/foundation.dart';
import 'package:image_size_getter/image_size_getter.dart';
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
    @required File file,
    exifdart.AbstractBlobReader Function() exifdartReaderBuilder,
    AsyncImageInput Function() imageSizeGetterInputBuilder,
  }) async {
    exifdart.Metadata metadata;
    if (file_util.isMetadataSupportedFormat(file)) {
      metadata = await exifdart.readMetadata(exifdartReaderBuilder());
    } else {
      metadata = exifdart.Metadata();
    }
    int imageWidth, imageHeight;
    if (metadata.imageWidth == null || metadata.imageHeight == null) {
      final resolution =
          await AsyncImageSizeGetter.getSize(imageSizeGetterInputBuilder());
      // image size getter doesn't handle exif orientation
      if (metadata.exif?.containsKey("Orientation") == true &&
          metadata.exif["Orientation"] >= 5 &&
          metadata.exif["Orientation"] <= 8) {
        // 90 deg CW/CCW
        imageWidth = resolution.height;
        imageHeight = resolution.width;
      } else {
        imageWidth = resolution.width;
        imageHeight = resolution.height;
      }
    } else {
      if (metadata.rotateAngleCcw != null &&
          metadata.rotateAngleCcw % 180 != 0) {
        imageWidth = metadata.imageHeight;
        imageHeight = metadata.imageWidth;
      } else {
        imageWidth = metadata.imageWidth;
        imageHeight = metadata.imageHeight;
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
}
