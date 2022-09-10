import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pixel_image_provider.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/handler/permission_handler.dart';
import 'package:nc_photos/widget/image_editor/color_toolbar.dart';
import 'package:nc_photos/widget/image_editor/crop_controller.dart';
import 'package:nc_photos/widget/image_editor/transform_toolbar.dart';
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
      _previewWidth,
      _previewHeight,
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
                  ? _isCropMode
                      ? CropController(
                          // crop always work on the src, otherwise we'll be
                          // cropping repeatedly
                          image: _src,
                          initialState: _cropFilter,
                          onCropChanged: (cropFilter) {
                            _cropFilter = cropFilter;
                            _applyFilters();
                          },
                        )
                      : Image(
                          image: (_dst ?? _src).run((obj) =>
                              PixelImage(obj.pixel, obj.width, obj.height)),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                  : Container(),
            ),
            if (_activeTool == _ToolType.color)
              ColorToolbar(
                initialState: _colorFilters,
                onActiveFiltersChanged: (colorFilters) {
                  _colorFilters = colorFilters.toList();
                  _applyFilters();
                },
              )
            else if (_activeTool == _ToolType.transform)
              TransformToolbar(
                initialState: _transformFilters,
                onActiveFiltersChanged: (transformFilters) {
                  _transformFilters = transformFilters.toList();
                  _applyFilters();
                },
                isCropModeChanged: (value) {
                  setState(() {
                    _isCropMode = value;
                  });
                },
                onCropToolDeactivated: () {
                  _cropFilter = null;
                  _applyFilters();
                },
              ),
            const SizedBox(height: 4),
            _buildToolBar(context),
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
          if (_isModified)
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

  Widget _buildToolBar(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _ToolButton(
              icon: Icons.palette_outlined,
              label: L10n.global().imageEditToolbarColorLabel,
              isSelected: _activeTool == _ToolType.color,
              onPressed: () {
                setState(() {
                  _setActiveTool(_ToolType.color);
                });
              },
            ),
            _ToolButton(
              icon: Icons.transform_outlined,
              label: L10n.global().imageEditToolbarTransformLabel,
              isSelected: _activeTool == _ToolType.transform,
              onPressed: () {
                setState(() {
                  _setActiveTool(_ToolType.transform);
                });
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _onBackButton(BuildContext context) async {
    if (!_isModified) {
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
    final c = KiwiContainer().resolve<DiContainer>();
    await ImageProcessor.filter(
      "${widget.account.url}/${widget.file.path}",
      widget.file.filename,
      4096,
      3072,
      _buildFilterList(),
      headers: {
        "Authorization": Api.getAuthorizationHeaderValue(widget.account),
      },
      isSaveToServer: c.pref.isSaveEditResultToServerOr(),
    );
    Navigator.of(context).pop();
  }

  void _setActiveTool(_ToolType tool) {
    _activeTool = tool;
    _isCropMode = false;
  }

  List<ImageFilter> _buildFilterList() {
    return [
      if (_cropFilter != null) _cropFilter!.toImageFilter()!,
      ..._transformFilters.map((f) => f.toImageFilter()).whereNotNull(),
      ..._colorFilters.map((f) => f.toImageFilter()),
    ];
  }

  Future<void> _applyFilters() async {
    final result = await ImageProcessor.filterPreview(_src, _buildFilterList());
    setState(() {
      _dst = result;
    });
  }

  bool get _isModified =>
      _cropFilter != null ||
      _transformFilters.isNotEmpty ||
      _colorFilters.isNotEmpty;

  bool _isDoneInit = false;
  late final Rgba8Image _src;
  Rgba8Image? _dst;
  var _activeTool = _ToolType.color;
  var _isCropMode = false;

  var _colorFilters = <ColorArguments>[];
  var _transformFilters = <TransformArguments>[];
  TransformArguments? _cropFilter;
}

enum _ToolType {
  color,
  transform,
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : null,
                // borderRadius: const BorderRadius.all(Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.unfocusedIconColorDark,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.unfocusedIconColorDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
}

const _previewWidth = 480;
const _previewHeight = 360;
