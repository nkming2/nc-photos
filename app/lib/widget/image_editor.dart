import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pixel_image_provider.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/handler/permission_handler.dart';
import 'package:nc_photos/widget/image_editor/color_toolbar.dart';
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
            ColorToolbar(
              initialState: _colorFilters,
              onActiveFiltersChanged: (colorFilters) {
                _colorFilters = colorFilters.toList();
                _applyFilters();
              },
            ),
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

  List<ImageFilter> _buildFilterList() {
    return _colorFilters.map((f) => f.toImageFilter()).toList();
  }

  Future<void> _applyFilters() async {
    final result = await ImageProcessor.filterPreview(_src, _buildFilterList());
    setState(() {
      _dst = result;
    });
  }

  bool get _isModified => _colorFilters.isNotEmpty;

  bool _isDoneInit = false;
  late final Rgba8Image _src;
  Rgba8Image? _dst;

  var _colorFilters = <ColorArguments>[];
}
