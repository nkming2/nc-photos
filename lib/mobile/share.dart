import 'package:nc_photos/mobile/android/share.dart';
import 'package:nc_photos/platform/share.dart' as itf;

class AndroidFileShare extends itf.FileShare {
  AndroidFileShare(this.fileUris, this.mimeTypes);

  @override
  share() {
    return Share.shareItems(fileUris, mimeTypes);
  }

  final List<String> fileUris;
  final List<String?> mimeTypes;
}

class AndroidTextShare extends itf.TextShare {
  AndroidTextShare(
    this.text, {
    this.mimeType = "text/plain",
  });

  @override
  share() {
    return Share.shareText(text, mimeType);
  }

  final String text;
  final String? mimeType;
}
