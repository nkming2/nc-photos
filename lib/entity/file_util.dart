import 'package:nc_photos/entity/file.dart';

bool isSupportedFormat(File file) =>
    _supportedFormatMimes.contains(file.contentType);

const _supportedFormatMimes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
];
