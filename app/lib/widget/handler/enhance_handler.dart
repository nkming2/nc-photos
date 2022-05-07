import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/help_utils.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/android/permission_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhanceHandler {
  const EnhanceHandler({
    required this.account,
    required this.file,
  });

  static bool isSupportedFormat(File file) =>
      file_util.isSupportedImageFormat(file) && file.contentType != "image/gif";

  Future<void> call(BuildContext context) async {
    if (!await _ensurePermission()) {
      return;
    }

    final selected = await showDialog<_Algorithm>(
      context: context,
      builder: (context) => SimpleDialog(
        children: _getOptions()
            .map((o) => SimpleDialogOption(
                  child: ListTile(
                    title: Text(o.title),
                    subtitle: o.subtitle?.run((t) => Text(t)),
                    trailing: o.link != null
                        ? SizedBox(
                            height: double.maxFinite,
                            child: TextButton(
                              child: Text(L10n.global().detailsTooltip),
                              onPressed: () {
                                launch(o.link!);
                              },
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(o.algorithm);
                    },
                  ),
                ))
            .toList(),
      ),
    );
    if (selected == null) {
      // user canceled
      return;
    }
    _log.info("[call] Selected: ${selected.name}");
    final imageUri = await _getFileUri();
    switch (selected) {
      case _Algorithm.zeroDce:
        await ImageProcessor.zeroDce(imageUri.toString(), file.filename);
        break;
    }
  }

  Future<bool> _ensurePermission() async {
    if (platform_k.isAndroid) {
      if (AndroidInfo().sdkInt < AndroidVersion.R &&
          !await Permission.hasWriteExternalStorage()) {
        final results = await requestPermissionsForResult([
          Permission.WRITE_EXTERNAL_STORAGE,
        ]);
        if (results[Permission.WRITE_EXTERNAL_STORAGE] !=
            PermissionRequestResult.granted) {
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(L10n.global().errorNoStoragePermission),
            duration: k.snackBarDurationNormal,
          ));
          return false;
        } else {
          return true;
        }
      }
    }
    return true;
  }

  List<_Option> _getOptions() => [
        if (platform_k.isAndroid)
          _Option(
            title: L10n.global().enhanceLowLightTitle,
            subtitle: "Zero-DCE",
            link: enhanceZeroDceUrl,
            algorithm: _Algorithm.zeroDce,
          ),
      ];

  Future<Uri> _getFileUri() async {
    final f = await LargeImageCacheManager.inst.getSingleFile(
      api_util.getFilePreviewUrl(
        account,
        file,
        width: k.photoLargeSize,
        height: k.photoLargeSize,
        a: true,
      ),
      headers: {
        "Authorization": Api.getAuthorizationHeaderValue(account),
      },
    );
    return f.absolute.uri;
  }

  final Account account;
  final File file;

  static final _log = Logger("widget.handler.enhance_handler.EnhanceHandler");
}

enum _Algorithm {
  zeroDce,
}

class _Option {
  const _Option({
    required this.title,
    this.subtitle,
    this.link,
    required this.algorithm,
  });

  final String title;
  final String? subtitle;
  final String? link;
  final _Algorithm algorithm;
}
