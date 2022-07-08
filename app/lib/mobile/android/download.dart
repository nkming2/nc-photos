import 'dart:async';

import 'package:flutter/services.dart';

class DownloadEvent {
  static StreamSubscription<DownloadCancelEvent> listenDownloadCancel() =>
      _cancelStream.listen(null);

  /// User canceled the download job
  static const exceptionCodeUserCanceled = "userCanceled";

  static const _downloadCancelChannel = EventChannel(
      "com.nkming.nc_photos/download_event/action_download_cancel");

  static final _cancelStream = _downloadCancelChannel
      .receiveBroadcastStream()
      .map((data) => DownloadCancelEvent(
            data["notificationId"],
          ));
}

class DownloadCancelEvent {
  const DownloadCancelEvent(this.notificationId);

  final int notificationId;
}
