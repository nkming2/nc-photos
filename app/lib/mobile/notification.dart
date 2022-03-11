import 'package:flutter/foundation.dart';
import 'package:nc_photos/platform/notification.dart' as itf;
import 'package:nc_photos_plugin/nc_photos_plugin.dart' as plugin;

class AndroidDownloadSuccessfulNotification extends _AndroidNotification {
  AndroidDownloadSuccessfulNotification(
    this.fileUris,
    this.mimeTypes, {
    int? notificationId,
  }) : replaceId = notificationId;

  @override
  doNotify() => plugin.Notification.notifyDownloadSuccessful(
      fileUris, mimeTypes, replaceId);

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
  doNotify() => plugin.Notification.notifyDownloadProgress(
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
  doNotify() => plugin.Notification.notifyLogSaveSuccessful(fileUri);

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
      await plugin.Notification.dismiss(notificationId!);
    }
  }

  @protected
  Future<int?> doNotify();

  int? notificationId;
}
