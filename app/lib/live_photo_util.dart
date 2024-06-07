import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

LivePhotoType? getLivePhotoTypeFromFile(FileDescriptor file) {
  final filenameL = file.filename.toLowerCase();
  if (filenameL.startsWith("pxl_") && filenameL.endsWith(".mp.jpg")) {
    return LivePhotoType.googleMp;
  } else if (filenameL.startsWith("mvimg_") && filenameL.endsWith(".jpg")) {
    return LivePhotoType.googleMvimg;
  } else {
    return null;
  }
}
