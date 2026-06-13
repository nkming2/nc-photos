abstract class ImageEnhancerAndroidConstant {
  static const notificationChannelId = "ImageProcessorService";
  static const notificationChannelName = "Image processing";
  static const notificationChannelDescription =
      "Enhance images in the background";
  static const notificationChannelImportance = 2; // IMPORTANCE_LOW
  static const notificationId = 5000;
  static const foregroundServiceType =
      8192; // FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING
  static const resultNotificationId = 5001;
  static const resultNotificationAction = "ACTION_SHOW_IMAGE_PROCESSOR_RESULT";
}
