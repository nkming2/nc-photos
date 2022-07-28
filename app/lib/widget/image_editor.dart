import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/double_extension.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pixel_image_provider.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/handler/permission_handler.dart';
import 'package:nc_photos/widget/stateful_slider.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class ImageEditorArguments {
  const ImageEditorArguments(this.account, this.file);

  final Account account;
  final File file;
}

class ImageEditor extends StatefulWidget {
  static const routeName = "/image-editor";

  static Route buildRoute(ImageEditorArguments args) => MaterialPageRoute(
        builder: (context) => ImageEditor.fromArgs(args),
      );

  const ImageEditor({
    Key? key,
    required this.account,
    required this.file,
  }) : super(key: key);

  ImageEditor.fromArgs(ImageEditorArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          file: args.file,
        );

  @override
  createState() => _ImageEditorState();

  final Account account;
  final File file;
}

class _ImageEditorState extends State<ImageEditor> {
  @override
  initState() {
    super.initState();
    _initImage();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    if (!await const PermissionHandler().ensureStorageWritePermission()) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  build(BuildContext context) => AppTheme(
        child: Scaffold(
          body: Builder(
            builder: _buildContent,
          ),
        ),
      );

  Future<void> _initImage() async {
    final fileInfo = await LargeImageCacheManager.inst
        .getFileFromCache(api_util.getFilePreviewUrl(
      widget.account,
      widget.file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      a: true,
    ));
    _src = await ImageLoader.loadUri(
      "file://${fileInfo!.file.path}",
      480,
      360,
      ImageLoaderResizeMethod.fit,
      isAllowSwapSide: true,
    );
    if (mounted) {
      setState(() {
        _isDoneInit = true;
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        unawaited(_onBackButton(context));
        return false;
      },
      child: ColoredBox(
        color: Colors.black,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isDoneInit
                  ? Image(
                      image: (_dst ?? _src).run((obj) =>
                          PixelImage(obj.pixel, obj.width, obj.height)),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : Container(),
            ),
            _buildFilterOption(context),
            _buildFilterBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white.withOpacity(.87),
        leading: BackButton(onPressed: () => _onBackButton(context)),
        title: Text(L10n.global().imageEditTitle),
        actions: [
          if (_filters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: L10n.global().saveTooltip,
              onPressed: () => _onSavePressed(context),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: L10n.global().helpTooltip,
            onPressed: () {
              launch(help_util.editPhotosUrl);
            },
          ),
        ],
      );

  Widget _buildFilterBar(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              _FilterButton(
                icon: Icons.brightness_medium,
                label: L10n.global().imageEditColorBrightness,
                onPressed: _onBrightnessPressed,
                isSelected: _selectedFilter == _ColorFilterType.brightness,
                activationOrder:
                    _filters.keys.indexOf(_ColorFilterType.brightness),
              ),
              _FilterButton(
                icon: Icons.contrast,
                label: L10n.global().imageEditColorContrast,
                onPressed: _onContrastPressed,
                isSelected: _selectedFilter == _ColorFilterType.contrast,
                activationOrder:
                    _filters.keys.indexOf(_ColorFilterType.contrast),
              ),
              _FilterButton(
                icon: Icons.circle,
                label: L10n.global().imageEditColorWhitePoint,
                onPressed: _onWhitePointPressed,
                isSelected: _selectedFilter == _ColorFilterType.whitePoint,
                activationOrder:
                    _filters.keys.indexOf(_ColorFilterType.whitePoint),
              ),
              _FilterButton(
                icon: Icons.circle_outlined,
                label: L10n.global().imageEditColorBlackPoint,
                onPressed: _onBlackPointPressed,
                isSelected: _selectedFilter == _ColorFilterType.blackPoint,
                activationOrder:
                    _filters.keys.indexOf(_ColorFilterType.blackPoint),
              ),
              _FilterButton(
                icon: Icons.invert_colors,
                label: L10n.global().imageEditColorSaturation,
                onPressed: _onSaturationPressed,
                isSelected: _selectedFilter == _ColorFilterType.saturation,
                activationOrder:
                    _filters.keys.indexOf(_ColorFilterType.saturation),
              ),
              _FilterButton(
                icon: Icons.thermostat,
                label: L10n.global().imageEditColorWarmth,
                onPressed: _onWarmthPressed,
                isSelected: _selectedFilter == _ColorFilterType.warmth,
                activationOrder: _filters.keys.indexOf(_ColorFilterType.warmth),
              ),
              _FilterButton(
                icon: Icons.colorize,
                label: L10n.global().imageEditColorTint,
                onPressed: _onTintPressed,
                isSelected: _selectedFilter == _ColorFilterType.tint,
                activationOrder: _filters.keys.indexOf(_ColorFilterType.tint),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context) {
    Widget? child;
    switch (_selectedFilter) {
      case _ColorFilterType.brightness:
        child = _buildBrightnessOption(context);
        break;

      case _ColorFilterType.contrast:
        child = _buildContrastOption(context);
        break;

      case _ColorFilterType.whitePoint:
        child = _buildWhitePointOption(context);
        break;

      case _ColorFilterType.blackPoint:
        child = _buildBlackPointOption(context);
        break;

      case _ColorFilterType.saturation:
        child = _buildSaturationOption(context);
        break;

      case _ColorFilterType.warmth:
        child = _buildWarmthOption(context);
        break;

      case _ColorFilterType.tint:
        child = _buildTintOption(context);
        break;

      case null:
        child = null;
        break;
    }
    return Container(
      height: 96,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildSliderOption(
    BuildContext context, {
    required Key key,
    required double min,
    required double max,
    required double initialValue,
    ValueChanged<double>? onChangeEnd,
  }) {
    return AppTheme.dark(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(min.toStringAsFixedTruncated(1)),
                  ),
                  if (min < 0 && max > 0)
                    const Align(
                      alignment: AlignmentDirectional.center,
                      child: Text("0"),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(max.toStringAsFixedTruncated(1)),
                  ),
                ],
              ),
            ),
            StatefulSlider(
              key: key,
              initialValue: initialValue.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChangeEnd: onChangeEnd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.brightness.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.brightness] as _BrightnessArguments)
                .value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.brightness] as _BrightnessArguments)
              .value = value;
          _applyFilters();
        },
      );

