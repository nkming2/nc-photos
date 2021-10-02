import 'package:flutter/foundation.dart';
import 'package:nc_photos/mobile/android/notification.dart';
import 'package:nc_photos/platform/notification.dart' as itf;

class AndroidDownloadSuccessfulNotification extends _AndroidNotification {
  AndroidDownloadSuccessfulNotification(
    this.fileUris,
    this.mimeTypes, {
    int? notificationId,
  }) : replaceId = notificationId;

  @override
  doNotify() =>
      Notification.notifyDownloadSuccessful(fileUris, mimeTypes, replaceId);

  final List<String> fileUris;
  final List<String?> mimeTypes;
  final int? replaceId;
}

class AndroidDownloadProgressNotification extends _AndroidNotification {
  AndroidDownloadProgressNotification(
    this.progress,
    this.max, {
    this.currentItemTitle,
  });

  @override
  doNotify() => Notification.notifyDownloadProgress(
      progress, max, currentItemTitle, notificationId);

  Future<void> update(
    int progress, {
    String? currentItemTitle,
  }) async {
    this.progress = progress;
    this.currentItemTitle = currentItemTitle;
    await doNotify();
  }

  int progress;
  final int max;
  String? currentItemTitle;
}

class AndroidLogSaveSuccessfulNotification extends _AndroidNotification {
  AndroidLogSaveSuccessfulNotification(this.fileUri);

  @override
  doNotify() => Notification.notifyLogSaveSuccessful(fileUri);

  final String fileUri;
}

abstract class _AndroidNotification extends itf.Notification {
  @override
  notify() async {
    notificationId = await doNotify();
  }

  @override
  dismiss() async {
    if (notificationId != null) {
      await Notification.dismiss(notificationId!);
    }
  }

  @protected
  Future<int?> doNotify();

  int? notificationId;
}
