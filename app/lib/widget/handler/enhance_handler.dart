import 'dart:math' as math;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/help_utils.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/android/content_uri_image_provider.dart';
import 'package:nc_photos/mobile/android/k.dart' as android;
import 'package:nc_photos/mobile/android/permission_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/selectable.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/stateful_slider.dart';
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
    if (!Pref().hasShownEnhanceInfoOr()) {
      await _showInfo(context);
    }

    if (!await _ensurePermission()) {
      return;
    }

    final selected = await _pickAlgorithm(context);
    if (selected == null) {
      // user canceled
      return;
    }
    _log.info("[call] Selected: ${selected.name}");
    final args = await _getArgs(context, selected);
    if (args == null) {
      // user canceled
      return;
    }
    switch (selected) {
      case _Algorithm.zeroDce:
        await ImageProcessor.zeroDce(
          "${account.url}/${file.path}",
          file.filename,
          Pref().getEnhanceMaxWidthOr(),
          Pref().getEnhanceMaxHeightOr(),
          args["iteration"] ?? 8,
          headers: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
        );
        break;

      case _Algorithm.deepLab3Portrait:
        await ImageProcessor.deepLab3Portrait(
          "${account.url}/${file.path}",
          file.filename,
          Pref().getEnhanceMaxWidthOr(),
          Pref().getEnhanceMaxHeightOr(),
          args["radius"] ?? 16,
          headers: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
        );
        break;

      case _Algorithm.esrgan:
        await ImageProcessor.esrgan(
          "${account.url}/${file.path}",
          file.filename,
          Pref().getEnhanceMaxWidthOr(),
          Pref().getEnhanceMaxHeightOr(),
          headers: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
        );
        break;

      case _Algorithm.arbitraryStyleTransfer:
        await ImageProcessor.arbitraryStyleTransfer(
          "${account.url}/${file.path}",
          file.filename,
          math.min(
              Pref().getEnhanceMaxWidthOr(), isAtLeast5GbRam() ? 1600 : 1280),
          math.min(
              Pref().getEnhanceMaxHeightOr(), isAtLeast5GbRam() ? 1200 : 960),
          args["styleUri"],
          args["weight"],
          headers: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
        );
        break;
    }
  }

  Future<void> _showInfo(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.global().enhanceIntroDialogTitle),
        content: Text(L10n.global().enhanceIntroDialogDescription),
        actions: [
          TextButton(
            onPressed: () {
              launch(enhanceUrl);
            },
            child: Text(L10n.global().learnMoreButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(EnhancementSettings.routeName);
            },
            child: Text(L10n.global().configButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
    Pref().setHasShownEnhanceInfo(true);
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

  Future<_Algorithm?> _pickAlgorithm(BuildContext context) =>
      showDialog<_Algorithm>(
        context: context,
        builder: (context) => SimpleDialog(
          children: _getOptions()
              .map((o) => SimpleDialogOption(
                    padding: const EdgeInsets.all(0),
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

  List<_Option> _getOptions() => [
        if (platform_k.isAndroid)
          _Option(
            title: L10n.global().enhanceLowLightTitle,
            subtitle: "Zero-DCE",
            link: enhanceZeroDceUrl,
            algorithm: _Algorithm.zeroDce,
          ),
        if (platform_k.isAndroid)
          _Option(
            title: L10n.global().enhancePortraitBlurTitle,
            subtitle: "DeepLap v3",
            link: enhanceDeepLabPortraitBlurUrl,
            algorithm: _Algorithm.deepLab3Portrait,
          ),
        if (platform_k.isAndroid)
          _Option(
            title: L10n.global().enhanceSuperResolution4xTitle,
            subtitle: "ESRGAN",
            link: enhanceEsrganUrl,
            algorithm: _Algorithm.esrgan,
          ),
        if (platform_k.isAndroid && isAtLeast4GbRam())
          _Option(
            title: L10n.global().enhanceStyleTransferTitle,
            link: enhanceStyleTransferUrl,
            algorithm: _Algorithm.arbitraryStyleTransfer,
          ),
      ];

  Future<Map<String, dynamic>?> _getArgs(
      BuildContext context, _Algorithm selected) async {
    switch (selected) {
      case _Algorithm.zeroDce:
        return _getZeroDceArgs(context);

      case _Algorithm.deepLab3Portrait:
        return _getDeepLab3PortraitArgs(context);

      case _Algorithm.esrgan:
        return {};

      case _Algorithm.arbitraryStyleTransfer:
        return _getArbitraryStyleTransferArgs(context);
    }
  }

  Future<Map<String, dynamic>?> _getZeroDceArgs(BuildContext context) async {
    var current = .8;
    final iteration = await showDialog<int>(
      context: context,
      builder: (context) => AppTheme(
        child: AlertDialog(
          title: Text(L10n.global().enhanceLowLightParamBrightnessLabel),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.brightness_low,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  Expanded(
                    child: StatefulSlider(
                      initialValue: current,
                      onChangeEnd: (value) {
                        current = value;
                      },
                    ),
                  ),
                  Icon(
                    Icons.brightness_high,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final iteration = (current * 10).round().clamp(1, 10);
                Navigator.of(context).pop(iteration);
              },
              child: Text(L10n.global().enhanceButtonLabel),
            ),
          ],
        ),
      ),
    );
    _log.info("[_getZeroDceArgs] iteration: $iteration");
    return iteration?.run((it) => {"iteration": it});
  }

  Future<Map<String, dynamic>?> _getDeepLab3PortraitArgs(
      BuildContext context) async {
    var current = .5;
    final radius = await showDialog<int>(
      context: context,
      builder: (context) => AppTheme(
        child: AlertDialog(
          title: Text(L10n.global().enhancePortraitBlurParamBlurLabel),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.circle,
                    size: 20,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  Expanded(
                    child: StatefulSlider(
                      initialValue: current,
                      onChangeEnd: (value) {
                        current = value;
                      },
                    ),
                  ),
                  Icon(
                    Icons.blur_on,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final radius = (current * 25).round().clamp(1, 25);
                Navigator.of(context).pop(radius);
              },
              child: Text(L10n.global().enhanceButtonLabel),
            ),
          ],
        ),
      ),
    );
    _log.info("[_getDeepLab3PortraitArgs] radius: $radius");
    return radius?.run((it) => {"radius": it});
  }

  Future<Map<String, dynamic>?> _getArbitraryStyleTransferArgs(
      BuildContext context) async {
    final result = await showDialog<_StylePickerResult>(
      context: context,
      builder: (_) => const _StylePicker(),
    );
    if (result == null) {
      // user canceled
      return null;
    } else {
      return {
        "styleUri": result.styleUri,
        "weight": result.weight,
      };
    }
  }

  bool isAtLeast4GbRam() {
    // We can't compare with 4096 directly as some RAM are preserved
    return AndroidInfo().totalMemMb > 3584;
  }

  bool isAtLeast5GbRam() {
    return AndroidInfo().totalMemMb > 4608;
  }

  final Account account;
  final File file;

  static final _log = Logger("widget.handler.enhance_handler.EnhanceHandler");
}

enum _Algorithm {
  zeroDce,
  deepLab3Portrait,
  esrgan,
  arbitraryStyleTransfer,
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

class _StylePickerResult {
  const _StylePickerResult(this.styleUri, this.weight);

  final String styleUri;
  final double weight;
}

class _StylePicker extends StatefulWidget {
  const _StylePicker({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _StylePickerState();
}

class _StylePickerState extends State<_StylePicker> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: AlertDialog(
        title: Text(L10n.global().enhanceStyleTransferStyleDialogTitle),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selected != null) ...[
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: Image(
                    image: ResizeImage.resizeIfNeeded(
                        128, null, ContentUriImage(_getSelectedUri())),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              runSpacing: 8,
              spacing: 8,
              children: [
                ..._bundledStyles.mapWithIndex((i, e) => _buildItem(
                      i,
                      Image(
                        image: ResizeImage.resizeIfNeeded(
                            _thumbSize, null, ContentUriImage(e)),
                        fit: BoxFit.cover,
                      ),
                    )),
                if (_customUri != null)
                  _buildItem(
                    _bundledStyles.length,
                    Image(
                      image: ResizeImage.resizeIfNeeded(
                          _thumbSize, null, ContentUriImage(_customUri!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                InkWell(
                  onTap: _onCustomTap,
                  child: SizedBox(
                    width: _thumbSize.toDouble(),
                    height: _thumbSize.toDouble(),
                    child: const Icon(
                      Icons.file_open_outlined,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.auto_fix_normal,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
                Expanded(
                  child: StatefulSlider(
                    initialValue: _weight,
                    min: .01,
                    onChangeEnd: (value) {
                      _weight = value;
                    },
                  ),
                ),
                Icon(
                  Icons.auto_fix_high,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_selected == null) {
                SnackBarManager().showSnackBar(const SnackBar(
                  content: Text("Please pick a style"),
                  duration: k.snackBarDurationNormal,
                ));
              } else {
                final result = _StylePickerResult(_getSelectedUri(), _weight);
                Navigator.of(context).pop(result);
              }
            },
            child: Text(L10n.global().enhanceButtonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index, Widget child) {
    return SizedBox(
      width: _thumbSize.toDouble(),
      height: _thumbSize.toDouble(),
      child: Selectable(
        isSelected: _selected == index,
        iconSize: 24,
        child: child,
        onTap: () {
          setState(() {
            _selected = index;
          });
        },
      ),
    );
  }

  Future<void> _onCustomTap() async {
    const intent = AndroidIntent(
      action: android.ACTION_GET_CONTENT,
      type: "image/*",
      category: android.CATEGORY_OPENABLE,
      arguments: {
        android.EXTRA_LOCAL_ONLY: true,
      },
    );
    final result = await intent.launchForResult();
    _log.info("[onCustomTap] Intent result: $result");
    if (result?.resultCode == android.resultOk) {
      if (mounted) {
        setState(() {
          _customUri = result!.data;
          _selected = _bundledStyles.length;
        });
      }
    }
  }

  String _getSelectedUri() {
    return _selected! < _bundledStyles.length
        ? _bundledStyles[_selected!]
        : _customUri!;
  }

  int? _selected;
  String? _customUri;
  double _weight = .85;

  static const _thumbSize = 56;
  static const _bundledStyles = [
    "file:///android_asset/tf/arbitrary-style-transfer/1.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/2.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/3.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/4.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/5.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/6.jpg",
  ];

  static final _log =
      Logger("widget.handler.enhance_handler._StylePickerState");
}
