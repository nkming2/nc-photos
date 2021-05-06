import 'package:nc_photos/entity/file.dart';

bool isSupportedFormat(File file) =>
    _supportedFormatMimes.contains(file.contentType);

bool isSupportedImageFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("image/") == true;

const _supportedFormatMimes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
];
