abstract class NotificationManager {
  /// Show a notification and optionally return a unique identifier to dismiss
  /// this notification later
  Future<dynamic> notify(Notification notification);

  /// Dismiss a notification
  ///
  /// This could have no effect if not supported by the platform
  Future<void> dismiss(dynamic id);
}

class Notification {}

class LogSaveSuccessfulNotification implements Notification {
  const LogSaveSuccessfulNotification(this.result);

  final dynamic result;
}
