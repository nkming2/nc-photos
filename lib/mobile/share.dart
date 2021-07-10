import 'package:nc_photos/mobile/android/share.dart';
import 'package:nc_photos/platform/share.dart' as itf;

class AndroidShare extends itf.Share {
  AndroidShare(this.fileUris, this.mimeTypes);

  @override
  Future<void> share() {
    return Share.shareItems(fileUris, mimeTypes);
  }

  final List<String> fileUris;
  final List<String> mimeTypes;
}
