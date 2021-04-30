import 'package:nc_photos/mobile/android/notification.dart';
import 'package:nc_photos/platform/notification.dart' as itf;

class AndroidItemDownloadSuccessfulNotification
    extends itf.ItemDownloadSuccessfulNotification {
  AndroidItemDownloadSuccessfulNotification(this.fileUri, this.mimeType);

  @override
  Future<void> notify() {
    return Notification.notifyItemDownloadSuccessful(fileUri, mimeType);
  }

  final String fileUri;
  final String mimeType;
}
