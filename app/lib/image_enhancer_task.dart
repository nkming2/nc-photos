import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image/image.dart' as imagelib;
import 'package:logging/logging.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/image_enhancer_util.dart';
import 'package:np_common/size.dart';
import 'package:np_common/type.dart';
import 'package:np_exiv2/np_exiv2.dart' as exiv2;
import 'package:np_ffi_torch/np_ffi_torch.dart' as torch;
import 'package:np_log/np_log.dart';
import 'package:np_platform_local_media/np_platform_local_media.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';
import 'package:np_platform_util/np_platform_util.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'image_enhancer_task.g.dart';

enum ImageEnhancerTaskType { retouch, superResolution, motionDeblur, derain }

@npLog
class ImageEnhancerTask {
  ImageEnhancerTask._({
    required this.type,
    required this.platformIdentifier,
    required this.filename,
  });

  factory ImageEnhancerTask(JsonObj args) {
    return ImageEnhancerTask._(
      type: ImageEnhancerTaskType.values[args["type"]],
      platformIdentifier: args["platformIdentifier"],
      filename: args["filename"],
    );
  }

  static JsonObj encodeArgument({
    required ImageEnhancerTaskType type,
    required String platformIdentifier,
    required String filename,
  }) {
    return {
      "type": type.index,
      "platformIdentifier": platformIdentifier,
      "filename": filename,
    };
  }

  static void _showStatusNotif({
    required String title,
    String? body,
    String? payload,
    bool ongoing = false,
  }) {
    FlutterLocalNotificationsPlugin().show(
      id: ImageEnhancerAndroidConstant.resultNotificationId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ImageEnhancerAndroidConstant.notificationChannelId,
          ImageEnhancerAndroidConstant.notificationChannelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: ongoing,
        ),
      ),
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    app_init.initLog();
    await app_init.initLocalNotification();
    try {
      final result = await _process();
      if (result == null) {
        _log.severe("[run] Failed while _process");
        // TODO string
        _showStatusNotif(title: "Failed to process image");
        return;
      }
      final srcBytes = await LocalMedia.readFile(platformIdentifier);
      final resultPlatformIdentifier = await _persistResult(result, srcBytes);
      _log.fine("[run] Persisted as $resultPlatformIdentifier");
      _showStatusNotif(
        // TODO string
        title: "Successfully processed image",
        // TODO string
        body: "Tap to view the result",
        payload: jsonEncode({
          "action": ImageEnhancerAndroidConstant.resultNotificationAction,
          "platformIdentifier": resultPlatformIdentifier,
        }),
      );
    } catch (e, stackTrace) {
      _log.severe("[run] Unhandled exception", e, stackTrace);
      _showStatusNotif(title: "Failed to process image");
    }
  }

  Future<Rgb8Image?> _process() async {
    _log.info(
      "[_process] Running with type: $type, platformIdentifier: $platformIdentifier",
    );
    final torch.Method tm = type.toTorchMethod();
    final size = tm.getMaxSrcSize();
    final Rgb8Image src;
    try {
      src = await _loadSrc(size);
    } catch (e, stackTrace) {
      _log.info("[_process] Failed to load image", e, stackTrace);
      return null;
    }
    _log.info("[_process] Loaded src image (${src.width}*${src.height})");
    final Rgb8Image? result;
    try {
      result = await tm.apply(src);
    } catch (e, stackTrace) {
      _log.severe("[_process] Failed to apply method", e, stackTrace);
      return null;
    }
    if (result != null) {
      return result;
    } else {
      _log.severe("[_process] Failed to apply method");
      return null;
    }
  }

  Future<Rgb8Image> _loadSrc(SizeInt size) async {
    if (getRawPlatform() == NpPlatform.android) {
      final fileUri = Uri.parse(platformIdentifier);
      final rgba = await ImageLoader.loadUri(
        fileUri,
        size.width,
        size.height,
        ImageLoaderResizeMethod.fit,
        isAllowSwapSide: true,
        shouldFixOrientation: true,
      );
      return rgba.toRgb();
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  Future<String> _persistResult(Rgb8Image result, Uint8List srcBytes) async {
    final (:dir, :file) = await _createTempFile();
    try {
      final isOk = await imagelib.encodeJpgFile(
        file.path,
        imagelib.Image.fromBytes(
          width: result.width,
          height: result.height,
          bytes: result.pixel.buffer,
          numChannels: 3,
          order: imagelib.ChannelOrder.rgb,
        ),
        quality: 85,
      );
      if (!isOk) {
        throw StateError("Unable to encode image to JPEG");
      }

      // don't copy orientation as it's applied to the src before processing
      if (!await exiv2.copyMetadata(
        srcBytes,
        file,
        shouldCopyOrientation: false,
      )) {
        throw StateError("Unable to copy metadata to JPEG");
      }

      return await LocalMedia.copyPrivateFileToPublicDir(
        file.path,
        srcMime: "image/jpeg",
        dstDir: "Photos (for Nextcloud)/Enhanced Photos",
      );
    } finally {
      unawaited(dir.delete(recursive: true));
    }
  }

  static Future<io.Directory> _openTempDir() async {
    final root = await getTemporaryDirectory();
    final dir = io.Directory("${root.path}/image_enhancer");
    if (!await dir.exists()) {
      return dir.create();
    } else {
      return dir;
    }
  }

  Future<({io.Directory dir, io.File file})> _createTempFile() async {
    final dstDir = await _openTempDir();
    while (true) {
      final dirName = const Uuid().v4();
      final dir = io.Directory("${dstDir.path}/$dirName");
      if (await io.FileSystemEntity.type(dir.path) !=
          io.FileSystemEntityType.notFound) {
        continue;
      }
      await dir.create();
      return (
        dir: dir,
        file: io.File("${dir.path}/${basenameWithoutExtension(filename)}.jpg"),
      );
    }
  }

  final ImageEnhancerTaskType type;
  final String platformIdentifier;
  final String filename;
}

extension ImageEnhancerTaskTypeExtension on ImageEnhancerTaskType {
  torch.Method toTorchMethod() {
    return switch (this) {
      ImageEnhancerTaskType.retouch => torch.Retouch(),
      ImageEnhancerTaskType.superResolution => torch.SuperResolution(),
      ImageEnhancerTaskType.motionDeblur => torch.MotionDeblur(),
      ImageEnhancerTaskType.derain => torch.Derain(),
    };
  }
}
