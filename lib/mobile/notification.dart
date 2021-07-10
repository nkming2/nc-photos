import 'package:nc_photos/mobile/android/notification.dart';
import 'package:nc_photos/platform/notification.dart' as itf;

class AndroidItemDownloadSuccessfulNotification
    extends itf.ItemDownloadSuccessfulNotification {
  AndroidItemDownloadSuccessfulNotification(this.fileUris, this.mimeTypes);

  @override
  Future<void> notify() {
    return Notification.notifyItemsDownloadSuccessful(fileUris, mimeTypes);
  }

  final List<String> fileUris;
  final List<String> mimeTypes;
}