  Widget _buildContrastOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.contrast.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.contrast] as _ContrastArguments).value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.contrast] as _ContrastArguments).value =
              value;
          _applyFilters();
        },
      );

  Widget _buildWhitePointOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.whitePoint.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.whitePoint] as _WhitePointArguments)
                .value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.whitePoint] as _WhitePointArguments)
              .value = value;
          _applyFilters();
        },
      );

  Widget _buildBlackPointOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.blackPoint.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.blackPoint] as _BlackPointArguments)
                .value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.blackPoint] as _BlackPointArguments)
              .value = value;
          _applyFilters();
        },
      );

  Widget _buildSaturationOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.saturation.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.saturation] as _SaturationArguments)
                .value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.saturation] as _SaturationArguments)
              .value = value;
          _applyFilters();
        },
      );

  Widget _buildWarmthOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.warmth.name),
        min: -100,
        max: 100,
        initialValue:
            (_filters[_ColorFilterType.warmth] as _WarmthArguments).value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.warmth] as _WarmthArguments).value = value;
          _applyFilters();
        },
      );

  Widget _buildTintOption(BuildContext context) => _buildSliderOption(
        context,
        key: Key(_ColorFilterType.tint.name),
        min: -100,
        max: 100,
        initialValue: (_filters[_ColorFilterType.tint] as _TintArguments).value,
        onChangeEnd: (value) {
          (_filters[_ColorFilterType.tint] as _TintArguments).value = value;
          _applyFilters();
        },
      );

  Future<void> _onBackButton(BuildContext context) async {
    if (_filters.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.global().imageEditDiscardDialogTitle),
        content: Text(L10n.global().imageEditDiscardDialogContent),
        actions: [
          TextButton(
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(L10n.global().discardButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (result == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSavePressed(BuildContext context) async {
    await ImageProcessor.colorFilter(
      "${widget.account.url}/${widget.file.path}",
      widget.file.filename,
      4096,
      3072,
      _buildFilterList(),
      headers: {
        "Authorization": Api.getAuthorizationHeaderValue(widget.account),
      },
    );
    Navigator.of(context).pop();
  }

  void _onFilterPressed(_ColorFilterType type, _FilterArguments defArgs) {
    if (_selectedFilter == type) {
      // deactivate filter
      setState(() {
        _selectedFilter = null;
        _filters.remove(type);
      });
    } else {
      setState(() {
        _selectedFilter = type;
        _filters[type] ??= defArgs;
      });
    }
    _applyFilters();
  }

  void _onBrightnessPressed() =>
      _onFilterPressed(_ColorFilterType.brightness, _BrightnessArguments(0));
  void _onContrastPressed() =>
      _onFilterPressed(_ColorFilterType.contrast, _ContrastArguments(0));
  void _onWhitePointPressed() =>
      _onFilterPressed(_ColorFilterType.whitePoint, _WhitePointArguments(0));
  void _onBlackPointPressed() =>
      _onFilterPressed(_ColorFilterType.blackPoint, _BlackPointArguments(0));
  void _onSaturationPressed() =>
      _onFilterPressed(_ColorFilterType.saturation, _SaturationArguments(0));
  void _onWarmthPressed() =>
      _onFilterPressed(_ColorFilterType.warmth, _WarmthArguments(0));
  void _onTintPressed() =>
      _onFilterPressed(_ColorFilterType.tint, _TintArguments(0));

  List<ImageFilter> _buildFilterList() {
    return _filters.entries.map((e) {
      switch (e.key) {
        case _ColorFilterType.brightness:
          return (e.value as _BrightnessArguments)
              .run((arg) => ColorBrightnessFilter(arg.value / 100));

        case _ColorFilterType.contrast:
          return (e.value as _ContrastArguments)
              .run((arg) => ColorContrastFilter(arg.value / 100));

        case _ColorFilterType.whitePoint:
          return (e.value as _WhitePointArguments)
              .run((arg) => ColorWhitePointFilter(arg.value / 100));

        case _ColorFilterType.blackPoint:
          return (e.value as _BlackPointArguments)
              .run((arg) => ColorBlackPointFilter(arg.value / 100));

        case _ColorFilterType.saturation:
          return (e.value as _SaturationArguments)
              .run((arg) => ColorSaturationFilter(arg.value / 100));

        case _ColorFilterType.warmth:
          return (e.value as _WarmthArguments)
              .run((arg) => ColorWarmthFilter(arg.value / 100));

        case _ColorFilterType.tint:
          return (e.value as _TintArguments)
              .run((arg) => ColorTintFilter(arg.value / 100));
      }
    }).toList();
  }

  Future<void> _applyFilters() async {
    final result = await ImageProcessor.filterPreview(_src, _buildFilterList());
    setState(() {
      _dst = result;
    });
  }

  bool _isDoneInit = false;
  late final Rgba8Image _src;
  Rgba8Image? _dst;
  final _filters = <_ColorFilterType, _FilterArguments>{};
  _ColorFilterType? _selectedFilter;
}

enum _ColorFilterType {
  brightness,
  contrast,
  whitePoint,
  blackPoint,
  saturation,
  warmth,
  tint,
}

abstract class _FilterArguments {}

class _FilterDoubleArguments implements _FilterArguments {
  _FilterDoubleArguments(this.value);

  double value;
}

typedef _BrightnessArguments = _FilterDoubleArguments;
typedef _ContrastArguments = _FilterDoubleArguments;
typedef _WhitePointArguments = _FilterDoubleArguments;
typedef _BlackPointArguments = _FilterDoubleArguments;
typedef _SaturationArguments = _FilterDoubleArguments;
typedef _WarmthArguments = _FilterDoubleArguments;
typedef _TintArguments = _FilterDoubleArguments;

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.activationOrder = -1,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final color = !isSelected && isActivated
        ? AppTheme.primarySwatchDark[900]!.withOpacity(0.4)
        : AppTheme.primarySwatchDark[500]!.withOpacity(0.7);
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedOpacity(
                    opacity: isSelected || isActivated ? 1 : 0,
                    duration: k.animationDurationNormal,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: color,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: 32,
                      color: AppTheme.unfocusedIconColorDark,
                    ),
                  ),
                  if (isActivated)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          (activationOrder + 1).toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.unfocusedIconColorDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.unfocusedIconColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isActivated => activationOrder >= 0;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
  final int activationOrder;
}
